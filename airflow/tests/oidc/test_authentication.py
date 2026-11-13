"""Exercise stock FAB browser login and preserve existing account permissions."""

import json
import os
import time
from unittest.mock import patch
from urllib.parse import parse_qs, urlsplit

import jwt
import pytest
from airflow.api_fastapi.app import create_app
from airflow.utils.session import create_session
from cryptography.hazmat.primitives.asymmetric import rsa
from fastapi.testclient import TestClient
from requests import Response

pytestmark = pytest.mark.skipif(
    os.environ.get("AIRFLOW_AUTH_TEST_MODE") != "oidc",
    reason="Use tests/oidc/run.sh to initialize a disposable authentication database",
)

ISSUER = os.environ.get("AIRFLOW_OIDC_ISSUER", "https://synthetic-issuer/")
CLIENT_ID = os.environ.get("AIRFLOW_OIDC_CLIENT_ID", "synthetic-client")
KEY = rsa.generate_private_key(public_exponent=65537, key_size=2048)
JWK = json.loads(jwt.algorithms.RSAAlgorithm.to_jwk(KEY.public_key())) | {"kid": "rehearsal", "use": "sig", "alg": "RS256"}
METADATA = {
    "issuer": ISSUER,
    "authorization_endpoint": ISSUER + "authorize",
    "token_endpoint": ISSUER + "token",
    "jwks_uri": ISSUER + "jwks",
    "code_challenge_methods_supported": ["S256"],
    "id_token_signing_alg_values_supported": ["RS256"],
}


def existing_users():
    from airflow.providers.fab.auth_manager.models import User

    with create_session() as session:
        return {user.username: (user.id, tuple(role.name for role in user.roles)) for user in session.query(User).all()}


def browser_login(client, subject, issuer=ISSUER, audience=CLIENT_ID, *, nonce=None, expires_in=300, signing_key=KEY):
    def provider_request(method, url, **kwargs):
        response = Response()
        response.status_code = 200
        response.headers["content-type"] = "application/json"
        if url.endswith("/.well-known/openid-configuration"):
            body = METADATA
        elif url == METADATA["jwks_uri"]:
            body = {"keys": [JWK]}
        elif url == METADATA["token_endpoint"]:
            data = kwargs["data"]
            verifier = parse_qs(data)["code_verifier"] if isinstance(data, str) else data["code_verifier"]
            assert verifier
            now = int(time.time())
            username = {"synthetic-subject": "rehearsal-viewer", "synthetic-owner": "rehearsal-owner"}.get(subject, "")
            claims = {
                "nickname": username,
                "preferred_username": username,
                "groups": ["untrusted-admin-role"],
                "iss": issuer,
                "sub": subject,
                "aud": audience,
                "iat": now,
                "exp": now + expires_in,
                "nonce": nonce if nonce is not None else params["nonce"][0],
            }
            body = {
                "access_token": "synthetic-access",
                "token_type": "Bearer",
                "id_token": jwt.encode(claims, signing_key, algorithm="RS256", headers={"kid": "rehearsal"}),
            }
        else:
            raise AssertionError("Unexpected provider request")
        response._content = json.dumps(body).encode()
        return response

    client.cookies.clear()
    with patch("requests.sessions.Session.request", side_effect=provider_request):
        login = client.get("/auth/login/authentik", follow_redirects=False)
        assert login.is_redirect
        cookies = login.headers.get_list("set-cookie")
        assert any("secure" in cookie.lower() and "httponly" in cookie.lower() and "samesite=lax" in cookie.lower() for cookie in cookies)
        params = parse_qs(urlsplit(login.headers["location"]).query)
        assert params["code_challenge_method"] == ["S256"]
        assert params["nonce"]
        callback = urlsplit(params["redirect_uri"][0])
        assert callback.path == "/auth/oauth-authorized/authentik"
        result = client.get(callback.path, params={"code": "synthetic-code", "state": params["state"][0]}, follow_redirects=False)
        assert result.is_redirect
        return "/login" not in result.headers["location"]


def test_stock_oidc_preserves_account_identity_and_permissions():
    from airflow.providers.fab.auth_manager.models import User

    before = existing_users()
    with TestClient(create_app(), base_url="https://testserver") as client:
        assert client.get("/api/v2/dags").status_code == 401
        assert client.get("/auth/token").status_code in (404, 405)
        for username, password in (("rehearsal-viewer", "synthetic-value"), ("rehearsal-owner", "wrong-value")):
            assert client.post("/auth/token", json={"username": username, "password": password}).status_code == 401

        # Stock FAB never issues password tokens when AUTH_TYPE is OAuth.
        for username in ("rehearsal-viewer", "rehearsal-owner", "unknown-user"):
            assert client.post("/auth/token", json={"username": username, "password": "synthetic-value"}).status_code == 401

        assert browser_login(client, "synthetic-subject")
        assert client.get("/api/v2/dags").status_code == 200
        assert client.post("/api/v2/variables", json={"key": "rehearsal-viewer-denied", "value": "synthetic"}).status_code == 403
        assert not browser_login(client, "unmapped-subject")
        assert not browser_login(client, "synthetic-subject", issuer="https://wrong-issuer/")
        assert not browser_login(client, "synthetic-subject", audience="wrong-audience")
        assert not browser_login(client, "synthetic-subject", nonce="wrong-nonce")
        assert not browser_login(client, "synthetic-subject", expires_in=-3600)
        assert not browser_login(client, "synthetic-subject", signing_key=rsa.generate_private_key(public_exponent=65537, key_size=2048))
        with create_session() as session:
            session.query(User).filter_by(username="rehearsal-viewer").one().active = False
        assert not browser_login(client, "synthetic-subject")
        with create_session() as session:
            session.query(User).filter_by(username="rehearsal-viewer").one().active = True
        assert existing_users() == before

        assert browser_login(client, "synthetic-owner")
        assert client.post("/api/v2/variables", json={"key": "rehearsal-owner-write", "value": "synthetic"}).status_code == 201
        assert existing_users() == before
