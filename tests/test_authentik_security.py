"""Exercise the deployed policy expressions without Authentik or real accounts.

Run with: python3 -m unittest discover -s tests
These tests do not replace a provider plan or end-to-end flow verification.
"""

from datetime import datetime, timedelta, timezone
from pathlib import Path
import re
import sys
import textwrap
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch


ROOT = Path(__file__).resolve().parents[1] / "terraform" / "authentik"
NOW = datetime(2030, 1, 1, tzinfo=timezone.utc)


def resource(kind, name):
    for path in ROOT.glob("*.tf"):
        match = re.search(
            rf'^resource "{kind}" "{name}" \{{\n(.*?)^\}}',
            path.read_text(), re.MULTILINE | re.DOTALL,
        )
        if match:
            return match.group(1)
    raise AssertionError(f"Missing resource: {kind}.{name}")


def evaluate(name, context, user=None, current=None, cache=None):
    body = resource("authentik_policy_expression", name)
    expression = re.search(r"expression\s*= <<-PY\n(.*?)\n\s*PY", body, re.DOTALL)
    namespace = {
        "context": context,
        "request": SimpleNamespace(user=user),
        "ak_user_by": lambda **kwargs: current,
        "ak_message": lambda message: None,
    }
    source = "def policy():\n" + textwrap.indent(textwrap.dedent(expression.group(1)), "    ")
    exec(compile(source, name, "exec"), namespace)
    with patch.dict(sys.modules, {
        "django.utils.timezone": SimpleNamespace(now=lambda: NOW),
        "django.core.cache": SimpleNamespace(cache=cache),
        "authentik.core.models": SimpleNamespace(User=lambda **kwargs: account(pk=None, **kwargs)),
    }):
        return namespace["policy"]()


def account(**overrides):
    values = dict(
        pk=1, username="person", is_active=True, email="inbox", attributes={},
        password_change_date=NOW, has_usable_password=lambda: True,
        check_password=lambda candidate: candidate == "same", save=Mock(),
    )
    values.update(overrides)
    return SimpleNamespace(**values)


class PasswordPolicyTests(unittest.TestCase):
    def test_annual_rotation_boundary(self):
        for age, expired in [(0, False), (180, False), (364, False), (365, True), (366, True)]:
            with self.subTest(age=age):
                user = account(password_change_date=NOW - timedelta(days=age))
                self.assertEqual(evaluate("password_renewal_required", {"pending_user": user}), expired)

    def test_missing_metadata_and_inactive_users_require_renewal(self):
        for user in [None, account(pk=None), account(is_active=False), account(password_change_date=None)]:
            with self.subTest(user=user):
                self.assertTrue(evaluate("password_renewal_required", {"pending_user": user}))

    def test_source_only_account_does_not_get_local_password(self):
        user = account(has_usable_password=lambda: False)
        self.assertFalse(evaluate("password_renewal_required", {"pending_user": user}))

    def test_replacement_password_must_differ_from_current(self):
        for candidate, allowed in [("same", False), ("different", True), (None, False)]:
            with self.subTest(candidate=candidate):
                self.assertEqual(evaluate("password_not_current", {"prompt_data": {"password": candidate}}, user=account()), allowed)

    def test_enrollment_and_reset_both_check_breaches_and_strength(self):
        for name in ["password_change", "password_requirements"]:
            body = resource("authentik_policy_password", name)
            for key in ["amount_digits", "amount_lowercase", "amount_uppercase", "amount_symbols"]:
                self.assertRegex(body, rf"{key}\s*= 1\b")
            self.assertRegex(body, r"length_min\s*= 15\b")
            self.assertRegex(body, r"check_have_i_been_pwned\s*= true")
            self.assertRegex(body, r"zxcvbn_score_threshold\s*= 3\b")


