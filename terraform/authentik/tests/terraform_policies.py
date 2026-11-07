"""Read the actual inline Terraform expressions for policy security tests."""

from pathlib import Path
import re
import textwrap


def read_policy(filename, resource):
    source = (Path(__file__).parents[1] / filename).read_text()
    pattern = (
        r'resource "authentik_policy_expression" "' + re.escape(resource)
        + r'" \{.*?expression\s*=\s*<<-PY\n(.*?)\n\s*PY\n'
    )
    match = re.search(pattern, source, re.S)
    if match is None:
        raise AssertionError(f"Missing inline policy: {resource}")
    return textwrap.dedent(match[1]) + "\n"
