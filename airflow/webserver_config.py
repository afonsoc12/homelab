"""FAB's required OAuth configuration; provider values come from deployment env.

Airflow's [fab] config_file loads these settings. FAB does not expose AUTH_TYPE
or OAUTH_PROVIDERS through airflow.cfg or AIRFLOW__FAB__ environment variables.
"""

import os

from airflow_oidc import ExistingAccountSecurityManager, issuer_url, service_users, subject_users
from flask_appbuilder.const import AUTH_OAUTH

ISSUER = issuer_url()
subject_users()
service_users()

AUTH_TYPE = AUTH_OAUTH
AUTH_USER_REGISTRATION = False
AUTH_ROLES_SYNC_AT_LOGIN = False
SECURITY_MANAGER_CLASS = ExistingAccountSecurityManager
SESSION_COOKIE_HTTPONLY = True

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
