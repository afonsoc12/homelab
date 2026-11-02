"""Exercise the actual Firefly nginx gate with dummy credentials.

Run from the repository root:
    python3 scripts/check_firefly_proxy_auth.py --pod <running-firefly-pod>

Requires PyYAML, SOPS, kubectl, and access to the selected Firefly pod.
Decrypts values only in memory. Starts a temporary loopback-only nginx listener
inside the pod and removes it on exit. Does not change the application listener
or test Firefly login, database access, or cron-token validation.
"""

import argparse
import shlex
import subprocess
import sys
from pathlib import Path

import yaml


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pod", required=True)
    parser.add_argument("--namespace", default="homelab")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    result = subprocess.run(
        ["sops", "-d", str(root / "kubernetes/apps/homelab/firefly/values.sops.yaml")],
        capture_output=True,
        text=True,
        check=True,
    )
    gate = yaml.safe_load(result.stdout)["secret"]["stringData"]["FIREFLY_NGINX_PROXY_GATE"]
    replacements = {
        "{{ .Values.secret.stringData.FIREFLY_PROXY_TOKEN }}": "test-origin-key",
        "{{ .Values.secret.stringData.FIREFLY_PROXY_EMAIL }}": "shared-account@example.invalid",
    }
    for template, dummy in replacements.items():
        if template not in gate:
            raise ValueError("Expected gate template missing; review the test before running")
        gate = gate.replace(template, dummy)
    if "{{" in gate:
        raise ValueError("Unexpected template in gate; refusing to run")

    script = (
        """set -eu
probe_dir=$(mktemp -d /tmp/firefly-auth-check.XXXXXX)
cleanup() {
    if [ -f "$probe_dir/nginx.pid" ]; then
        nginx -p "$probe_dir/" -c "$probe_dir/nginx.conf" -s quit >/dev/null 2>&1 || true
    fi
    rm -rf "$probe_dir"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM
cat > "$probe_dir/nginx.conf" <<'CONFIG'
pid nginx.pid;
error_log error.log error;
events {}
http { access_log off; server { listen 127.0.0.1:18080;
"""
        + gate
        + """
location / { return 200 "gate passed"; }
} }
CONFIG
nginx -p "$probe_dir/" -c "$probe_dir/nginx.conf" -t >/dev/null 2>&1
nginx -p "$probe_dir/" -c "$probe_dir/nginx.conf"
"""
    )
    user = "X-Firefly-User: shared-account@example.invalid"
    token = "X-Firefly-Proxy-Token: test-origin-key"
    cases = [
        ("missing headers", 403, "/", []),
        ("forged identity only", 403, "/", [user]),
        ("missing identity", 403, "/", [token]),
        ("wrong token", 403, "/", [user, "X-Firefly-Proxy-Token: wrong"]),
        ("wrong identity", 403, "/", [token, "X-Firefly-User: other@example.invalid"]),
        ("standard email alone", 403, "/", [token, "X-Authentik-Email: shared-account@example.invalid"]),
        ("spoofed source", 403, "/", [user, "X-Forwarded-For: 127.0.0.1"]),
        ("authorized proxy", 200, "/", [user, token]),
        ("health probe", 200, "/health", []),
        ("health suffix", 403, "/health/anything", []),
    ]
    for label, expected, path, headers in cases:
        command = [
            "curl",
            "--silent",
            "--show-error",
            "--max-time",
            "3",
            "--output",
            "/dev/null",
            "--write-out",
            "%{http_code}",
            "http://127.0.0.1:18080" + path,
        ]
        for header in headers:
            command.extend(["-H", header])
        script += "actual=$(" + shlex.join(command) + ")\n"
        script += "printf '%s: HTTP %s (expected %s)\\n' " + shlex.quote(label)
        script += ' "$actual" ' + str(expected) + "\n"
        script += 'test "$actual" = ' + str(expected) + "\n"
    result = subprocess.run(
        ["kubectl", "exec", "-i", "-n", args.namespace, args.pod, "--", "sh", "-s"],
        input=script,
        text=True,
        capture_output=True,
    )
    print(result.stdout, end="")
    if result.returncode:
        print("Gate check failed; temporary listener cleanup was requested.", file=sys.stderr)
        return 1
    print("PASS: nginx gate checks; temporary listener cleaned up.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
