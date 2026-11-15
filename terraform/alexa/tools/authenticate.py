"""Supply short-lived SMAPI authentication and fresh per-resource ETags.

Requires the official ask-smapi executable (or ASK_SMAPI_BIN) and an authenticated
ASK profile. CLI output, HTTP error bodies and credentials must never reach logs.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import urllib.request


def authenticate(query):
    executable = os.environ.get("ASK_SMAPI_BIN") or shutil.which("ask-smapi")
    if not executable:
        raise RuntimeError("Set ASK_SMAPI_BIN to the official ASK SMAPI executable")
    profile = os.environ.get("ASK_PROFILE", "default")
    command = (["node", executable] if executable.endswith(".js") else [executable])
    command += ["list-skills-for-vendor", "--profile", profile]
    result = subprocess.run(command, capture_output=True, timeout=90)
    if result.returncode:
        raise RuntimeError("ASK authentication failed; authenticate the selected profile")
    config = json.loads((Path.home() / ".ask" / "cli_config").read_text())
    token = config["profiles"][profile]["token"]["access_token"]
    result = {"access_token": token}
    for name, path in json.loads(query["paths"]).items():
        request = urllib.request.Request(
            query["uri"] + path, headers={"Authorization": "Bearer " + token}
        )
        with urllib.request.urlopen(request, timeout=30) as response:
            etag = response.headers.get("ETag")
            if not etag:
                raise RuntimeError("SMAPI response has no ETag; refusing unversioned updates")
            result[name] = etag
    return result


if __name__ == "__main__":
    try:
        print(json.dumps(authenticate(json.load(sys.stdin))))
    except Exception:
        print("SMAPI authentication or ETag retrieval failed; details suppressed", file=sys.stderr)
        sys.exit(1)
