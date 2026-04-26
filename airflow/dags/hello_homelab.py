from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.models import Variable
from airflow.providers.standard.operators.empty import EmptyOperator
from airflow.providers.standard.operators.python import PythonOperator


def print_vars() -> None:
    test_var = Variable.get("test_var", default_var="missing")
    test_secret = Variable.get("test_secret", default_var="missing")
    print(f"test_var = {test_var}")
    print(f"test_secret = {test_secret}")


with DAG(
    dag_id="homelab_hello",
    description="Minimal DAG baked into the Airflow image (prints test_var and test_secret)",
    schedule="@daily",
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=["homelab"],
):
    start = EmptyOperator(task_id="start")
    show_vars = PythonOperator(task_id="print_vars", python_callable=print_vars)

    start >> show_vars
