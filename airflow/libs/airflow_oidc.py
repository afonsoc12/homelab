"""FAB hooks for existing OIDC accounts and allowlisted machine API access.

Provider settings belong in webserver_config.py and deployment environment
variables. These hooks enforce restrictions FAB configuration cannot express.
"""

import json
import os
from urllib.parse import urlsplit

from airflow.providers.fab.auth_manager.fab_auth_manager import FabAuthManager
from airflow.providers.fab.auth_manager.security_manager.override import FabAirflowSecurityManagerOverride


def issuer_url():
    issuer = os.environ["AIRFLOW_OIDC_ISSUER"]
    parsed = urlsplit(issuer)
    if parsed.scheme != "https" or not parsed.hostname or parsed.username or parsed.password or parsed.query or parsed.fragment:
        raise ValueError("AIRFLOW_OIDC_ISSUER must be an HTTPS issuer URL")
    return issuer


def subject_users():
    users = json.loads(os.environ.get("AIRFLOW_OIDC_SUBJECT_USERS", "{}"))
    if not isinstance(users, dict) or any(
        not isinstance(subject, str) or not subject or not isinstance(username, str) or not username for subject, username in users.items()
    ):
        raise ValueError("AIRFLOW_OIDC_SUBJECT_USERS must map subjects to existing usernames")
    if len(set(users.values())) != len(users):
        raise ValueError("Each OIDC subject must map to a distinct existing user")
    return users


def service_users():
    users = json.loads(os.environ.get("AIRFLOW_API_SERVICE_USERS", "[]"))
    if not isinstance(users, list) or any(not isinstance(username, str) or not username for username in users):
        raise ValueError("AIRFLOW_API_SERVICE_USERS must be a list of existing machine usernames")
    if set(users).intersection(subject_users().values()):
        raise ValueError("OIDC users cannot also use machine password authentication")
    return frozenset(users)


class ExistingAccountSecurityManager(FabAirflowSecurityManagerOverride):
    def get_oauth_user_info(self, provider, response):
        # Authlib verifies the signed ID token, audience, expiry and nonce before
        # this hook receives its claims. Never select a local user by email.
        claims = response.get("userinfo", {})
        if provider != "authentik" or claims.get("iss") != issuer_url():
            return {}
        username = subject_users().get(claims.get("sub"))
        return {"username": username} if username else {}


class OIDCAuthManager(FabAuthManager):
    def create_token(self, headers, body):
        username = body.get("username")
        password = body.get("password")
        if not isinstance(username, str) or not isinstance(password, str) or not username or not password.strip("\x00"):
            raise ValueError("Username and password must be provided")
        if username not in service_users():
            return None
        # Use FAB's existing password and active-user checks. The
        # returned FAB user retains its assigned API permissions.
        user = self.security_manager.auth_user_db(username, password, rotate_session_id=False)
        # FAB can fall back to finding a user by email. Only the explicitly
        # allowlisted username may receive a machine token.
        return user if user is not None and user.username == username else None
