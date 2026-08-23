from __future__ import annotations

from datetime import datetime, timedelta

from airflow.providers.cncf.kubernetes.operators.pod import KubernetesPodOperator
from airflow.sdk import Param, TaskGroup, dag, get_current_context, task

from libs import kpo
from libs.t212 import db

_MODULE = "libs.t212.tasks"
_SINCE_MS = "{{ (data_interval_start.timestamp() * 1000) | int }}"


def _pod(dag_id: str, task_id: str, args: list[str], *, do_xcom_push: bool = False) -> KubernetesPodOperator:
    return KubernetesPodOperator(
        **kpo.default_kwargs(dag_id=dag_id, task_id=task_id),
        cmds=["python", "-m", _MODULE],
        arguments=args,
        do_xcom_push=do_xcom_push,
    )


def _pipeline_tasks(dag_id: str, account_id: str) -> None:
    real_id_task = _pod(
        dag_id,
        f"fetch_account_summary_{account_id}",
        ["fetch-account-summary", account_id],
        do_xcom_push=True,
    )
    real_id = real_id_task.output

    real_id_task >> [
        _pod(dag_id, f"fetch_positions_{account_id}", ["fetch-positions", account_id, real_id]),
        _pod(dag_id, f"fetch_orders_{account_id}", ["fetch-orders", account_id, real_id, _SINCE_MS]),
        _pod(dag_id, f"fetch_live_orders_{account_id}", ["fetch-live-orders", account_id, real_id]),
        _pod(dag_id, f"fetch_dividends_{account_id}", ["fetch-dividends", account_id, real_id, _SINCE_MS]),
        _pod(dag_id, f"fetch_transactions_{account_id}", ["fetch-transactions", account_id, real_id, _SINCE_MS]),
    ]


@dag(
    dag_id="t212_hourly",
    description="Trading 212 hourly pipeline — all accounts",
    schedule="@hourly",
    start_date=datetime(2020, 1, 1),
    catchup=False,
    tags=["t212", "finance"],
    default_args={"retries": 2, "retry_delay": timedelta(minutes=1)},
    params={
        "force_metadata_refresh": Param(False, type="boolean", description="Force instruments+exchanges refresh regardless of schedule")
    },
)
def t212_hourly():
    _DAG_ID = "t212_hourly"

    @task
    def init_schema() -> None:
        db.init_schema()

    @task.short_circuit
    def is_weekly_refresh() -> bool:
        ctx = get_current_context()
        if ctx["params"]["force_metadata_refresh"] is True:
            return True
        return ctx["data_interval_start"].weekday() == 0  # Monday only

    schema = init_schema()

    with TaskGroup(group_id="fetch_metadata") as tg_metadata:
        gate = is_weekly_refresh()
        gate >> [
            _pod(_DAG_ID, "fetch_exchanges", ["fetch-exchanges"]),
            _pod(_DAG_ID, "fetch_instruments", ["fetch-instruments"]),
        ]

    with TaskGroup(group_id="account_a") as tg_a:
        _pipeline_tasks(_DAG_ID, "a")

    with TaskGroup(group_id="account_m") as tg_m:
        _pipeline_tasks(_DAG_ID, "m")

    schema >> [tg_metadata, tg_a, tg_m]


t212_hourly()
