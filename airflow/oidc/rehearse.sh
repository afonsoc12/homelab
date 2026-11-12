#!/usr/bin/env bash
set -euo pipefail

directory=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
AIRFLOW_HOME=$(mktemp -d)
export AIRFLOW_HOME
trap 'rm -rf "$AIRFLOW_HOME"' EXIT
export PYTHONPATH="$directory/../libs:${PYTHONPATH:-}"
export AIRFLOW__DATABASE__SQL_ALCHEMY_CONN="sqlite:///$AIRFLOW_HOME/airflow.db"
export AIRFLOW__CORE__AUTH_MANAGER=homelab_auth.fab.OIDCAuthManager
export AIRFLOW__CORE__SIMPLE_AUTH_MANAGER_ALL_ADMINS=false
export AIRFLOW__CORE__LOAD_EXAMPLES=false
export AIRFLOW__FAB__CONFIG_FILE="$directory/../libs/homelab_auth/webserver_config.py"
export AIRFLOW_OIDC_ISSUER=https://synthetic-issuer/
export AIRFLOW_OIDC_CLIENT_ID=synthetic-client
export AIRFLOW_OIDC_CLIENT_SECRET=synthetic-value
export AIRFLOW_OIDC_SUBJECT_USERS='{"synthetic-subject":"rehearsal-viewer","synthetic-owner":"rehearsal-owner"}'
export AIRFLOW_API_SERVICE_USERS='["rehearsal-machine"]'

airflow db migrate
airflow users create --username rehearsal-viewer --firstname Rehearsal --lastname Viewer --role Viewer --email viewer@synthetic --password synthetic-value
airflow users create --username rehearsal-machine --firstname Rehearsal --lastname Machine --role Viewer --email machine@synthetic --password synthetic-value
python "$directory/rehearse.py"
