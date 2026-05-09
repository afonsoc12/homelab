from __future__ import annotations

import os
from datetime import datetime, timezone
from pathlib import Path
from unittest.mock import patch

import pytest
from airflow.models import DagBag

os.environ.setdefault("AIRFLOW__DATABASE__SQL_ALCHEMY_CONN", "sqlite:////tmp/airflow-test.db")
os.environ.setdefault("AIRFLOW__CORE__LOAD_EXAMPLES", "False")


@pytest.fixture(scope="session")
def dagbag():
    dag_folder = Path(__file__).resolve().parent.parent / "dags"
    with patch("libs.t212.client.Variable") as mock_var:
        mock_var.get.return_value = "test-value"
        bag = DagBag(dag_folder=str(dag_folder), include_examples=False)
    return bag


@pytest.fixture
def utcnow():
    return datetime(2026, 1, 15, 12, 0, 0, tzinfo=timezone.utc)
