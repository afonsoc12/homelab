"""Check that Contour policy settings cannot silently remove authentication."""

from copy import deepcopy
from pathlib import Path
import subprocess

import yaml

ROOT = Path(__file__).resolve().parents[1]


def render(chart, values):
    return subprocess.run(
        ["helm", "template", "policy-check", str(ROOT / "kubernetes/charts" / chart), "-f", "-"],
        input=yaml.safe_dump(values), text=True, capture_output=True, check=False,
    )


def main():
    checks = 0
    for chart in ("homelab-svc", "external-svc"):
        values = {
            "image": {"repository": "test", "tag": "1"},
            "ports": [{"containerPort": 8080, "service": True}],
            "server": {"port": 8080},
            "lanIngress": {"trustedNetworks": ["cidr-placeholder"]},
            "ingress": {
                "enabled": True, "className": "contour", "authelia": False,
                "contourPolicy": "protectedLan",
                "tls": [{"secretName": "test-certificate"}],
                "hosts": [{"host": "sample", "paths": [{
                    "path": "/", "pathType": "Prefix",
                    "service": {"name": "authentication-proxy", "port": 9000},
                }]}],
            },
        }
        result = render(chart, values)
        assert result.returncode == 0, result.stderr
        proxy = next(d for d in yaml.safe_load_all(result.stdout) if d and d["kind"] == "HTTPProxy")
        protected = next(r for r in proxy["spec"]["routes"] if "prefix" in r["conditions"][0])
        assert protected["services"][0]["name"] == "authentication-proxy"
        assert protected["ipAllowPolicy"] == [{"cidr": "cidr-placeholder", "source": "Peer"}]
        checks += 1

        cases = []
        invalid = deepcopy(values)
        del invalid["ingress"]["hosts"][0]["paths"][0]["service"]
        cases.append((invalid, "requires an authentication proxy backend"))
        invalid = deepcopy(values)
        invalid["ingress"]["className"] = "nginx"
        cases.append((invalid, "requires the contour class"))
        for flag in ("authelia", "authentik"):
            invalid = deepcopy(values)
            invalid["ingress"][flag] = True
            cases.append((invalid, "nginx forward-auth disabled"))
        invalid = deepcopy(values)
        invalid["lanIngress"]["trustedNetworks"] = []
        cases.append((invalid, "lanIngress.trustedNetworks must be set"))
        invalid = deepcopy(values)
        invalid["ingress"]["hosts"] *= 2
        cases.append((invalid, "requires exactly one ingress host"))
        for invalid, message in cases:
            result = render(chart, invalid)
            assert result.returncode != 0 and message in result.stderr, (chart, message, result.stderr)
            checks += 1
    print(f"Contour authentication safeguards: {checks} checks passed")


if __name__ == "__main__":
    main()
