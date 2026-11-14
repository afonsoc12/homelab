"""Forward linked Alexa requests without logging credentials or directive payloads."""

import json
import os
import uuid
import urllib.error
import urllib.parse
import urllib.request


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def failure(kind, directive=None):
    header = {
        "namespace": "Alexa",
        "name": "ErrorResponse",
        "payloadVersion": "3",
        "messageId": str(uuid.uuid4()),
    }
    result = {
        "event": {
            "header": header,
            "payload": {"type": kind, "message": "Request could not be completed"},
        }
    }
    if isinstance(directive, dict):
        source_header = directive.get("header")
        if isinstance(source_header, dict) and isinstance(
            source_header.get("correlationToken"), str
        ):
            header["correlationToken"] = source_header["correlationToken"]
        endpoint = directive.get("endpoint")
        if isinstance(endpoint, dict) and isinstance(endpoint.get("endpointId"), str):
            result["event"]["endpoint"] = {"endpointId": endpoint["endpointId"]}
    return result


def lambda_handler(event, context):
    directive = event.get("directive", {}) if isinstance(event, dict) else {}

    def fail(kind):
        return failure(kind, directive)

    if not isinstance(directive, dict) or any(
        not isinstance(directive.get(k, {}), dict)
        for k in ("header", "payload", "endpoint")
    ):
        return fail("INVALID_DIRECTIVE")
    if directive.get("header", {}).get("payloadVersion") != "3":
        return fail("INVALID_DIRECTIVE")
    payload = directive.get("payload", {})
    scope = (
        directive.get("endpoint", {}).get("scope")
        or payload.get("grantee")
        or payload.get("scope")
        or {}
    )
    if not isinstance(scope, dict):
        return fail("INVALID_AUTHORIZATION_CREDENTIAL")
    token = scope.get("token")
    if (
        scope.get("type") != "BearerToken"
        or not isinstance(token, str)
        or not token
        or any(c in token for c in "\r\n")
    ):
        return fail("INVALID_AUTHORIZATION_CREDENTIAL")
    base = os.environ.get("BASE_URL", "").rstrip("/")
    url = urllib.parse.urlsplit(base)
    if (
        url.scheme != "https"
        or not url.hostname
        or url.username
        or url.password
        or url.query
        or url.fragment
        or url.path
    ):
        return fail("INTERNAL_ERROR")
    headers = {
        "Authorization": "Bearer " + token,
        "Content-Type": "application/json",
        "User-Agent": "HomeAssistantAlexaBridge/1.0",
    }
    # Service credentials are supplied by the encrypted Terraform configuration.
    client_id = os.environ.get("CF_ACCESS_CLIENT_ID")
    client_secret = os.environ.get("CF_ACCESS_CLIENT_SECRET")
    if not client_id or not client_secret:
        return fail("INTERNAL_ERROR")
    headers.update(
        {"CF-Access-Client-Id": client_id, "CF-Access-Client-Secret": client_secret}
    )
    encoded = json.dumps(event).encode()
    if len(encoded) > 256 * 1024:
        return fail("INVALID_DIRECTIVE")
    request = urllib.request.Request(
        base + "/api/alexa/smart_home", data=encoded, headers=headers, method="POST"
    )
    try:
        with urllib.request.build_opener(NoRedirect).open(
            request, timeout=5
        ) as response:
            data = response.read(1024 * 1024 + 1)
            if len(data) > 1024 * 1024:
                return fail("INTERNAL_ERROR")
            result = json.loads(data)
            return (
                result
                if isinstance(result, dict) and "event" in result
                else fail("INTERNAL_ERROR")
            )
    except urllib.error.HTTPError as error:
        return fail(
            "INVALID_AUTHORIZATION_CREDENTIAL"
            if error.code in (401, 403)
            else "INTERNAL_ERROR"
        )
    except urllib.error.URLError, TimeoutError, ValueError, OSError:
        return fail("INTERNAL_ERROR")
