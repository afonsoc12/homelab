"""Native OIDC through FAB; Authlib validates tokens using OpenID discovery."""

import os

from flask_appbuilder.const import AUTH_OAUTH

AUTH_TYPE = AUTH_OAUTH
AUTH_USER_REGISTRATION = True
AUTH_USER_REGISTRATION_ROLE = "Public"
AUTH_ROLES_SYNC_AT_LOGIN = True
AUTH_ROLES_MAPPING = {"authentik_admins": ["Admin"]}

SESSION_COOKIE_SECURE = True
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = "Lax"

OAUTH_PROVIDERS = [
    {
        # FAB's generic OIDC mapping uses preferred_username and email unchanged.
        "name": "oidc",
        "icon": "fa-openid",
        "token_key": "access_token",
        "remote_app": {
            "client_id": "airflow",
            "client_secret": os.environ["OIDC_CLIENT_SECRET"],
            "server_metadata_url": os.environ["OIDC_DISCOVERY_URL"],
            "client_kwargs": {
                "scope": "openid profile email",
                "code_challenge_method": "S256",
                "token_endpoint_auth_method": "client_secret_basic",
            },
        },
    },
]
