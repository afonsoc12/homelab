"""A process-local SMAPI adapter. Credentials never enter Terraform's graph.

Only imported resources are accessible. Writes use fresh ETags and asynchronous
manifest status is checked before Terraform can read the updated configuration.
"""
import hmac
import json
import time
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


ORIGIN = "https://api.amazonalexa.com"
MAX_BODY = 2 * 1024 * 1024


class SafeError(Exception):
    """An error safe to return to Terraform, without upstream error bodies."""


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


class Upstream:
    def __init__(self, token, sleep=time.sleep):
        self.token = token
        self.sleep = sleep
        self.opener = urllib.request.build_opener(NoRedirect)

    def request(self, method, path, body=None, etag=None):
        # No absolute URLs, queries, fragments, traversal or encoded paths.
        if not path.startswith('/v1/skills/') or any(x in path for x in ('?', '#', '%', '..', '\\')):
            raise SafeError('Invalid upstream path')
        headers = {'Authorization': 'Bearer ' + self.token(), 'Accept': 'application/json'}
        if body is not None:
            headers['Content-Type'] = 'application/json'
        if etag:
            headers['If-Match'] = etag
        request = urllib.request.Request(ORIGIN + path, data=body, headers=headers, method=method)
        for attempt in range(4):
            try:
                with self.opener.open(request, timeout=20) as response:
                    raw = response.read(MAX_BODY + 1)
                    if len(raw) > MAX_BODY:
                        raise SafeError('SMAPI response exceeds limit')
                    value = json.loads(raw) if raw else None
                    return response.status, value, response.headers.get('ETag')
            except urllib.error.HTTPError as error:
                status = error.code
                error.close()
                # Only retry reads. Never replay a possibly accepted mutation.
                if method == 'GET' and status in (429, 500, 502, 503, 504) and attempt < 3:
                    self.sleep(2 ** attempt)
                    continue
                raise SafeError('SMAPI request rejected (HTTP %d)' % status) from None
            except (OSError, ValueError, urllib.error.URLError):
                raise SafeError('SMAPI transport or response failure') from None
        raise SafeError('SMAPI retries exhausted')


class Adapter:
    def __init__(self, upstream, paths, sleep=time.sleep, monotonic=time.monotonic, timeout=180):
        self.upstream = upstream
        self.paths = frozenset(paths)
        self.sleep = sleep
        self.monotonic = monotonic
        self.timeout = timeout

    def get(self, path):
        if path not in self.paths:
            raise SafeError('Resource is outside the imported scope')
        _, value, _ = self.upstream.request('GET', path)
        return value

    def put(self, path, body):
        if path not in self.paths:
            raise SafeError('Resource is outside the imported scope')
        manifest = path.endswith('/manifest')
        key = 'manifest' if manifest else 'accountLinkingRequest'
        if not isinstance(body, dict) or set(body) != {key} or not isinstance(body[key], dict):
            raise SafeError('Invalid resource update')
        _, before, etag = self.upstream.request('GET', path)
        if not etag:
            raise SafeError('Missing ETag; update refused')
        desired = body if manifest else {'accountLinkingResponse': body[key]}
        # Metadata-only Terraform updates must not mutate live skills.
        if before == desired:
            return
        status, _, _ = self.upstream.request('PUT', path, json.dumps(body).encode(), etag)
        readable = json.loads(json.dumps(desired))
        if not manifest:
            readable['accountLinkingResponse'].pop('clientSecret', None)
        if manifest:
            if status != 202:
                raise SafeError('Unexpected manifest update response')
            deadline = self.monotonic() + self.timeout
            status_path = path.split('/stages/')[0] + '/status'
            while self.monotonic() < deadline:
                _, value, _ = self.upstream.request('GET', status_path)
                state = value.get('manifest', {}).get('lastUpdateRequest', {}).get('status')
                if state == 'SUCCEEDED':
                    # Status can briefly describe the preceding build. Require
                    # a new successful version as well as matching settings.
                    version = value.get('manifest', {}).get('eTag')
                    if not isinstance(version, str) or not version:
                        raise SafeError('Successful build has no version identifier')
                    if version.strip('"') != etag.strip('"'):
                        _, after, _ = self.upstream.request('GET', path)
                        if after == readable:
                            return
                if state == 'FAILED':
                    raise SafeError('Alexa manifest build failed')
                if state not in ('IN_PROGRESS', 'SUCCEEDED'):
                    raise SafeError('Unexpected Alexa manifest build status')
                self.sleep(2)
            else:
                raise SafeError('Alexa manifest build timed out; inspect status before retrying')
        _, after, _ = self.upstream.request('GET', path)
        # The write-only OAuth client secret cannot be compared with GET data.
        if after != readable:
            raise SafeError('Updated configuration does not match the requested settings')


def serve(adapter, session):
    class Handler(BaseHTTPRequestHandler):
        def setup(self):
            super().setup()
            self.connection.settimeout(30)

        def log_message(self, *args):
            pass

        def handle_request(self):
            try:
                if not hmac.compare_digest(self.headers.get('Authorization', ''), 'Bearer ' + session):
                    self.send_error_safe(403, 'Invalid local session')
                    return
                if self.command == 'GET':
                    value = adapter.get(self.path)
                    raw = json.dumps(value).encode()
                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json')
                    self.send_header('Content-Length', str(len(raw)))
                    self.end_headers()
                    self.wfile.write(raw)
                elif self.command == 'PUT':
                    length = int(self.headers.get('Content-Length', '0'))
                    if length <= 0 or length > MAX_BODY:
                        raise SafeError('Invalid request size')
                    adapter.put(self.path, json.loads(self.rfile.read(length)))
                    self.send_response(204)
                    self.end_headers()
                else:
                    self.send_error_safe(405, 'Method refused')
            except SafeError as error:
                self.send_error_safe(502, str(error))
            except Exception:
                self.send_error_safe(502, 'Local adapter request failed')

        def send_error_safe(self, status, message):
            raw = json.dumps({'message': message}).encode()
            self.send_response(status)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(raw)))
            self.end_headers()
            self.wfile.write(raw)

        do_GET = do_PUT = do_POST = do_DELETE = handle_request

    server = ThreadingHTTPServer(('localhost', 0), Handler)
    server.daemon_threads = True
    return server
