"""Stock FAB OAuth configuration; deployment values supply the credentials."""

import os

from flask_appbuilder.const import AUTH_OAUTH

ISSUER = os.environ["AIRFLOW_OIDC_ISSUER"]
AUTH_TYPE = AUTH_OAUTH
AUTH_USER_REGISTRATION = False
AUTH_ROLES_SYNC_AT_LOGIN = False

OAUTH_PROVIDERS = [
    {
        "name": "authentik",
        "token_key": "access_token",
        "remote_app": {
            "client_id": os.environ["AIRFLOW_OIDC_CLIENT_ID"],
            "client_secret": os.environ["AIRFLOW_OIDC_CLIENT_SECRET"],
            "server_metadata_url": ISSUER.rstrip("/") + "/.well-known/openid-configuration",
            "client_kwargs": {
                "scope": "openid profile",
                "code_challenge_method": "S256",
                "verify_signature": True,
                "issuer": ISSUER,
            },
        },
    },
]
