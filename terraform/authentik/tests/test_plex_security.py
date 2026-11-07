"""Exercise the source-flow guard without requiring a running Authentik instance."""

from pathlib import Path
import textwrap
from types import SimpleNamespace
import unittest


class PlexSourceGuardTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        expression = (Path(__file__).parents[1] / "policies/plex_source_context.py.tftpl").read_text()
        namespace = {}
        exec(
            "def guard(context, ak_is_sso_flow):\n"
            + textwrap.indent(expression.replace("${deny_unverified}", "False"), "    "),
            namespace,
        )
        cls.guard = staticmethod(namespace["guard"])
        namespace = {}
        exec(
            "def deny(context, ak_is_sso_flow):\n"
            + textwrap.indent(expression.replace("${deny_unverified}", "True"), "    "),
            namespace,
        )
        cls.deny = staticmethod(namespace["deny"])

    def setUp(self):
        self.source = SimpleNamespace(pk="plex-source", slug="plex", enabled=True)
        self.connection = SimpleNamespace(source_id="plex-source", identifier="123456")
        self.context = {
            "source": self.source,
            "goauthentik.io/sources/connection": self.connection,
        }

    def test_verified_plex_callback_can_continue(self):
        self.assertTrue(self.guard(self.context, True))

    def test_direct_flow_url_is_denied(self):
        self.assertFalse(self.guard({}, False))

    def test_sso_flag_alone_is_insufficient(self):
        self.assertFalse(self.guard({}, True))

    def test_source_context_without_sso_is_denied(self):
        self.assertFalse(self.guard(self.context, False))

    def test_another_source_is_denied(self):
        self.source.slug = "another-source"
        self.assertFalse(self.guard(self.context, True))

    def test_disabled_source_is_denied(self):
        self.source.enabled = False
        self.assertFalse(self.guard(self.context, True))

    def test_missing_connection_is_denied(self):
        del self.context["goauthentik.io/sources/connection"]
        self.assertFalse(self.guard(self.context, True))

    def test_connection_from_another_source_is_denied(self):
        self.connection.source_id = "another-source"
        self.assertFalse(self.guard(self.context, True))

    def test_missing_plex_identity_is_denied(self):
        self.connection.identifier = ""
        self.assertFalse(self.guard(self.context, True))

    def test_deny_stage_runs_when_source_proof_is_missing(self):
        self.assertTrue(self.deny({}, False))
        self.assertTrue(self.deny(self.context, False))

    def test_deny_stage_is_skipped_only_with_verified_source(self):
        self.assertFalse(self.deny(self.context, True))


if __name__ == "__main__":
    unittest.main()
