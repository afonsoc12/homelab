"""FAB configuration for the dedicated OIDC image."""

import os

from flask_appbuilder.const import AUTH_OAUTH
from homelab_auth.fab import ExistingAccountSecurityManager
from homelab_auth.settings import issuer_url, service_users, subject_users

ISSUER = issuer_url()
subject_users()
service_users()

AUTH_TYPE = AUTH_OAUTH
AUTH_USER_REGISTRATION = False
AUTH_ROLES_SYNC_AT_LOGIN = False
SECURITY_MANAGER_CLASS = ExistingAccountSecurityManager
SESSION_COOKIE_SECURE = True
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = "Lax"

OAUTH_PROVIDERS = [
    {
        "name": "authentik",
        "token_key": "access_token",
        "remote_app": {
            "client_id": os.environ["AIRFLOW_OIDC_CLIENT_ID"],
            "client_secret": os.environ["AIRFLOW_OIDC_CLIENT_SECRET"],
            "server_metadata_url": ISSUER.rstrip("/") + "/.well-known/openid-configuration",
            "client_kwargs": {"scope": "openid", "code_challenge_method": "S256"},
        },
    },
]
