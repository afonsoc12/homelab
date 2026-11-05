"""Verify standard Ingress proxy backends and reject unsupported forward auth."""

from copy import deepcopy
from pathlib import Path
import subprocess

import yaml

ROOT = Path(__file__).resolve().parents[1]


def render(chart, values):
    return subprocess.run(
        ["helm", "template", "ingress-check", str(ROOT / "kubernetes/charts" / chart), "-f", "-"],
        input=yaml.safe_dump(values), text=True, capture_output=True, check=False,
    )


def main():
    checks = 0
    for chart in ("homelab-svc", "external-svc"):
        values = {
            "domain": "placeholder",
            "image": {"repository": "test", "tag": "1"},
            "ports": [{"containerPort": 8080, "service": True}],
            "server": {"port": 8080},
            "ingress": {
                "enabled": True, "className": "contour", "authelia": False,
                "annotations": {"ingress.kubernetes.io/force-ssl-redirect": "true"},
                "tls": [{"secretName": "test-certificate"}],
                "hosts": [{"host": "app.{{ .Values.domain }}", "paths": [{
                    "path": "/", "pathType": "Prefix",
                    "service": {"name": "authentik-proxy", "port": 9000},
                }]}],
            },
        }
        result = render(chart, values)
        assert result.returncode == 0, result.stderr
        docs = [d for d in yaml.safe_load_all(result.stdout) if isinstance(d, dict)]
        assert not any(d["kind"] == "HTTPProxy" for d in docs)
        ingress = next(d for d in docs if d["kind"] == "Ingress")
        assert ingress["spec"]["ingressClassName"] == "contour"
        host = ingress["spec"]["rules"][0]
        assert ingress["spec"]["tls"][0]["hosts"] == [host["host"]]
        assert host["http"]["paths"][0]["backend"]["service"] == {
            "name": "authentik-proxy", "port": {"number": 9000},
        }
        assert not any(k.startswith("nginx.") for k in ingress["metadata"]["annotations"])
        checks += 1
        invalid = deepcopy(values)
        invalid["ingress"]["authelia"] = True
        result = render(chart, invalid)
        assert result.returncode != 0 and "nginx forward-auth" in result.stderr
        checks += 1
        if chart == "homelab-svc":
            invalid = deepcopy(values)
            invalid["ingress"]["authentik"] = True
            result = render(chart, invalid)
            assert result.returncode != 0 and "nginx forward-auth" in result.stderr
            checks += 1
    print(f"Standard Ingress authentication checks: {checks} passed")


if __name__ == "__main__":
    main()
