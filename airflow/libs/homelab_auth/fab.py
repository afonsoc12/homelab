"""OIDC browser login with explicitly scoped native machine authentication."""

from airflow.providers.fab.auth_manager.fab_auth_manager import FabAuthManager
from airflow.providers.fab.auth_manager.security_manager.override import FabAirflowSecurityManagerOverride
from homelab_auth.settings import issuer_url, service_users, subject_users


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
        # Use FAB's existing password, active-user and lockout handling. The
        # returned FAB user retains its assigned API permissions.
        return self.security_manager.auth_user_db(username, password, rotate_session_id=False)
