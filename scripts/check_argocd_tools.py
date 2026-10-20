"""Validate pinned tool versions and optionally verify the upstream bytes."""

import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
from pathlib import Path
import re
import sys
import urllib.request

import yaml


def artifacts(env):
    for arch, curl_arch in [("amd64", "amd64"), ("arm64", "aarch64")]:
        curl, kubectl, sops, vals, helm = (env[k] for k in ["CURL_VERSION", "KUBECTL_VERSION", "SOPS_VERSION", "VALS_VERSION", "HELM3_VERSION"])
        yield f"curl-{curl}-{curl_arch}", f"https://github.com/moparisthebest/static-curl/releases/download/v{curl}/curl-{curl_arch}"
        yield f"kubectl-v{kubectl}-linux-{arch}", f"https://dl.k8s.io/release/v{kubectl}/bin/linux/{arch}/kubectl"
        yield f"sops-v{sops}.linux.{arch}", f"https://github.com/getsops/sops/releases/download/v{sops}/sops-v{sops}.linux.{arch}"
        yield f"vals_{vals}_linux_{arch}.tar.gz", f"https://github.com/helmfile/vals/releases/download/v{vals}/vals_{vals}_linux_{arch}.tar.gz"
        yield f"helm-v{helm}-linux-{arch}.tar.gz", f"https://get.helm.sh/helm-v{helm}-linux-{arch}.tar.gz"
    version = env["HELM_SECRETS_VERSION"]
    yield f"helm-secrets-{version}.tar.gz", f"https://github.com/jkroepke/helm-secrets/releases/download/v{version}/helm-secrets.tar.gz"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--verify-downloads", action="store_true")
    args = parser.parse_args()
    data = yaml.safe_load(Path("kubernetes/apps/addons/argocd/values.sops.yaml").read_text())
    init = next(container for container in data["repoServer"]["initContainers"] if container["name"] == "download-tools")
    env = {item["name"]: str(item["value"]) for item in init["env"]}
    checksums = {}
    for line in env["TOOL_CHECKSUMS"].splitlines():
        checksum, name = line.split()
        if not re.fullmatch(r"[0-9a-f]{64}", checksum) or name in checksums:
            raise ValueError("Invalid or duplicate tool checksum")
        checksums[name] = checksum
    urls = dict(artifacts(env))
    if set(urls) != set(checksums):
        raise ValueError("Tool versions and checksums differ; update hashes alongside version bumps")
    if args.verify_downloads:
        def verify(item):
            name, url = item
            digest = hashlib.sha256()
            with urllib.request.urlopen(url, timeout=60) as response:
                while chunk := response.read(1024 * 1024):
                    digest.update(chunk)
            if digest.hexdigest() != checksums[name]:
                raise ValueError("Checksum mismatch: " + name)
            print("Verified:", name, flush=True)
        with ThreadPoolExecutor(max_workers=4) as pool:
            list(pool.map(verify, urls.items()))
    print(f"Argo CD tool checks: {len(checksums)} pinned artifacts across amd64 and arm64")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as error:
        print(f"Tool verification failed: {error}", file=sys.stderr)
        sys.exit(1)
