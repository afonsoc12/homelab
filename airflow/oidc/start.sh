#!/usr/bin/env bash
set -euo pipefail

# Refuse to fall back to another auth manager when deployment values are absent.
python - <<'PYTHON'
import os
import runpy

from airflow.configuration import conf

if conf.get("core", "auth_manager") != "airflow_oidc.OIDCAuthManager":
    raise RuntimeError("The OIDC image requires its auth manager in deployment values")
for name in ("AIRFLOW__API__SECRET_KEY", "AIRFLOW__API_AUTH__JWT_SECRET"):
    if not os.environ.get(name):
        raise RuntimeError(f"The OIDC image requires {name} in deployment secrets")
runpy.run_path(conf.get("fab", "config_file"))
PYTHON

# Airflow standalone forces SimpleAuthManager even when another manager is set.
# Run the normal components explicitly so the selected FAB manager is honored.
airflow db migrate

children=()
shutdown() {
  trap - EXIT
  for child in "${children[@]}"; do
    kill -TERM "$child" 2>/dev/null || true
  done
  for child in "${children[@]}"; do
    wait "$child" 2>/dev/null || true
  done
}
trap shutdown EXIT
trap 'exit 143' TERM
trap 'exit 130' INT

airflow scheduler &
children+=("$!")
airflow dag-processor &
children+=("$!")
airflow triggerer &
children+=("$!")
airflow api-server --proxy-headers &
children+=("$!")

set +e
wait -n "${children[@]}"
result=$?
if [ "$result" -eq 0 ]; then
  result=1
fi
exit "$result"
