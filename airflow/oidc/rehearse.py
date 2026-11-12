"""Exercise the candidate through its actual browser and native API entrypoints."""

import json
import os
import time
from unittest.mock import patch
from urllib.parse import parse_qs, urlsplit

import jwt
from airflow.api_fastapi.app import create_app
from airflow.providers.fab.auth_manager.models import User
from airflow.utils.session import create_session
from cryptography.hazmat.primitives.asymmetric import rsa
from fastapi.testclient import TestClient
from requests import Response

ISSUER = os.environ["AIRFLOW_OIDC_ISSUER"]
CLIENT_ID = os.environ["AIRFLOW_OIDC_CLIENT_ID"]
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
    with create_session() as session:
        return {user.username: (user.id, tuple(role.name for role in user.roles)) for user in session.query(User).all()}


def browser_login(client, subject, issuer=ISSUER, audience=CLIENT_ID):
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
            claims = {"iss": issuer, "sub": subject, "aud": audience, "iat": now, "exp": now + 300, "nonce": params["nonce"][0]}
            body = {
                "access_token": "synthetic-access",
                "token_type": "Bearer",
                "id_token": jwt.encode(claims, KEY, algorithm="RS256", headers={"kid": "rehearsal"}),
            }
        else:
            raise AssertionError("Unexpected provider request")
        response._content = json.dumps(body).encode()
        return response

    client.cookies.clear()
    with patch("requests.sessions.Session.request", side_effect=provider_request):
        login = client.get("/auth/login/authentik", follow_redirects=False)
        assert login.is_redirect
        params = parse_qs(urlsplit(login.headers["location"]).query)
        assert params["code_challenge_method"] == ["S256"]
        assert params["nonce"]
        callback = urlsplit(params["redirect_uri"][0])
        assert callback.path == "/auth/oauth-authorized/authentik"
        result = client.get(callback.path, params={"code": "synthetic-code", "state": params["state"][0]}, follow_redirects=False)
        assert result.is_redirect
        return "/login" not in result.headers["location"]


before = existing_users()
with TestClient(create_app(), base_url="https://testserver") as client:
    assert client.get("/api/v2/dags").status_code == 401
    assert client.get("/auth/token").status_code in (404, 405)
    for username, password in (("rehearsal-viewer", "synthetic-value"), ("rehearsal-machine", "wrong-value")):
        assert client.post("/auth/token", json={"username": username, "password": password}).status_code == 401

    machine = client.post("/auth/token", json={"username": "rehearsal-machine", "password": "synthetic-value"})
    assert machine.status_code == 201
    headers = {"Authorization": "Bearer " + machine.json()["access_token"]}
    assert client.get("/api/v2/dags", headers=headers).status_code == 200
    assert client.post("/api/v2/variables", json={"key": "rehearsal-denied", "value": "synthetic"}, headers=headers).status_code == 403

    with create_session() as session:
        session.query(User).filter_by(username="rehearsal-machine").one().active = False
    assert client.post("/auth/token", json={"username": "rehearsal-machine", "password": "synthetic-value"}).status_code == 401

    assert browser_login(client, "synthetic-subject")
    assert not browser_login(client, "unmapped-subject")
    assert not browser_login(client, "synthetic-subject", issuer="https://wrong-issuer/")
    assert not browser_login(client, "synthetic-subject", audience="wrong-audience")
    assert existing_users() == before

    from airflow.providers.fab.auth_manager.cli_commands.utils import get_application_builder
    from homelab_auth.accounts import rename_admin

    with get_application_builder() as builder:
        owner = builder.sm.add_user(
            "admin", "Synthetic", "Owner", "owner@synthetic", builder.sm.find_role("Admin"), password="synthetic-value"
        )
        assert owner is not None
        owner_id = owner.id
    rename = {"id": owner_id, "from": "admin", "to": "rehearsal-owner"}
    assert rename_admin(rename) == "ready"
    assert "admin" in existing_users() and "rehearsal-owner" not in existing_users()
    assert rename_admin(rename, apply=True) == "renamed"
    assert rename_admin(rename, apply=True) == "already-renamed"
    assert "admin" not in existing_users()
    assert existing_users()["rehearsal-owner"] == (owner_id, ("Admin",))
    for name, identity in before.items():
        assert existing_users()[name] == identity
    assert browser_login(client, "synthetic-owner")
    assert client.post("/api/v2/variables", json={"key": "rehearsal-owner-write", "value": "synthetic"}).status_code == 201

print("OIDC browser/API, owner-admin access and default-admin rename passed with preserved IDs and roles")
