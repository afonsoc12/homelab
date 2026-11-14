import base64
import importlib.util
import json
import os
from pathlib import Path
import unittest
from unittest.mock import MagicMock, patch
import urllib.error
import urllib.parse

spec = importlib.util.spec_from_file_location(
    "oauth", Path(__file__).parents[1] / "lambda/oauth_gateway.py"
)
h = importlib.util.module_from_spec(spec)
spec.loader.exec_module(h)


class OAuthGatewayTests(unittest.TestCase):
    def setUp(self):
        self.host = "https://" + ".".join(("upstream", "invalid"))
        self.env = {
            "BASE_URL": self.host,
            "OAUTH_CLIENT_ID": "client-id",
            "OAUTH_CLIENT_SECRET": "client-secret",
            "CF_ACCESS_CLIENT_ID": "service-id",
            "CF_ACCESS_CLIENT_SECRET": "service-secret",
        }
        self.auth = "Basic " + base64.b64encode(b"client-id:client-secret").decode()
        self.event = {
            "requestContext": {"http": {"method": "POST"}},
            "rawPath": "/auth/token",
            "rawQueryString": "",
            "headers": {
                "content-type": "application/x-www-form-urlencoded",
                "authorization": self.auth,
            },
            "body": "grant_type=refresh_token&refresh_token=user-refresh",
        }
        self.patch = patch.dict(os.environ, self.env, clear=True)
        self.patch.start()
        self.addCleanup(self.patch.stop)

    def test_missing_and_bad_client_secret_never_reach_upstream(self):
        for auth in [
            "",
            "Bearer user-token",
            "Basic !!!",
            "Basic " + base64.b64encode(b"client-id:wrong").decode(),
        ]:
            self.event["headers"]["authorization"] = auth
            with patch.object(h.urllib.request, "build_opener") as opener:
                self.assertEqual(h.lambda_handler(self.event, None)["statusCode"], 401)
                opener.assert_not_called()

    def test_only_exact_post_token_route(self):
        for path in [
            "/",
            "/api/alexa/smart_home",
            "/auth/token/",
            "/auth%2ftoken",
            "//auth/token",
        ]:
            self.event["rawPath"] = path
            self.assertEqual(h.lambda_handler(self.event, None)["statusCode"], 404)
        self.event["rawPath"] = "/auth/token"
        self.event["requestContext"]["http"]["method"] = "GET"
        self.assertEqual(h.lambda_handler(self.event, None)["statusCode"], 404)

    def test_reject_query_and_wrong_content_type(self):
        self.event["rawQueryString"] = "target=other"
        self.assertEqual(h.lambda_handler(self.event, None)["statusCode"], 404)
        self.event["rawQueryString"] = ""
        self.event["headers"]["content-type"] = "application/json"
        self.assertEqual(h.lambda_handler(self.event, None)["statusCode"], 415)

    def test_duplicate_fields_wrong_client_and_unknown_grants_denied(self):
        for body in [
            "grant_type=refresh_token&refresh_token=a&refresh_token=b",
            "grant_type=refresh_token&refresh_token=a&client_id=wrong",
            "grant_type=password&username=admin&password=secret",
            "grant_type=refresh_token&refresh_token=a&target=other",
        ]:
            self.event["body"] = body
            with patch.object(h.urllib.request, "build_opener") as opener:
                self.assertEqual(h.lambda_handler(self.event, None)["statusCode"], 400)
                opener.assert_not_called()

    def test_missing_configuration_fails_closed(self):
        with patch.dict(os.environ, {}, clear=True):
            self.assertEqual(h.lambda_handler(self.event, None)["statusCode"], 503)

    def test_forwarding_uses_service_credentials_and_native_refresh_token(self):
        response = MagicMock()
        response.headers = {"Content-Type": "application/json"}
        response.read.return_value = b'{"access_token":"native-access","refresh_token":"native-refresh","unexpected":"ignored"}'
        opener = MagicMock()
        opener.open.return_value.__enter__.return_value = response
        with patch.object(h.urllib.request, "build_opener", return_value=opener):
            result = h.lambda_handler(self.event, None)
        self.assertEqual(result["statusCode"], 200)
        self.assertNotIn("unexpected", json.loads(result["body"]))
        self.assertEqual(result["headers"]["cache-control"], "no-store")
        req = opener.open.call_args.args[0]
        self.assertEqual(req.full_url, self.host + "/auth/token")
        self.assertEqual(req.get_header("Cf-access-client-secret"), "service-secret")
        self.assertIsNone(req.get_header("Authorization"))
        self.assertEqual(
            urllib.parse.parse_qs(req.data.decode())["refresh_token"], ["user-refresh"]
        )

    def test_upstream_redirect_and_access_denial_are_not_forwarded(self):
        for status in [302, 401, 403, 500]:
            opener = MagicMock()
            opener.open.side_effect = urllib.error.HTTPError(
                self.host, status, "denied", {}, None
            )
            with patch.object(h.urllib.request, "build_opener", return_value=opener):
                result = h.lambda_handler(self.event, None)
            self.assertEqual(result["statusCode"], 502)
            self.assertNotIn("client-secret", result["body"])

    def test_invalid_native_refresh_is_denied(self):
        opener = MagicMock()
        opener.open.side_effect = urllib.error.HTTPError(
            self.host, 400, "", {"Content-Type": "application/json"}, None
        )
        with patch.object(h.urllib.request, "build_opener", return_value=opener):
            self.assertEqual(
                json.loads(h.lambda_handler(self.event, None)["body"]),
                {"error": "invalid_grant"},
            )


if __name__ == "__main__":
    unittest.main()
