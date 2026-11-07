"""Check invitation admission and email rejection at the source-flow boundary."""

from datetime import datetime, timedelta, timezone
import json
import sys
import textwrap
from types import ModuleType, SimpleNamespace
import unittest
from unittest.mock import patch
from uuid import uuid4

from terraform_policies import read_policy


def evaluate(expression, context, sso=False, request=None, modules=None):
    namespace = {
        "context": context,
        "ak_is_sso_flow": sso,
        "http_request": request,
    }
    exec("def policy():\n" + textwrap.indent(expression, "    "), namespace)
    with patch.dict(sys.modules, modules or {}):
        return namespace["policy"]()


class PlexInvitationTests(unittest.TestCase):
    def setUp(self):
        self.expression = read_policy("plex_invitations.tf", "plex_enrollment_admission")
        self.now = datetime.now(timezone.utc)
        self.invite = SimpleNamespace(
            pk=uuid4(),
            flow_slug="homelab-plex-enrollment",
            single_use=True,
            expiring=True,
            expires=self.now + timedelta(hours=1),
            fixed_data={},
        )
        self.present = True
        self.request = SimpleNamespace(
            session={"authentik/flows/get": {"itoken": str(self.invite.pk)}}
        )
        self.context = {
            "source": SimpleNamespace(pk="plex-source", slug="plex", enabled=True),
            "goauthentik.io/sources/connection": SimpleNamespace(
                source_id="plex-source", identifier="123456"
            ),
            "prompt_data": {"username": "plex-user", "email": "person@invalid"},
        }

        def select(**kwargs):
            matches = (
                self.present
                and kwargs["pk"] == self.invite.pk
                and kwargs["flow__slug"] == self.invite.flow_slug
                and kwargs["single_use"] == self.invite.single_use
                and kwargs["expiring"] == self.invite.expiring
            )
            return SimpleNamespace(first=lambda: self.invite if matches else None)

        invitation_module = ModuleType("authentik.stages.invitation.models")
        invitation_module.Invitation = SimpleNamespace(objects=SimpleNamespace(filter=select))
        timezone_module = ModuleType("django.utils.timezone")
        timezone_module.now = lambda: self.now
        self.modules = {
            "authentik.stages.invitation.models": invitation_module,
            "django.utils.timezone": timezone_module,
        }

    def admit(self, sso=False):
        return evaluate(self.expression, self.context, sso, self.request, self.modules)

    def test_invitation_can_start_without_an_email_or_plex_context(self):
        self.context = {}
        self.assertTrue(self.admit())

    def test_missing_invitation_is_denied_even_after_plex_login(self):
        self.request.session = {}
        self.assertFalse(self.admit(True))

    def test_malformed_invitation_is_denied(self):
        self.request.session["authentik/flows/get"]["itoken"] = "invalid"
        self.assertFalse(self.admit())

    def test_consumed_invitation_is_denied(self):
        self.present = False
        self.assertFalse(self.admit())

    def test_expired_invitation_is_denied(self):
        self.invite.expires = self.now - timedelta(seconds=1)
        self.assertFalse(self.admit())

    def test_invitation_for_another_flow_is_denied(self):
        self.invite.flow_slug = "another-flow"
        self.assertFalse(self.admit())

    def test_reusable_invitation_is_denied(self):
        self.invite.single_use = False
        self.assertFalse(self.admit())

    def test_nonexpiring_invitation_is_denied(self):
        self.invite.expiring = False
        self.assertFalse(self.admit())

    def test_missing_expiry_is_denied(self):
        self.invite.expires = None
        self.assertFalse(self.admit())

    def test_invitation_cannot_override_the_plex_profile(self):
        self.invite.fixed_data = {"email": "another@invalid"}
        self.assertFalse(self.admit(True))

    def test_callback_without_source_proof_is_denied(self):
        self.context.pop("source")
        self.assertFalse(self.admit(True))

    def test_invitation_is_carried_into_the_verified_callback_plan(self):
        self.assertTrue(self.admit(True))
        self.assertEqual(self.context["prompt_data"]["token"], str(self.invite.pk))
        self.assertTrue(self.present, "Admission must not consume the invitation")
        self.request.session = {}
        self.assertTrue(self.admit(True), "Native invitation stage needs the preserved token")


class PlexEmailTests(unittest.TestCase):
    def check(self, email=None, denied=None, sso=True):
        expression = read_policy("plex_invitations.tf", "plex_email_access")
        expression = expression.replace("${jsonencode(local.plex_denied_emails)}", json.dumps(denied or []))
        return evaluate(expression, {"prompt_data": {"email": email}}, sso)

    def test_invitation_entry_does_not_require_an_email(self):
        self.assertTrue(self.check(sso=False))

    def test_missing_plex_email_is_denied(self):
        self.assertFalse(self.check())
        self.assertFalse(self.check("   "))

    def test_denied_email_is_case_and_whitespace_insensitive(self):
        self.assertFalse(self.check(" BlOcKeD@InVaLiD ", ["blocked@invalid"]))
        self.assertFalse(self.check("blocked@invalid", [" BLOCKED@INVALID "]))

    def test_unlisted_email_can_continue(self):
        self.assertTrue(self.check("person@invalid", ["blocked@invalid"]))


if __name__ == "__main__":
    unittest.main()
