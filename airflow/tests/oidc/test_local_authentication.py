"""The shared image keeps local standalone runs free of login prompts."""

import os

import pytest
from airflow.api_fastapi.app import create_app
from airflow.configuration import conf
from fastapi.testclient import TestClient

pytestmark = pytest.mark.skipif(
    os.environ.get("AIRFLOW_AUTH_TEST_MODE") != "local",
    reason="Use tests/oidc/run.sh to initialize a disposable authentication database",
)


def test_local_default_allows_requests_without_login():
    assert conf.getboolean("core", "simple_auth_manager_all_admins")
    with TestClient(create_app()) as client:
        assert client.get("/api/v2/dags").status_code == 200
        assert client.post("/api/v2/variables", json={"key": "local-test", "value": "synthetic"}).status_code == 201