class EmailVerificationTests(unittest.TestCase):
    def context(self, **overrides):
        values = dict(
            pending_user=account(),
            is_restored=SimpleNamespace(user_id=1, identifier="ak-email-stage-homelab-sign-in-email-verification-test"),
            flow_plan=SimpleNamespace(context={"signin_email_address": "inbox"}),
        )
        values.update(overrides)
        return values

    def test_only_matching_email_token_records_verification(self):
        current = account()
        self.assertFalse(evaluate("signin_email_incomplete", self.context(), current=current))
        self.assertEqual(current.attributes, {"email_verified_address": "inbox"})
        current.save.assert_called_once_with(update_fields=["attributes"])

    def test_missing_wrong_account_or_non_email_token_denies(self):
        for token in [None, SimpleNamespace(user_id=2), SimpleNamespace(user_id=1, identifier="invitation")]:
            with self.subTest(token=token):
                current = account()
                self.assertTrue(evaluate("signin_email_incomplete", self.context(is_restored=token), current=current))
                current.save.assert_not_called()

    def test_changed_address_deleted_or_disabled_account_denies(self):
        for current in [None, account(email="changed"), account(is_active=False)]:
            with self.subTest(current=current):
                self.assertTrue(evaluate("signin_email_incomplete", self.context(), current=current))

    def test_missing_destination_snapshot_denies(self):
        context = self.context(flow_plan=SimpleNamespace(context={}))
        self.assertTrue(evaluate("signin_email_incomplete", context, current=account()))

    def test_captures_destination_without_overriding_email(self):
        plan = SimpleNamespace(context={"email": "untrusted"})
        context = dict(pending_user=account(), flow_plan=plan, email="untrusted")
        self.assertFalse(evaluate("signin_email_destination_invalid", context))
        self.assertEqual(plan.context, {"signin_email_address": "inbox"})
        self.assertNotIn("email", context)

    def test_claim_matches_exact_saved_address(self):
        source = (ROOT / "oidc_security.tf").read_text()
        expression = re.search(r"oidc_verified_email_expression = <<-PY\n(.*?)\n\s*PY", source, re.DOTALL)
        for email, verified, expected in [("inbox", "inbox", True), ("changed", "inbox", False), ("", "", False), ("inbox", None, False)]:
            namespace = {"request": SimpleNamespace(user=account(email=email, attributes={"email_verified_address": verified}))}
            exec("def claim():\n" + textwrap.indent(textwrap.dedent(expression.group(1)), "    "), namespace)
            self.assertEqual(namespace["claim"]()["email_verified"], expected)


class RecoveryAndOAuthTests(unittest.TestCase):
    def test_recovery_masks_unknown_inactive_and_throttled_accounts(self):
        for current, count, masked in [(None, 1, True), (account(is_active=False), 1, True), (account(), 4, True), (account(), 3, False)]:
            with self.subTest(current=current, count=count):
                cache = Mock()
                cache.incr.return_value = count
                original = account()
                plan = SimpleNamespace(context={"pending_user": original})
                context = dict(pending_user=original, flow_plan=plan)
                self.assertFalse(evaluate("recovery_prepare", context, current=current, cache=cache))
                self.assertEqual(context["pending_user"].pk is None, masked)
                self.assertIs(context["pending_user"], plan.context["pending_user"])
                cache.add.assert_called_once()
                key = cache.add.call_args.args[0]
                self.assertNotIn(original.email, key)
                self.assertEqual(cache.add.call_args.kwargs["timeout"], 1800)

    def test_unavailable_recovery_cache_does_not_allow_email(self):
        cache = Mock()
        cache.add.side_effect = RuntimeError("cache unavailable")
        with self.assertRaises(RuntimeError):
            evaluate("recovery_prepare", {"pending_user": account()}, cache=cache)

    def test_inactive_recovery_checks_current_database_state(self):
        self.assertFalse(evaluate("inactive_account", {"pending_user": account(pk=None)}))
        for current, denied in [(account(), False), (account(is_active=False), True), (None, True)]:
            self.assertEqual(evaluate("inactive_account", {"pending_user": account()}, current=current), denied)

    def test_recovery_cannot_enroll_an_attacker_factor(self):
        body = resource("authentik_stage_authenticator_validate", "existing_mfa")
        self.assertRegex(body, r'not_configured_action\s*= "deny"')
        self.assertRegex(body, r"configuration_stages\s*= \[\]")
        self.assertRegex(body, r'last_auth_threshold\s*= "seconds=0"')
        self.assertRegex(resource("authentik_stage_email", "recovery_email"), r"activate_user_on_success\s*= false")

    def test_guard_policy_errors_execute_denial(self):
        for name in ["recovery_inactive_account", "recovery_prepare", "signin_email_destination", "signin_email_complete", "password_expired"]:
            self.assertRegex(resource("authentik_policy_binding", name), r"failure_result\s*= true")

    def test_interactive_clients_have_no_password_implicit_or_machine_grants(self):
        for name in ["argo_cd", "mealie", "node_red", "grafana", "native_oidc", "home_assistant", "cloudflare_access"]:
            body = resource("authentik_provider_oauth2", name)
            grants = re.search(r"grant_types\s*= (\[[^\]]*\])", body).group(1)
            self.assertIn('"authorization_code"', grants)
            for forbidden in ['"password"', '"implicit"', '"hybrid"', '"client_credentials"', '"urn:ietf:params:oauth:grant-type:device_code"']:
                self.assertNotIn(forbidden, grants)
            self.assertRegex(body, r'sub_mode\s*= "hashed_user_id"')
            self.assertRegex(body, r'issuer_mode\s*= "per_provider"')


if __name__ == "__main__":
    unittest.main()
