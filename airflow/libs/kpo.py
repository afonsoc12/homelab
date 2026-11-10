from __future__ import annotations

import re

from airflow.providers.cncf.kubernetes.secret import Secret
from airflow.sdk import Variable
from kubernetes.client import models as k8s

# Names of the k8s resources the homelab-svc chart creates for the airflow release.
# Reusing them keeps KubernetesPodOperator task pods on the exact same DB connection,
# secret key and secrets-backend files as the scheduler — no separate copy to maintain.
_ENV_SECRET = "airflow"
_BACKEND_SECRET = "airflow-secrets-backend"
_BACKEND_MOUNT_PATH = "/var/run/secrets/airflow"
_NAMESPACE = "addons"

_NAME_SANITIZE_RE = re.compile(r"[^a-z0-9-]+")


def pod_name(dag_id: str, task_id: str) -> str:
    """Deterministic, RFC1123-safe pod name prefix: airflow-kpo-<dag_id>-<task_id>."""
    raw = f"airflow-kpo-{dag_id}-{task_id}"
    return _NAME_SANITIZE_RE.sub("-", raw.lower()).strip("-")[:63]


def default_kwargs(dag_id: str, task_id: str, *, with_backend_secrets: bool = True) -> dict:
    """Common KubernetesPodOperator kwargs so every task pod matches the running
    airflow image (same deps, same libs/) and — when needed — the same secrets.

    Usage:
        KubernetesPodOperator(
            **kpo.default_kwargs(dag_id="t212_hourly", task_id="sync_account"),
            cmds=["python", "-m", "libs.t212.some_job"],
        )
    """
    kwargs: dict = {
        "task_id": task_id,
        "name": pod_name(dag_id, task_id),
        "namespace": _NAMESPACE,
        # Falls back to a placeholder outside the cluster (local dev, CI dagbag import) —
        # in the addons namespace this is always set to the running airflow image.
        "image": Variable.get("kpo_image", default="kpo_image-unset"),
        "image_pull_policy": "Always",
        "in_cluster": True,
        "get_logs": True,
        "is_delete_operator_pod": True,
        "startup_timeout_seconds": 120,
        "container_resources": k8s.V1ResourceRequirements(
            requests={"cpu": "100m", "memory": "256Mi"},
            limits={"cpu": "1", "memory": "1Gi"},
        ),
        "env_vars": {"PYTHONPATH": "/opt/airflow/libs"},
        "secrets": [
            Secret("env", "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN", _ENV_SECRET, "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN"),
        ],
    }

    if with_backend_secrets:
        kwargs["volumes"] = [
            k8s.V1Volume(name="secrets", secret=k8s.V1SecretVolumeSource(secret_name=_BACKEND_SECRET)),
        ]
        kwargs["volume_mounts"] = [
            k8s.V1VolumeMount(name="secrets", mount_path=_BACKEND_MOUNT_PATH, read_only=True),
        ]

    return kwargs
