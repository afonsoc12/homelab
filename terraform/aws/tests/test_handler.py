import importlib.util
import os
from pathlib import Path
import unittest
from unittest.mock import patch, MagicMock

spec = importlib.util.spec_from_file_location(
    "handler", Path(__file__).parents[1] / "lambda/lambda_function.py"
)
h = importlib.util.module_from_spec(spec)
spec.loader.exec_module(h)


class HandlerTests(unittest.TestCase):
    def directive(self):
        return {
            "directive": {
                "header": {"payloadVersion": "3"},
                "payload": {"scope": {"type": "BearerToken", "token": "user-token"}},
            }
        }

    def test_malformed_directives_do_not_raise(self):
        for e in [
            None,
            [],
            {},
            {"directive": None},
            {"directive": {"header": []}},
            {"directive": {"payload": None}},
        ]:
            self.assertEqual(
                h.lambda_handler(e, None)["event"]["header"]["name"], "ErrorResponse"
            )

    def test_invalid_token_never_reaches_network(self):
        for token in ["", "bad\r\nheader", None]:
            event = self.directive()
            event["directive"]["payload"]["scope"]["token"] = token
            with patch.object(h.urllib.request, "build_opener") as opener:
                self.assertEqual(
                    h.lambda_handler(event, None)["event"]["payload"]["type"],
                    "INVALID_AUTHORIZATION_CREDENTIAL",
                )
                opener.assert_not_called()

    def test_forwarding_preserves_distinct_credentials(self):
        response = MagicMock()
        response.read.return_value = b'{"event":{"payload":{}}}'
        opener = MagicMock()
        opener.open.return_value.__enter__.return_value = response
        with (
            patch.dict(
                os.environ,
                {
                    "BASE_URL": "https://example.invalid",
                    "CF_ACCESS_CLIENT_ID": "service-id",
                    "CF_ACCESS_CLIENT_SECRET": "service-secret",
                },
                clear=True,
            ),
            patch.object(h.urllib.request, "build_opener", return_value=opener),
        ):
            self.assertIn("event", h.lambda_handler(self.directive(), None))
        request = opener.open.call_args.args[0]
        self.assertEqual(request.get_header("Authorization"), "Bearer user-token")
        self.assertEqual(
            request.get_header("Cf-access-client-secret"), "service-secret"
        )

    def test_missing_service_credentials_fail_closed(self):
        with (
            patch.dict(os.environ, {"BASE_URL": "https://example.invalid"}, clear=True),
            patch.object(h.urllib.request, "build_opener") as opener,
        ):
            self.assertEqual(
                h.lambda_handler(self.directive(), None)["event"]["payload"]["type"],
                "INTERNAL_ERROR",
            )
            opener.assert_not_called()

    def test_denial_keeps_correlation_without_echoing_token(self):
        event = self.directive()
        event["directive"]["header"]["correlationToken"] = "correlation"
        event["directive"]["endpoint"] = {
            "endpointId": "device",
            "scope": {"type": "BearerToken", "token": "bad\r\n"},
        }
        result = h.lambda_handler(event, None)
        self.assertEqual(result["event"]["header"]["correlationToken"], "correlation")
        self.assertEqual(result["event"]["endpoint"], {"endpointId": "device"})

    def test_redirects_are_denied(self):
        self.assertIsNone(
            h.NoRedirect().redirect_request(
                None, None, 302, "", {}, "https://example.invalid"
            )
        )

    def test_response_limit(self):
        response = MagicMock()
        response.read.return_value = b"x" * (1024 * 1024 + 1)
        opener = MagicMock()
        opener.open.return_value.__enter__.return_value = response
        with (
            patch.dict(
                os.environ,
                {
                    "BASE_URL": "https://example.invalid",
                    "CF_ACCESS_CLIENT_ID": "service-id",
                    "CF_ACCESS_CLIENT_SECRET": "service-secret",
                },
                clear=True,
            ),
            patch.object(h.urllib.request, "build_opener", return_value=opener),
        ):
            self.assertEqual(
                h.lambda_handler(self.directive(), None)["event"]["payload"]["type"],
                "INTERNAL_ERROR",
            )


if __name__ == "__main__":
    unittest.main()
