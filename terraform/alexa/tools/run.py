"""Run from any directory: python3 tools/run.py {init,validate,plan,apply}.

ASK_CLI_ROOT must identify the installed ask-cli 2.30.7 package. Long-lived ASK
credentials are read only from credentials.sops.yaml, never from a CLI profile.
All subprocess output is captured; only resource addresses/actions are printed.
"""
import argparse
from contextlib import contextmanager
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import secrets
import shutil
import subprocess
import sys
import tempfile
import threading

from adapter import Adapter, ORIGIN, SafeError, Upstream, serve


ROOT = Path(__file__).resolve().parents[1]


def capture(command, **kwargs):
    result = subprocess.run(command, capture_output=True, **kwargs)
    if result.returncode:
        raise SafeError('Command failed: ' + Path(command[0]).name + '; output suppressed')
    return result.stdout


def decrypt(path):
    return json.loads(capture(['sops', '-d', '--output-type', 'json', str(path)]))


def environment():
    env = dict(os.environ)
    # Provider debug logging and caller-supplied endpoint overrides are unsafe.
    for key in list(env):
        if key.startswith(('TF_LOG', 'ASK_LWA_', 'ASK_SMAPI_')) or key in ('NODE_OPTIONS', 'NODE_DEBUG'):
            env.pop(key)
    env['API_DATA_IS_SENSITIVE'] = 'true'
    return env


def backend(env):
    raw = capture(['sops', '-d', str(ROOT.parent / 'backend.sops.tfbackend')]).decode()
    variables = {'access_key': 'AWS_ACCESS_KEY_ID', 'secret_key': 'AWS_SECRET_ACCESS_KEY', 'token': 'AWS_SESSION_TOKEN'}
    env.pop('AWS_SESSION_TOKEN', None)
    pattern = re.compile(r'^\s*(access_key|secret_key|token)\s*=\s*("(?:[^"\\]|\\.)*")\s*$', re.M)

    def replace(match):
        env[variables[match[1]]] = json.loads(match[2])
        return ''

    cleaned = pattern.sub(replace, raw)
    if re.search(r'^\s*(access_key|secret_key|token)\s*=', cleaned, re.M):
        raise SafeError('Unsupported backend credential format')
    return cleaned.encode()


def secure_cache(module):
    folder = module / '.terraform'
    if folder.exists():
        folder.chmod(0o700)
    cache = folder / 'terraform.tfstate'
    if cache.exists():
        cache.chmod(0o600)


class Tokens:
    def __init__(self, env):
        root = env.get('ASK_CLI_ROOT')
        if not root:
            executable = shutil.which('ask-smapi') or shutil.which('ask')
            if executable:
                root = str(Path(executable).resolve().parents[2])
        if not root or not (Path(root) / 'package.json').is_file():
            raise SafeError('Set ASK_CLI_ROOT to the installed ask-cli 2.30.7 package')
        if json.loads((Path(root) / 'package.json').read_text()).get('version') != '2.30.7':
            raise SafeError('ASK CLI version must be 2.30.7')
        env['ASK_CLI_ROOT'] = root
        self.env = env
        self.profile = json.loads(decrypt(ROOT / 'credentials.sops.yaml')['profile'])
        self.lock = threading.Lock()

    def __call__(self):
        with self.lock:
            token = self.profile['token']
            expiry = datetime.fromisoformat(token.get('expires_at', '1970-01-01T00:00:00+00:00').replace('Z', '+00:00'))
            if (expiry - datetime.now(timezone.utc)).total_seconds() < 300:
                raw = capture(['node', str(ROOT / 'tools/refresh.cjs')], input=json.dumps({"token": token, "vendor_id": self.profile["vendor_id"]}).encode(), env=self.env, timeout=60)
                refreshed = json.loads(raw)
                if not refreshed.get('access_token'):
                    raise SafeError('No access token returned')
                refreshed.setdefault('refresh_token', token['refresh_token'])
                updated_profile = dict(self.profile, token=refreshed)
                # Persist only rotated long-lived credentials, directly via SOPS.
                if refreshed['refresh_token'] != token['refresh_token']:
                    capture(['sops', 'set', '--value-stdin', str(ROOT / 'credentials.sops.yaml'), '["profile"]'], input=json.dumps(json.dumps(updated_profile)).encode())
                self.profile = updated_profile
                token = refreshed
            return token['access_token']


