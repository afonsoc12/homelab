#!/usr/bin/env bash
set -euo pipefail

directory=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
AIRFLOW_HOME=$(mktemp -d)
export AIRFLOW_HOME
cp "$directory/../../airflow.cfg" "$AIRFLOW_HOME/airflow.cfg"
cp "$directory/../../webserver_config.py" "$AIRFLOW_HOME/webserver_config.py"
export AIRFLOW__LOGGING__BASE_LOG_FOLDER="$AIRFLOW_HOME/logs"
printf '{}\n' > "$AIRFLOW_HOME/variables.yaml"
printf '{}\n' > "$AIRFLOW_HOME/connections.yaml"
export AIRFLOW__SECRETS__BACKEND_KWARGS="{\"variables_file_path\":\"$AIRFLOW_HOME/variables.yaml\",\"connections_file_path\":\"$AIRFLOW_HOME/connections.yaml\"}"
export AIRFLOW__CORE__FERNET_KEY="$(python -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())')"
trap 'rm -rf "$AIRFLOW_HOME"' EXIT
# Generate isolated signing keys for this disposable test environment.
export AIRFLOW__API__SECRET_KEY="$(python -c 'import secrets; print(secrets.token_urlsafe(32))')"
export AIRFLOW__API_AUTH__JWT_SECRET="$(python -c 'import secrets; print(secrets.token_urlsafe(32))')"
export PYTHONPATH="$directory/../../libs:${PYTHONPATH:-}"
export AIRFLOW__DATABASE__SQL_ALCHEMY_CONN="sqlite:///$AIRFLOW_HOME/airflow.db"
# Verify the shared image's default local configuration without OIDC settings.
export AIRFLOW__CORE__AUTH_MANAGER=airflow.api_fastapi.auth.managers.simple.simple_auth_manager.SimpleAuthManager
unset AIRFLOW__CORE__SIMPLE_AUTH_MANAGER_ALL_ADMINS
export AIRFLOW__CORE__LOAD_EXAMPLES=false
export AIRFLOW_AUTH_TEST_MODE=local
airflow db migrate
python -m pytest --confcutdir "$directory" "$directory/test_local_authentication.py" -q

# The deployment selects OIDC through environment variables in its values file.
export AIRFLOW__CORE__AUTH_MANAGER=airflow.providers.fab.auth_manager.fab_auth_manager.FabAuthManager
export AIRFLOW__CORE__SIMPLE_AUTH_MANAGER_ALL_ADMINS=false
export AIRFLOW__CORE__LOAD_EXAMPLES=false
unset AIRFLOW__FAB__CONFIG_FILE AIRFLOW__FAB__PROXY_FIX_X_PROTO
export AIRFLOW__FAB__ENABLE_PROXY_FIX=true
export AIRFLOW__FAB__PROXY_FIX_X_FOR=0
export AIRFLOW__FAB__PROXY_FIX_X_HOST=0
export AIRFLOW__FAB__PROXY_FIX_X_PORT=0
export AIRFLOW__FAB__PROXY_FIX_X_PREFIX=0
export AIRFLOW_OIDC_ISSUER=https://synthetic-issuer/
export AIRFLOW_OIDC_CLIENT_ID=synthetic-client
export AIRFLOW_OIDC_CLIENT_SECRET=synthetic-value

airflow db migrate
airflow users create --username rehearsal-viewer --firstname Rehearsal --lastname Viewer --role Viewer --email viewer@synthetic --password synthetic-value
airflow users create --username rehearsal-owner --firstname Rehearsal --lastname Owner --role Admin --email owner@synthetic --password synthetic-value
export AIRFLOW_AUTH_TEST_MODE=oidc
python -m pytest --confcutdir "$directory" "$directory/test_authentication.py" -q
