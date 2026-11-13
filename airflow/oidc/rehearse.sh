#!/usr/bin/env bash
set -euo pipefail

directory=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
AIRFLOW_HOME=$(mktemp -d)
export AIRFLOW_HOME
cp "$directory/../airflow.cfg" "$AIRFLOW_HOME/airflow.cfg"
export AIRFLOW__LOGGING__BASE_LOG_FOLDER="$AIRFLOW_HOME/logs"
printf '{}\n' > "$AIRFLOW_HOME/variables.yaml"
printf '{}\n' > "$AIRFLOW_HOME/connections.yaml"
export AIRFLOW__SECRETS__BACKEND_KWARGS="{\"variables_file_path\":\"$AIRFLOW_HOME/variables.yaml\",\"connections_file_path\":\"$AIRFLOW_HOME/connections.yaml\"}"
export AIRFLOW__CORE__FERNET_KEY="$(python -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())')"
trap 'rm -rf "$AIRFLOW_HOME"' EXIT
# Generate isolated signing keys for this disposable test environment.
export AIRFLOW__API__SECRET_KEY="$(python -c 'import secrets; print(secrets.token_urlsafe(32))')"
export AIRFLOW__API_AUTH__JWT_SECRET="$(python -c 'import secrets; print(secrets.token_urlsafe(32))')"
export PYTHONPATH="$directory/../libs:${PYTHONPATH:-}"
export AIRFLOW__DATABASE__SQL_ALCHEMY_CONN="sqlite:///$AIRFLOW_HOME/airflow.db"
export AIRFLOW__CORE__AUTH_MANAGER=airflow_oidc.OIDCAuthManager
export AIRFLOW__CORE__SIMPLE_AUTH_MANAGER_ALL_ADMINS=false
export AIRFLOW__CORE__LOAD_EXAMPLES=false
export AIRFLOW__FAB__CONFIG_FILE="$directory/../webserver_config.py"
export AIRFLOW_OIDC_ISSUER=https://synthetic-issuer/
export AIRFLOW_OIDC_CLIENT_ID=synthetic-client
export AIRFLOW_OIDC_CLIENT_SECRET=synthetic-value
export AIRFLOW_OIDC_SUBJECT_USERS='{"synthetic-subject":"rehearsal-viewer","synthetic-owner":"rehearsal-owner"}'
export AIRFLOW_API_SERVICE_USERS='["rehearsal-machine"]'

airflow db migrate
airflow users create --username rehearsal-viewer --firstname Rehearsal --lastname Viewer --role Viewer --email viewer@synthetic --password synthetic-value
airflow users create --username rehearsal-machine --firstname Rehearsal --lastname Machine --role Viewer --email machine@synthetic --password synthetic-value
airflow users create --username rehearsal-human --firstname Rehearsal --lastname Human --role Viewer --email machine-alias@synthetic --password synthetic-value
python "$directory/rehearse.py"
