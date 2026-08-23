from __future__ import annotations

from datetime import datetime

from airflow.providers.cncf.kubernetes.operators.pod import KubernetesPodOperator
from airflow.sdk import dag

from libs import kpo

_DAG_ID = "example_kubernetes_pod"


@dag(
    dag_id=_DAG_ID,
    description="Sanity check: run a task in its own pod via KubernetesPodOperator",
    schedule=None,
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["example"],
)
def example_kubernetes_pod():
    # No `image=` override: this task pod runs the exact same image as the scheduler,
    # so it has the same libs/ and pinned deps — the pattern to follow when migrating
    # a task (e.g. t212) to its own pod.
    KubernetesPodOperator(
        **kpo.default_kwargs(dag_id=_DAG_ID, task_id="hello_from_pod"),
        cmds=["python", "-c"],
        arguments=["import libs; print('hello from a KubernetesPodOperator task pod, same deps as the scheduler')"],
    )


example_kubernetes_pod()
