#!/usr/bin/env bash
set -euo pipefail

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
