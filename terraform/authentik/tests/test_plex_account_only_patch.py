"""Verify the narrowly scoped Plex patch against the pinned upstream module."""

import ast
from contextlib import redirect_stdout
import hashlib
import io
from pathlib import Path
from types import SimpleNamespace
import unittest

import yaml


ROOT = Path(__file__).parents[3]
FIXTURE = Path(__file__).parent / "fixtures/plex_2026_8_5.py"


class PlexAccountOnlyPatchTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        values = yaml.safe_load(
            (ROOT / "kubernetes/apps/ingress/authentik/plex-account-only.yaml").read_text()
        )
        script = values["server"]["initContainers"][0]["args"][0]
        function = next(
            node for node in ast.parse(script).body
            if isinstance(node, ast.FunctionDef) and node.name == "patch_plex"
        )
        namespace = {"ast": ast, "hashlib": hashlib}
        exec(compile(ast.Module(body=[function], type_ignores=[]), "patch", "exec"), namespace)
        cls.patch = staticmethod(namespace["patch_plex"])
        cls.original = FIXTURE.read_text()

    def patched(self, source=None, version="2026.8.5"):
        with redirect_stdout(io.StringIO()):
            return self.patch(self.original if source is None else source, version)

    def check(self, slug="plex", allowed=None, friends=False, resources=None, offline=False):
        tree = ast.parse(self.patched())
        plex_class = next(n for n in tree.body if isinstance(n, ast.ClassDef) and n.name == "PlexAuth")
        method = next(n for n in plex_class.body if isinstance(n, ast.FunctionDef) and n.name == "check_server_overlap")
        namespace = {
            "RequestException": RuntimeError,
            "Http404": LookupError,
            "LOGGER": SimpleNamespace(info=lambda *a, **k: None, warning=lambda *a, **k: None),
        }
        exec(compile(ast.Module(body=[method], type_ignores=[]), "plex", "exec"), namespace)
        calls = []

        def get_resources():
            calls.append(True)
            if offline:
                raise RuntimeError("Plex Media Server is offline")
            return resources or []

        instance = SimpleNamespace(
            _source=SimpleNamespace(slug=slug, allowed_servers=allowed or [], allow_friends=friends),
            get_resources=get_resources,
        )
        return namespace["check_server_overlap"](instance), calls

    def test_pinned_upstream_fixture_is_the_reviewed_module(self):
        self.assertEqual(
            hashlib.sha256(self.original.encode()).hexdigest(),
            "df272bb88ebad60953c9fe487cef087c8d20b0c64c456e243ae3e71af30c186a",
        )

    def test_account_only_mode_works_without_any_server_resources(self):
        passed, calls = self.check()
        self.assertTrue(passed)
        self.assertFalse(calls)

    def test_account_only_mode_does_not_contact_an_offline_server(self):
        passed, calls = self.check(offline=True)
        self.assertTrue(passed)
        self.assertFalse(calls)

    def test_other_sources_keep_the_upstream_restrictions(self):
        self.assertFalse(self.check(slug="another-plex-source")[0])

    def test_friend_restricted_mode_is_not_changed(self):
        self.assertFalse(self.check(friends=True)[0])

    def test_explicit_server_restrictions_are_preserved(self):
        server = {"provides": "server", "clientIdentifier": "allowed", "name": "Test"}
        self.assertTrue(self.check(allowed=["allowed"], resources=[server])[0])
        self.assertFalse(self.check(allowed=["another"], resources=[server])[0])

    def test_an_offline_explicitly_restricted_source_still_denies(self):
        with self.assertRaises(LookupError):
            self.check(allowed=["allowed"], offline=True)

    def test_unreviewed_versions_keep_upstream_behavior(self):
        self.assertEqual(self.patched(version="2026.9.0"), self.original)

    def test_modified_upstream_modules_are_not_patched(self):
        changed = self.original + "\n# Changed upstream implementation\n"
        self.assertEqual(self.patched(source=changed), changed)

    def test_only_the_server_restriction_method_changes(self):
        before = ast.parse(self.original)
        after = ast.parse(self.patched())
        for tree in (before, after):
            plex_class = next(n for n in tree.body if isinstance(n, ast.ClassDef) and n.name == "PlexAuth")
            plex_class.body = [
                n for n in plex_class.body
                if not isinstance(n, ast.FunctionDef) or n.name != "check_server_overlap"
            ]
        self.assertEqual(ast.dump(before), ast.dump(after))


if __name__ == "__main__":
    unittest.main()
