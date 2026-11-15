import importlib.util
import json
from pathlib import Path
import unittest
from unittest.mock import patch, MagicMock

spec = importlib.util.spec_from_file_location("authenticate", Path(__file__).parents[1] / "tools/authenticate.py")
auth = importlib.util.module_from_spec(spec)
spec.loader.exec_module(auth)


class AuthenticationTests(unittest.TestCase):
    def test_cli_failure_does_not_expose_output(self):
        with patch.dict(auth.os.environ, {"ASK_SMAPI_BIN": "ask-smapi"}), patch.object(auth.subprocess, "run", return_value=MagicMock(returncode=1, stderr=b"secret")):
            with self.assertRaisesRegex(RuntimeError, "ASK authentication failed") as error:
                auth.authenticate({})
            self.assertNotIn("secret", str(error.exception))

    def read(self, etag):
        response = MagicMock()
        response.__enter__.return_value.headers = {"ETag": etag}
        config = json.dumps({"profiles": {"default": {"token": {"access_token": "test-only"}}}})
        with patch.dict(auth.os.environ, {"ASK_SMAPI_BIN": "ask-smapi", "ASK_PROFILE": "default"}), patch.object(auth.subprocess, "run", return_value=MagicMock(returncode=0)), patch.object(auth.Path, "read_text", return_value=config), patch.object(auth.urllib.request, "urlopen", return_value=response) as request:
            result = auth.authenticate({"uri": "https://example.invalid", "paths": json.dumps({"manifest": "/manifest"})})
            self.assertEqual(request.call_args.args[0].get_header("Authorization"), "Bearer test-only")
            return result

    def test_requires_etag_for_updates(self):
        with self.assertRaisesRegex(RuntimeError, "no ETag"):
            self.read(None)

    def test_returns_resource_specific_etag(self):
        self.assertEqual(self.read('"version"'), {"access_token": "test-only", "manifest": '"version"'})


if __name__ == "__main__":
    unittest.main()
