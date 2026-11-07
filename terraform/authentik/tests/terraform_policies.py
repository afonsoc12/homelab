"""Read the actual inline Terraform expressions for policy security tests."""

from pathlib import Path
import re
import textwrap


def read_resource(filename, kind, name):
    source = (Path(__file__).parents[1] / filename).read_text()
    pattern = r'resource "' + re.escape(kind) + r'" "' + re.escape(name) + r'" \{.*?^\}'
    match = re.search(pattern, source, re.S | re.M)
    if match is None:
        raise AssertionError(f"Missing Terraform resource: {kind}.{name}")
    return match[0]


def read_policy(filename, resource):
    source = read_resource(filename, "authentik_policy_expression", resource)
    match = re.search(r'expression\s*=\s*<<-PY\n(.*?)\n\s*PY\n', source, re.S)
    if match is None:
        raise AssertionError(f"Missing inline policy expression: {resource}")
    return textwrap.dedent(match[1]) + "\n"
