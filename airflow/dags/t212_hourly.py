from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone

from airflow.sdk import TaskGroup, dag, get_current_context, task

from libs.t212 import db
from libs.t212.client import T212Client
from libs.t212.models import AccountSnapshot, Dividend, HistoricalOrder, Position, Transaction

log = logging.getLogger(__name__)
logging.getLogger("t212").setLevel(logging.DEBUG)


def _since_ms() -> int:
    ctx = get_current_context()
    return int(ctx["data_interval_start"].timestamp() * 1000)


def _pipeline_tasks(account_id: str) -> None:

    @task
    def fetch_account_summary() -> str:
        now = datetime.now(tz=timezone.utc)
        data = T212Client(account_id).account_summary()
        snapshot = AccountSnapshot.from_api(data, now)
        log.info(
            "account=%s t212_id=%s total_value=%s",
            account_id,
            snapshot.account_id,
            snapshot.total_value,
        )
        db.insert_account_snapshot(snapshot)
        return snapshot.account_id

    @task
    def fetch_positions(real_account_id: str) -> None:
        now = datetime.now(tz=timezone.utc)
        items = T212Client(account_id).positions()
        positions = [Position.from_api(p, real_account_id, now) for p in items]
        log.info("account=%s positions=%d", real_account_id, len(positions))
        db.insert_positions(positions)

    @task
    def fetch_orders(real_account_id: str) -> None:
        items = T212Client(account_id).paginate("/api/v0/equity/history/orders", _since_ms())
        orders = [HistoricalOrder.from_api(o, real_account_id) for o in items]
        log.info("account=%s orders=%d", real_account_id, len(orders))
        db.upsert_orders(orders)

    @task
    def fetch_live_orders(real_account_id: str) -> None:
        items = T212Client(account_id).live_orders()
        orders = [HistoricalOrder.from_api(o, real_account_id, is_live=True) for o in items]
        log.info("account=%s live_orders=%d", real_account_id, len(orders))
        db.upsert_orders(orders)

    @task
    def fetch_dividends(real_account_id: str) -> None:
        items = T212Client(account_id).paginate("/api/v0/equity/history/dividends", _since_ms())
        dividends = [Dividend.from_api(d, real_account_id) for d in items]
        log.info("account=%s dividends=%d", real_account_id, len(dividends))
        db.upsert_dividends(dividends)

    @task
    def fetch_transactions(real_account_id: str) -> None:
        items = T212Client(account_id).paginate("/api/v0/equity/history/transactions", _since_ms())
        transactions = [Transaction.from_api(t, real_account_id) for t in items]
        log.info("account=%s transactions=%d", real_account_id, len(transactions))
        db.upsert_transactions(transactions)

    real_id = fetch_account_summary()
    real_id >> [
        fetch_positions(real_id),
        fetch_orders(real_id),
        fetch_live_orders(real_id),
        fetch_dividends(real_id),
        fetch_transactions(real_id),
    ]


@dag(
    dag_id="t212_hourly",
    description="Trading 212 hourly pipeline — all accounts",
    schedule="@hourly",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["t212", "finance"],
    default_args={"retries": 2, "retry_delay": timedelta(minutes=1)},
)
def t212_hourly():

    @task
    def init_schema() -> None:
        db.init_schema()

    schema = init_schema()

    with TaskGroup(group_id="account_a") as tg_a:
        _pipeline_tasks("a")

    with TaskGroup(group_id="account_m") as tg_m:
        _pipeline_tasks("m")

    schema >> [tg_a, tg_m]


t212_hourly()
