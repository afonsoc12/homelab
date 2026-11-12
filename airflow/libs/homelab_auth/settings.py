"""Validate the explicitly configured browser and machine identities."""

import json
import os
from urllib.parse import urlsplit


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
