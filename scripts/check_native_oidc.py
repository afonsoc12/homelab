"""Exercise native OIDC email expressions with synthetic identities only."""

import json
from pathlib import Path
import re
from textwrap import dedent, indent
from types import SimpleNamespace


ROOT = Path(__file__).resolve().parents[1]
LEDGER_EXPRESSION = '${jsonencode(data.sops_file.secrets.data["native_oidc.verified_emails"])}'


def expression(source, resource_type, name, ledger):
    match = re.search(
        rf'resource "{resource_type}" "{name}"\s*\{{.*?expression = <<-EOT\n(.*?)\n  EOT',
        source,
        re.DOTALL,
    )
    assert match is not None, f"Missing expression: {name}"
    body = dedent(match[1])
    assert LEDGER_EXPRESSION in body, f"Missing encrypted ledger: {name}"
    # Reproduce HCL jsonencode of the encrypted JSON string without decrypting it.
    body = body.replace(LEDGER_EXPRESSION, json.dumps(json.dumps(ledger)))
    namespace = {}
    exec("def evaluate(request):\n" + indent(body, "    "), namespace)
    return namespace["evaluate"]


def main():
    source = (ROOT / "terraform/authentik/native_oidc.tf").read_text()
    cases = [
        ("empty ledger", {}, 101, "owner@placeholder", False),
        ("approved owner", {"101": "owner@placeholder"}, 101, "owner@placeholder", True),
        ("different user, same email", {"101": "owner@placeholder"}, 202, "owner@placeholder", False),
        ("changed profile email", {"101": "owner@placeholder"}, 101, "other@placeholder", False),
        ("missing email", {"101": "owner@placeholder"}, 101, None, False),
        ("empty approved email", {"101": ""}, 101, "", False),
        ("unapproved identity", {"101": "owner@placeholder"}, 202, "other@placeholder", False),
        ("case changed email", {"101": "owner@placeholder"}, 101, "Owner@placeholder", False),
        ("escaped email", {"101": 'owner"\\@placeholder'}, 101, 'owner"\\@placeholder', True),
    ]
    checks = 0
    for label, ledger, user_id, email, expected in cases:
        request = SimpleNamespace(user=SimpleNamespace(pk=user_id, email=email))
        claim = expression(source, "authentik_property_mapping_provider_scope", "native_oidc_email", ledger)(request)
        policy = expression(source, "authentik_policy_expression", "native_oidc_verified_email", ledger)(request)
        assert claim["email"] == email, f"Email changed: {label}"
        assert claim["email_verified"] is expected, f"Incorrect verification claim: {label}"
        assert policy is expected, f"Incorrect access decision: {label}"
        checks += 1
    print(f"Native OIDC identity checks: {checks} passed")


if __name__ == "__main__":
    main()
