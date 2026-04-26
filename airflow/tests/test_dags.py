from __future__ import annotations

from pathlib import Path

from airflow.models import DagBag


def test_dags_load_without_import_errors() -> None:
    dag_folder = Path(__file__).resolve().parents[1] / "dags"
    dagbag = DagBag(dag_folder=str(dag_folder), include_examples=False)

    assert dagbag.import_errors == {}
    assert "homelab_hello" in dagbag.dags