@contextmanager
def connection(env):
    settings = json.loads(decrypt(ROOT / 'secrets.sops.yaml')['settings'])
    if settings['api_uri'] != ORIGIN:
        raise SafeError('Unexpected SMAPI origin')
    paths = []
    for skill in settings['skills'].values():
        identifier = skill['id']
        if not re.fullmatch(r'amzn1\.ask\.skill\.[A-Za-z0-9-]+', identifier):
            raise SafeError('Invalid skill identifier')
        base = '/v1/skills/' + identifier + '/stages/development/'
        paths.append(base + 'manifest')
        if 'account_linking' in skill:
            paths.append(base + 'accountLinkingClient')
    session = secrets.token_urlsafe(32)
    server = serve(Adapter(Upstream(Tokens(env)), paths), session)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    env['TF_VAR_smapi_endpoint'] = 'http://localhost:' + str(server.server_port)
    env['TF_VAR_smapi_session_token'] = session
    try:
        yield
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=5)
        env.pop('TF_VAR_smapi_endpoint', None)
        env.pop('TF_VAR_smapi_session_token', None)


def execute(action, module, env, cleaned_backend):
    if action == 'init':
        read_fd, write_fd = os.pipe()
        try:
            os.write(write_fd, cleaned_backend)
            os.close(write_fd)
            write_fd = None
            capture(['terraform', 'init', '-reconfigure', '-input=false', '-backend-config=/dev/fd/' + str(read_fd)], cwd=module, env=env, pass_fds=(read_fd,))
        finally:
            os.close(read_fd)
            if write_fd is not None:
                os.close(write_fd)
            secure_cache(module)
        # Cached metadata must not retain backend credentials.
        cache = json.loads((module / '.terraform/terraform.tfstate').read_text())
        if any(cache['backend']['config'].get(k) for k in ('access_key', 'secret_key', 'token')):
            raise SafeError('Backend cache still contains credentials')
        print(module.name + ': backend initialized without cached credentials')
        return
    if action == 'validate':
        capture(['terraform', 'validate', '-json'], cwd=module, env=env)
        print(module.name + ': configuration valid')
        return
    with tempfile.TemporaryDirectory(prefix='skill-plan-') as directory:
        plan = str(Path(directory) / 'plan')
        capture(['terraform', 'plan', '-input=false', '-out=' + plan], cwd=module, env=env)
        Path(plan).chmod(0o600)
        document = json.loads(capture(['terraform', 'show', '-json', plan], cwd=module, env=env))
        changes = [r for r in document.get('resource_changes', []) if r['mode'] == 'managed' and r['change']['actions'] != ['no-op']]
        for change in changes:
            print(change['address'], ','.join(change['change']['actions']))
        print(module.name + ': ' + str(len(changes)) + ' resource changes')
        if action == 'apply':
            if any(r['change']['actions'] != ['update'] for r in changes):
                raise SafeError('Only updates to existing resources are supported')
            # Apply exactly the saved plan just reviewed above.
            capture(['terraform', 'apply', '-input=false', plan], cwd=module, env=env)
            print(module.name + ': saved plan applied')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['init', 'validate', 'plan', 'apply'])
    parser.add_argument('--module', choices=['alexa', 'aws', 'cloudflare'], default='alexa')
    args = parser.parse_args()
    os.umask(0o077)
    env = environment()
    cleaned = backend(env)
    module = ROOT.parent / args.module
    secure_cache(module)
    if args.module == 'alexa' and args.action in ('plan', 'apply'):
        with connection(env):
            execute(args.action, module, env, cleaned)
    else:
        execute(args.action, module, env, cleaned)


if __name__ == '__main__':
    try:
        main()
    except SafeError as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
    except Exception:
        print('Operation failed; sensitive diagnostic details suppressed', file=sys.stderr)
        sys.exit(1)
