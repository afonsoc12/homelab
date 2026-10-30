#!/usr/bin/env bash
set -euo pipefail

# Standalone forces SimpleAuthManager. Keep the configured auth manager instead.
airflow db migrate
if [[ "${AIRFLOW__CORE__AUTH_MANAGER:-}" == "airflow.providers.fab.auth_manager.fab_auth_manager.FabAuthManager" ]]; then
  airflow fab-db migrate
fi

pids=()
stop() {
  trap - EXIT TERM INT
  if ((${#pids[@]})); then
    kill -TERM "${pids[@]}" 2>/dev/null || true
    wait || true
  fi
}
trap stop EXIT
trap 'exit 143' TERM
trap 'exit 130' INT

for component in api-server scheduler dag-processor triggerer; do
  args=("$component")
  if [[ "$component" == api-server ]]; then
    args+=(--proxy-headers)
  fi
  airflow "${args[@]}" &
  pids+=("$!")
done

wait -n "${pids[@]}"
exit 1
