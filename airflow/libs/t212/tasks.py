from __future__ import annotations

import argparse
import json
import logging
import os
from datetime import datetime, timezone
from pathlib import Path

from . import db
from .client import T212Client
from .models import AccountSnapshot, Dividend, Exchange, HistoricalOrder, Instrument, Position, Transaction

log = logging.getLogger(__name__)

_XCOM_PATH = Path("/airflow/xcom/return.json")


def _push_xcom(value: str) -> None:
    if not _XCOM_PATH.parent.is_dir():
        return
    _XCOM_PATH.write_text(json.dumps(value))


def init_schema() -> None:
    db.init_schema()


def fetch_account_summary(account_id: str) -> str:
    now = datetime.now(tz=timezone.utc)
    data = T212Client(account_id).account_summary()
    snapshot = AccountSnapshot.from_api(data, now)
    log.info("account=%s t212_id=%s total_value=%s", account_id, snapshot.account_id, snapshot.total_value)
    db.insert_account_snapshot(snapshot)
    _push_xcom(snapshot.account_id)
    return snapshot.account_id


def fetch_positions(account_id: str, real_account_id: str) -> None:
    now = datetime.now(tz=timezone.utc)
    items = T212Client(account_id).positions()
    positions = [Position.from_api(p, real_account_id, now) for p in items]
    log.info("account=%s positions=%d", real_account_id, len(positions))
    db.insert_positions(positions)


def fetch_orders(account_id: str, real_account_id: str, since_ms: int) -> None:
    items = T212Client(account_id).paginate("/api/v0/equity/history/orders", since_ms)
    orders = [HistoricalOrder.from_api(o, real_account_id) for o in items]
    log.info("account=%s orders=%d", real_account_id, len(orders))
    db.upsert_orders(orders)


def fetch_live_orders(account_id: str, real_account_id: str) -> None:
    items = T212Client(account_id).live_orders()
    orders = [HistoricalOrder.from_api(o, real_account_id, is_live=True) for o in items]
    log.info("account=%s live_orders=%d", real_account_id, len(orders))
    db.upsert_orders(orders)


def fetch_dividends(account_id: str, real_account_id: str, since_ms: int) -> None:
    items = T212Client(account_id).paginate("/api/v0/equity/history/dividends", since_ms)
    dividends = [Dividend.from_api(d, real_account_id) for d in items]
    log.info("account=%s dividends=%d", real_account_id, len(dividends))
    db.upsert_dividends(dividends)


def fetch_transactions(account_id: str, real_account_id: str, since_ms: int) -> None:
    items = T212Client(account_id).paginate("/api/v0/equity/history/transactions", since_ms)
    transactions = [Transaction.from_api(t, real_account_id) for t in items]
    log.info("account=%s transactions=%d", real_account_id, len(transactions))
    db.upsert_transactions(transactions)


def fetch_exchanges() -> None:
    items = T212Client("m").exchanges()
    exchanges = [Exchange.from_api(e) for e in items]
    log.info("exchanges=%d", len(exchanges))
    db.upsert_exchanges(exchanges)


def fetch_instruments() -> None:
    items = T212Client("m").instruments()
    instruments = [Instrument.from_api(i) for i in items]
    log.info("instruments=%d", len(instruments))
    db.upsert_instruments(instruments)


def _main() -> None:
    logging.basicConfig(level=os.environ.get("LOG_LEVEL", "INFO"))
    logging.getLogger("t212").setLevel(logging.DEBUG)

    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("init-schema")

    p = sub.add_parser("fetch-account-summary")
    p.add_argument("account_id")

    p = sub.add_parser("fetch-positions")
    p.add_argument("account_id")
    p.add_argument("real_account_id")

    p = sub.add_parser("fetch-orders")
    p.add_argument("account_id")
    p.add_argument("real_account_id")
    p.add_argument("since_ms", type=int)

    p = sub.add_parser("fetch-live-orders")
    p.add_argument("account_id")
    p.add_argument("real_account_id")

    p = sub.add_parser("fetch-dividends")
    p.add_argument("account_id")
    p.add_argument("real_account_id")
    p.add_argument("since_ms", type=int)

    p = sub.add_parser("fetch-transactions")
    p.add_argument("account_id")
    p.add_argument("real_account_id")
    p.add_argument("since_ms", type=int)

    sub.add_parser("fetch-exchanges")
    sub.add_parser("fetch-instruments")

    args = parser.parse_args()
    kwargs = vars(args)
    command = kwargs.pop("command")

    {
        "init-schema": init_schema,
        "fetch-account-summary": fetch_account_summary,
        "fetch-positions": fetch_positions,
        "fetch-orders": fetch_orders,
        "fetch-live-orders": fetch_live_orders,
        "fetch-dividends": fetch_dividends,
        "fetch-transactions": fetch_transactions,
        "fetch-exchanges": fetch_exchanges,
        "fetch-instruments": fetch_instruments,
    }[command](**kwargs)


if __name__ == "__main__":
    _main()
