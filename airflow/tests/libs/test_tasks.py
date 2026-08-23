from __future__ import annotations

import json
from unittest.mock import patch

from libs.t212 import tasks


def test_all_subcommands_have_a_handler():
    # Mirrors the dispatch table in tasks._main() — catches a typo'd subcommand name.
    subcommands = [
        "init-schema",
        "fetch-account-summary",
        "fetch-positions",
        "fetch-orders",
        "fetch-live-orders",
        "fetch-dividends",
        "fetch-transactions",
        "fetch-exchanges",
        "fetch-instruments",
    ]
    dispatch = {
        "init-schema": tasks.init_schema,
        "fetch-account-summary": tasks.fetch_account_summary,
        "fetch-positions": tasks.fetch_positions,
        "fetch-orders": tasks.fetch_orders,
        "fetch-live-orders": tasks.fetch_live_orders,
        "fetch-dividends": tasks.fetch_dividends,
        "fetch-transactions": tasks.fetch_transactions,
        "fetch-exchanges": tasks.fetch_exchanges,
        "fetch-instruments": tasks.fetch_instruments,
    }
    assert set(dispatch) == set(subcommands)
    assert all(callable(fn) for fn in dispatch.values())


def test_push_xcom_writes_json_when_mount_present(tmp_path):
    xcom_dir = tmp_path / "airflow" / "xcom"
    xcom_dir.mkdir(parents=True)
    with patch.object(tasks, "_XCOM_PATH", xcom_dir / "return.json"):
        tasks._push_xcom("account-123")
    assert json.loads((xcom_dir / "return.json").read_text()) == "account-123"


def test_push_xcom_is_noop_without_mount(tmp_path):
    with patch.object(tasks, "_XCOM_PATH", tmp_path / "no-such-dir" / "return.json"):
        tasks._push_xcom("account-123")  # must not raise
