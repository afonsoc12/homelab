"""Exercise the configured OIDC client, including callback validation."""

import base64
import hashlib
import importlib.util
import time
from pathlib import Path
from urllib.parse import parse_qs, urlsplit

import pytest
from authlib.integrations.flask_client import OAuth
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from flask import Flask
from joserfc import jwt
from joserfc.jwk import RSAKey


@pytest.fixture
def oidc(monkeypatch):
    monkeypatch.setenv("OIDC_CLIENT_SECRET", "test-only")
    monkeypatch.setenv("OIDC_DISCOVERY_URL", "https://localhost/.well-known/openid-configuration")
    spec = importlib.util.spec_from_file_location("oidc_config", Path(__file__).parents[1] / "webserver_config.py")
    config = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(config)

    app = Flask(__name__)
    app.secret_key = "test-only"
    remote = OAuth(app).register("oidc", **config.OAUTH_PROVIDERS[0]["remote_app"])
    remote.server_metadata.update(
        issuer="https://localhost",
        authorization_endpoint="https://localhost/authorize",
        token_endpoint="https://localhost/token",
        jwks_uri="https://localhost/jwks",
        id_token_signing_alg_values_supported=["RS256"],
    )
    monkeypatch.setattr(remote, "load_server_metadata", lambda: remote.server_metadata)

    @app.get("/login")
    def login():
        return remote.authorize_redirect("https://localhost/callback")

    @app.get("/callback")
    def callback():
        return dict(remote.authorize_access_token()["userinfo"])

    private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    pem = private_key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8, serialization.NoEncryption())
    key = RSAKey.import_key(pem)
    public = key.as_dict(private=False)
    public["kid"] = "test"
    monkeypatch.setattr(remote, "fetch_jwk_set", lambda **kwargs: {"keys": [public]})

    app.testing = True
    client = app.test_client()
    params = parse_qs(urlsplit(client.get("/login").location).query)
    claims = {
        "iss": "https://localhost",
        "aud": "airflow",
        "sub": "existing-subject",
        "iat": int(time.time()),
        "exp": int(time.time()) + 300,
        "nonce": params["nonce"][0],
        "preferred_username": "acosta",
    }
    exchanges = []

    def exchange(**kwargs):
        exchanges.append(kwargs)
        return {
            "access_token": "test-only",
            "token_type": "Bearer",
            "id_token": jwt.encode({"alg": "RS256", "kid": "test"}, claims, key),
        }

    monkeypatch.setattr(remote, "fetch_access_token", exchange)
    return client, params, claims, exchanges


def test_oidc_uses_code_flow_pkce_and_validates_identity(oidc):
    client, params, _, exchanges = oidc
    assert params["response_type"] == ["code"]
    assert params["code_challenge_method"] == ["S256"]
    assert "openid" in params["scope"][0].split()
    response = client.get("/callback", query_string={"code": "test-code", "state": params["state"][0]})
    assert response.json["preferred_username"] == "acosta"
    verifier = exchanges[0]["code_verifier"]
    challenge = base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).rstrip(b"=").decode()
    assert challenge == params["code_challenge"][0]


@pytest.mark.parametrize("claim,value", [("iss", "https://untrusted"), ("aud", "other-client"), ("nonce", "wrong-nonce"), ("exp", 1)])
def test_oidc_rejects_invalid_token_claims(oidc, claim, value):
    client, params, claims, _ = oidc
    claims[claim] = value
    with pytest.raises(Exception, match="iss|aud|nonce|expired"):
        client.get("/callback", query_string={"code": "test-code", "state": params["state"][0]})


def test_oidc_rejects_missing_session_state_before_token_exchange(oidc):
    client, _, _, exchanges = oidc
    with pytest.raises(Exception, match="state"):
        client.get("/callback", query_string={"code": "test-code", "state": "wrong-state"})
    assert exchanges == []


def test_oidc_rejects_token_signed_by_another_key(oidc, monkeypatch):
    client, params, _, _ = oidc
    wrong_key = RSAKey.generate_key(2048)
    encode = jwt.encode
    monkeypatch.setattr(jwt, "encode", lambda header, claims, key: encode(header, claims, wrong_key))
    with pytest.raises(Exception, match="signature"):
        client.get("/callback", query_string={"code": "test-code", "state": params["state"][0]})
