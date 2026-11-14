"""Authenticate the Alexa OAuth client before forwarding to protected native OAuth."""

import base64
import binascii
import hmac
import json
import os
import urllib.error
import urllib.parse
import urllib.request


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def reply(status, value):
    return {
        "statusCode": status,
        "headers": {
            "content-type": "application/json",
            "cache-control": "no-store",
            "pragma": "no-cache",
        },
        "body": json.dumps(value),
    }


def lambda_handler(event, context):
    if not isinstance(event, dict):
        return reply(400, {"error": "invalid_request"})
    request = event.get("requestContext", {}).get("http", {})
    if (
        request.get("method") != "POST"
        or event.get("rawPath") != "/auth/token"
        or event.get("rawQueryString")
    ):
        return reply(404, {"error": "invalid_request"})
    headers = {k.lower(): v for k, v in event.get("headers", {}).items()}
    if (
        headers.get("content-type", "").split(";", 1)[0].strip().lower()
        != "application/x-www-form-urlencoded"
    ):
        return reply(415, {"error": "invalid_request"})
    auth = headers.get("authorization", "")
    expected_id = os.environ.get("OAUTH_CLIENT_ID", "")
    expected_secret = os.environ.get("OAUTH_CLIENT_SECRET", "")
    service_id = os.environ.get("CF_ACCESS_CLIENT_ID", "")
    service_secret = os.environ.get("CF_ACCESS_CLIENT_SECRET", "")
    if not all((expected_id, expected_secret, service_id, service_secret)):
        return reply(503, {"error": "temporarily_unavailable"})
    try:
        scheme, credentials = auth.split(" ", 1)
        if scheme.lower() != "basic" or len(credentials) > 8192:
            raise ValueError()
        client_id, secret = (
            base64.b64decode(credentials, validate=True).decode().rsplit(":", 1)
        )
        # RFC 6749 section 2.3.1 applies form encoding before HTTP Basic.
        client_id, secret = (
            urllib.parse.unquote_plus(client_id),
            urllib.parse.unquote_plus(secret),
        )
        valid_id = hmac.compare_digest(client_id.encode(), expected_id.encode())
        valid_secret = hmac.compare_digest(secret.encode(), expected_secret.encode())
        if not (valid_id and valid_secret):
            return reply(401, {"error": "invalid_client"})
    except ValueError, UnicodeError, binascii.Error:
        return reply(401, {"error": "invalid_client"})
    try:
        raw = event.get("body", "")
        if not isinstance(raw, str) or len(raw) > 32768:
            raise ValueError()
        body = (
            base64.b64decode(raw, validate=True)
            if event.get("isBase64Encoded")
            else raw.encode()
        )
        if len(body) > 16384:
            raise ValueError()
        form = urllib.parse.parse_qs(
            body.decode(),
            keep_blank_values=True,
            strict_parsing=True,
            max_num_fields=12,
        )
        if any(len(values) != 1 for values in form.values()):
            raise ValueError()
        grant = form.get("grant_type", [""])[0]
        if grant not in ("authorization_code", "refresh_token"):
            return reply(400, {"error": "unsupported_grant_type"})
        allowed = (
            {"grant_type", "client_id", "client_secret", "code", "redirect_uri"}
            if grant == "authorization_code"
            else {"grant_type", "client_id", "client_secret", "refresh_token", "scope"}
        )
        if (
            set(form) - allowed
            or not form.get(
                "code" if grant == "authorization_code" else "refresh_token", [""]
            )[0]
        ):
            raise ValueError()
        if "client_id" in form and not hmac.compare_digest(
            form["client_id"][0].encode(), expected_id.encode()
        ):
            raise ValueError()
        # Native Home Assistant remains the authority for codes and refresh tokens.
        form["client_id"] = [expected_id]
        form.pop("client_secret", None)
        upstream_body = urllib.parse.urlencode(
            {k: v[0] for k, v in form.items()}
        ).encode()
        base = urllib.parse.urlsplit(os.environ.get("BASE_URL", ""))
        if (
            base.scheme != "https"
            or not base.hostname
            or base.path
            or base.query
            or base.fragment
            or base.username
            or base.password
        ):
            raise ValueError()
    except ValueError, UnicodeError, binascii.Error:
        return reply(400, {"error": "invalid_request"})
    req = urllib.request.Request(
        base.geturl() + "/auth/token",
        data=upstream_body,
        method="POST",
        headers={
            "Content-Type": "application/x-www-form-urlencoded",
            "User-Agent": "HomeAssistantAlexaOAuth/1.0",
            "CF-Access-Client-Id": service_id,
            "CF-Access-Client-Secret": service_secret,
        },
    )
    try:
        with urllib.request.build_opener(NoRedirect).open(req, timeout=5) as response:
            raw = response.read(65537)
            if len(raw) > 65536 or "application/json" not in response.headers.get(
                "Content-Type", ""
            ):
                return reply(502, {"error": "server_error"})
            value = json.loads(raw)
            if not isinstance(value, dict) or not isinstance(
                value.get("access_token"), str
            ):
                return reply(502, {"error": "server_error"})
            return reply(
                200,
                {
                    k: v
                    for k, v in value.items()
                    if k
                    in {
                        "access_token",
                        "token_type",
                        "refresh_token",
                        "expires_in",
                        "scope",
                        "ha_auth_provider",
                    }
                },
            )
    except urllib.error.HTTPError as error:
        if error.code == 400 and "application/json" in error.headers.get(
            "Content-Type", ""
        ):
            return reply(400, {"error": "invalid_grant"})
        return reply(502, {"error": "server_error"})
    except urllib.error.URLError, OSError, ValueError:
        return reply(502, {"error": "server_error"})
