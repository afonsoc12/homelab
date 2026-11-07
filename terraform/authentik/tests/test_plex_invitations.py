"""Check callback-token handling and the guards around native invitation stages."""

import json
import re
import textwrap
from types import SimpleNamespace
import unittest
from uuid import uuid4

from terraform_policies import read_policy, read_resource


def evaluate(expression, context, sso=False, request=None):
    namespace = {"context": context, "ak_is_sso_flow": sso, "http_request": request}
    exec("def policy():\n" + textwrap.indent(expression, "    "), namespace)
    return namespace["policy"]()


class PlexInvitationTests(unittest.TestCase):
    def setUp(self):
        self.expression = read_policy("plex_invitations.tf", "plex_enrollment_admission")
        self.token = str(uuid4())
        self.request = SimpleNamespace(session={"authentik/flows/get": {"itoken": self.token}})
        self.context = {"prompt_data": {"email": "person@invalid"}}

    def admit(self, sso=False):
        return evaluate(self.expression, self.context, sso, self.request)

    def test_invitation_entry_requires_no_email(self):
        self.context = {}
        self.assertTrue(self.admit())

    def test_missing_invitation_token_is_denied(self):
        self.request.session = {}
        self.assertFalse(self.admit())
        self.assertFalse(self.admit(True))

    def test_callback_preserves_token_for_native_invitation_validation(self):
        self.assertTrue(self.admit(True))
        self.assertEqual(self.context["prompt_data"]["token"], self.token)

    def test_initial_entry_does_not_modify_the_profile(self):
        self.assertTrue(self.admit())
        self.assertNotIn("token", self.context["prompt_data"])

    def test_callback_can_resume_with_a_token_already_in_its_plan(self):
        self.context["prompt_data"]["token"] = self.token
        self.request.session = {}
        self.assertTrue(self.admit(True))


class PlexInvitationRequirementsTests(unittest.TestCase):
    def setUp(self):
        self.expression = read_policy("plex_invitations.tf", "plex_require_source")
        self.invitation = SimpleNamespace(
            single_use=True, expiring=True, expires=object(), fixed_data={}
        )
        self.context = {
            "source": SimpleNamespace(pk="plex-source", slug="plex", enabled=True),
            "goauthentik.io/sources/connection": SimpleNamespace(
                source_id="plex-source", identifier="123456"
            ),
            "invitation": self.invitation,
        }

    def denied(self):
        return evaluate(self.expression, self.context, True)

    def test_verified_identity_and_native_invitation_can_continue(self):
        self.assertFalse(self.denied())

    def test_missing_native_invitation_result_is_denied(self):
        self.context.pop("invitation")
        self.assertTrue(self.denied())

    def test_reusable_invitation_is_denied(self):
        self.invitation.single_use = False
        self.assertTrue(self.denied())

    def test_nonexpiring_invitation_is_denied(self):
        self.invitation.expiring = False
        self.assertTrue(self.denied())

    def test_missing_expiry_is_denied(self):
        self.invitation.expires = None
        self.assertTrue(self.denied())

    def test_invitation_cannot_override_the_plex_profile(self):
        self.invitation.fixed_data = {"email": "another@invalid"}
        self.assertTrue(self.denied())


class PlexFlowOrderTests(unittest.TestCase):
    def order(self, filename, name):
        block = read_resource(filename, "authentik_flow_stage_binding", name)
        return int(re.search(r"order\s*=\s*(\d+)", block)[1])

    def test_invitation_and_identity_guards_precede_user_creation(self):
        invitation = self.order("plex_invitations.tf", "plex_invitation")
        guard = self.order("plex_invitations.tf", "plex_require_source")
        write = self.order("plex.tf", "plex_enrollment_write")
        mfa = self.order("plex.tf", "plex_mfa")
        login = self.order("plex.tf", "plex_login")
        self.assertLess(invitation, guard)
        self.assertLess(guard, write)
        self.assertLess(write, mfa)
        self.assertLess(mfa, login)

    def test_native_invitation_stage_is_required(self):
        stage = read_resource("stages.tf", "authentik_stage_invitation", "invitation_enrollment")
        binding = read_resource("plex_invitations.tf", "authentik_flow_stage_binding", "plex_invitation")
        self.assertRegex(stage, r"continue_flow_without_invitation\s*=\s*false")
        self.assertIn("authentik_stage_invitation.invitation_enrollment.id", binding)

    def test_policy_errors_execute_the_deny_stage(self):
        block = read_resource("plex_invitations.tf", "authentik_policy_binding", "plex_require_source")
        self.assertRegex(block, r"failure_result\s*=\s*true")

    def test_native_invitation_requires_verified_plex_identity(self):
        block = read_resource("plex_invitations.tf", "authentik_policy_binding", "plex_invitation_source")
        self.assertIn("authentik_flow_stage_binding.plex_invitation.id", block)
        self.assertIn("authentik_policy_expression.plex_source_context.id", block)
        self.assertRegex(block, r"failure_result\s*=\s*false")


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
