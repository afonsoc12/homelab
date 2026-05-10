from __future__ import annotations

import json
import logging

from airflow.providers.postgres.hooks.postgres import PostgresHook

from .models import AccountSnapshot, Dividend, Exchange, HistoricalOrder, Instrument, Position, Transaction

log = logging.getLogger(__name__)

# Demote PostgresHook SQL echo to DEBUG
logging.getLogger("airflow.providers.common.sql.hooks.sql").setLevel(logging.DEBUG)

_SCHEMA_SQL = """
CREATE SCHEMA IF NOT EXISTS trading212;

CREATE TABLE IF NOT EXISTS trading212.account_snapshots (
    id                        BIGSERIAL   PRIMARY KEY,
    account_id                TEXT        NOT NULL,
    snapshot_at               TIMESTAMPTZ NOT NULL,
    currency                  TEXT,
    total_value               NUMERIC,
    cash_available            NUMERIC,
    cash_reserved_for_orders  NUMERIC,
    cash_in_pies              NUMERIC,
    investments_current_value NUMERIC,
    investments_total_cost    NUMERIC,
    unrealized_pnl            NUMERIC,
    realized_pnl              NUMERIC,
    raw_json                  JSONB       NOT NULL
);

CREATE TABLE IF NOT EXISTS trading212.positions (
    id                  BIGSERIAL   PRIMARY KEY,
    account_id          TEXT        NOT NULL,
    snapshot_at         TIMESTAMPTZ NOT NULL,
    ticker              TEXT        NOT NULL,
    instrument_name     TEXT,
    isin                TEXT,
    instrument_currency TEXT,
    quantity            NUMERIC,
    qty_available       NUMERIC,
    qty_in_pies         NUMERIC,
    current_price       NUMERIC,
    avg_price_paid      NUMERIC,
    position_created_at TIMESTAMPTZ,
    wallet_currency     TEXT,
    current_value       NUMERIC,
    total_cost          NUMERIC,
    unrealized_pnl      NUMERIC,
    fx_impact           NUMERIC,
    raw_json            JSONB       NOT NULL
);

CREATE TABLE IF NOT EXISTS trading212.orders (
    account_id          TEXT    NOT NULL,
    order_id            TEXT    NOT NULL,
    fill_id             BIGINT,
    ticker              TEXT,
    instrument_name     TEXT,
    isin                TEXT,
    instrument_currency TEXT,
    quantity            NUMERIC,
    filled_quantity     NUMERIC,
    value               NUMERIC,
    filled_value        NUMERIC,
    side                TEXT,
    type                TEXT,
    status              TEXT,
    limit_price         NUMERIC,
    stop_price          NUMERIC,
    time_in_force       TEXT,
    extended_hours      BOOLEAN,
    strategy            TEXT,
    currency            TEXT,
    created_at          TIMESTAMPTZ,
    initiated_from      TEXT,
    filled_at           TIMESTAMPTZ,
    fill_quantity       NUMERIC,
    fill_price          NUMERIC,
    fill_type           TEXT,
    trading_method      TEXT,
    fill_currency       TEXT,
    fill_net_value      NUMERIC,
    fill_realized_pnl   NUMERIC,
    fill_fx_rate        NUMERIC,
    taxes               JSONB,
    raw_json            JSONB   NOT NULL,
    is_live             BOOLEAN NOT NULL DEFAULT FALSE,
    extracted_at        TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT orders_account_order_fill_uniq UNIQUE NULLS NOT DISTINCT (account_id, order_id, fill_id)
);

CREATE TABLE IF NOT EXISTS trading212.dividends (
    account_id             TEXT    NOT NULL,
    dividend_id            TEXT    NOT NULL,
    ticker                 TEXT,
    instrument_name        TEXT,
    isin                   TEXT,
    ticker_currency        TEXT,
    quantity               NUMERIC,
    amount                 NUMERIC,
    amount_in_euro         NUMERIC,
    currency               TEXT,
    gross_amount_per_share NUMERIC,
    paid_on                TIMESTAMPTZ,
    dividend_type          TEXT,
    raw_json               JSONB   NOT NULL,
    extracted_at           TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (account_id, dividend_id)
);

CREATE TABLE IF NOT EXISTS trading212.transactions (
    account_id       TEXT        NOT NULL,
    reference        TEXT        NOT NULL,
    date_time        TIMESTAMPTZ,
    transaction_type TEXT,
    amount           NUMERIC,
    currency         TEXT,
    raw_json         JSONB       NOT NULL,
    extracted_at     TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (account_id, reference)
);

CREATE TABLE IF NOT EXISTS trading212.exchanges (
    exchange_id          INT         PRIMARY KEY,
    name                 TEXT,
    working_schedule_id  INT,
    working_schedules    JSONB,
    raw_json             JSONB       NOT NULL,
    extracted_at         TIMESTAMPTZ DEFAULT NOW(),
    updated_at           TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS trading212.instruments (
    ticker          TEXT        PRIMARY KEY,
    name            TEXT,
    isin            TEXT,
    currency        TEXT,
    exchange_id     INT,
    instrument_type TEXT,
    raw_json        JSONB       NOT NULL,
    extracted_at    TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS instruments_isin_idx ON trading212.instruments (isin);
CREATE INDEX IF NOT EXISTS instruments_exchange_idx ON trading212.instruments (exchange_id);
"""

_PG = "airflow_data"


def _hook() -> PostgresHook:
    return PostgresHook(postgres_conn_id=_PG)


def _j(data) -> str:
    return json.dumps(data)


def init_schema() -> None:
    log.info("initialising schema")
    _hook().run(_SCHEMA_SQL)
    log.info("schema ready")


def upsert_exchanges(exchanges: list[Exchange]) -> None:
    if not exchanges:
        log.info("no exchanges to upsert")
        return
    log.info("upserting %d exchanges", len(exchanges))
    rows = [
        (e.exchange_id, e.name, e.working_schedule_id, _j(e.working_schedules) if e.working_schedules is not None else None, _j(e.raw_json))
        for e in exchanges
    ]
    conn = _hook().get_conn()
    with conn.cursor() as cur:
        cur.executemany(
            """
            INSERT INTO trading212.exchanges (exchange_id, name, working_schedule_id, working_schedules, raw_json)
            VALUES (%s,%s,%s,%s,%s)
            ON CONFLICT (exchange_id) DO UPDATE SET
                name=EXCLUDED.name,
                working_schedule_id=EXCLUDED.working_schedule_id,
                working_schedules=EXCLUDED.working_schedules,
                raw_json=EXCLUDED.raw_json,
                updated_at=NOW()
            WHERE
                trading212.exchanges.name IS DISTINCT FROM EXCLUDED.name
                OR trading212.exchanges.working_schedule_id IS DISTINCT FROM EXCLUDED.working_schedule_id
            """,
            rows,
        )
    conn.commit()


def upsert_instruments(instruments: list[Instrument]) -> None:
    if not instruments:
        log.info("no instruments to upsert")
        return
    log.info("upserting %d instruments", len(instruments))
    rows = [(i.ticker, i.name, i.isin, i.currency, i.exchange_id, i.instrument_type, _j(i.raw_json)) for i in instruments]
    conn = _hook().get_conn()
    with conn.cursor() as cur:
        cur.executemany(
            """
            INSERT INTO trading212.instruments (ticker, name, isin, currency, exchange_id, instrument_type, raw_json)
            VALUES (%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (ticker) DO UPDATE SET
                name=EXCLUDED.name,
                isin=EXCLUDED.isin,
                currency=EXCLUDED.currency,
                exchange_id=EXCLUDED.exchange_id,
                instrument_type=EXCLUDED.instrument_type,
                raw_json=EXCLUDED.raw_json,
                updated_at=NOW()
            WHERE
                trading212.instruments.name IS DISTINCT FROM EXCLUDED.name
                OR trading212.instruments.isin IS DISTINCT FROM EXCLUDED.isin
                OR trading212.instruments.currency IS DISTINCT FROM EXCLUDED.currency
                OR trading212.instruments.exchange_id IS DISTINCT FROM EXCLUDED.exchange_id
                OR trading212.instruments.instrument_type IS DISTINCT FROM EXCLUDED.instrument_type
            """,
            rows,
        )
    conn.commit()


def insert_account_snapshot(snapshot: AccountSnapshot) -> None:
    log.info(
        "insert account_snapshot account=%s snapshot_at=%s total_value=%s",
        snapshot.account_id,
        snapshot.snapshot_at,
        snapshot.total_value,
    )
    _hook().run(
        """
        INSERT INTO trading212.account_snapshots (
            account_id, snapshot_at, currency, total_value,
            cash_available, cash_reserved_for_orders, cash_in_pies,
            investments_current_value, investments_total_cost,
            unrealized_pnl, realized_pnl, raw_json
        ) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
        """,
        parameters=(
            snapshot.account_id,
            snapshot.snapshot_at,
            snapshot.currency,
            snapshot.total_value,
            snapshot.cash_available,
            snapshot.cash_reserved_for_orders,
            snapshot.cash_in_pies,
            snapshot.investments_current_value,
            snapshot.investments_total_cost,
            snapshot.unrealized_pnl,
            snapshot.realized_pnl,
            _j(snapshot.raw_json),
        ),
    )


def insert_positions(positions: list[Position]) -> None:
    if not positions:
        log.info("no positions to insert")
        return
    log.info("inserting %d positions", len(positions))
    rows = [
        (
            p.account_id,
            p.snapshot_at,
            p.ticker,
            p.instrument_name,
            p.isin,
            p.instrument_currency,
            p.quantity,
            p.qty_available,
            p.qty_in_pies,
            p.current_price,
            p.avg_price_paid,
            p.position_created_at,
            p.wallet_currency,
            p.current_value,
            p.total_cost,
            p.unrealized_pnl,
            p.fx_impact,
            _j(p.raw_json),
        )
        for p in positions
    ]
    conn = _hook().get_conn()
    with conn.cursor() as cur:
        cur.executemany(
            """
            INSERT INTO trading212.positions (
                account_id, snapshot_at, ticker, instrument_name, isin, instrument_currency,
                quantity, qty_available, qty_in_pies, current_price, avg_price_paid,
                position_created_at, wallet_currency, current_value, total_cost,
                unrealized_pnl, fx_impact, raw_json
            ) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            """,
            rows,
        )
    conn.commit()


def upsert_orders(orders: list[HistoricalOrder]) -> None:
    if not orders:
        log.info("no orders to upsert")
        return
    log.info("upserting %d orders", len(orders))
    for o in orders:
        log.debug(
            "order order_id=%s ticker=%s status=%s is_live=%s filled_value=%s",
            o.order_id,
            o.ticker,
            o.status,
            o.is_live,
            o.filled_value,
        )
    rows = [
        (
            o.account_id,
            o.order_id,
            o.fill_id,
            o.ticker,
            o.instrument_name,
            o.isin,
            o.instrument_currency,
            o.quantity,
            o.filled_quantity,
            o.value,
            o.filled_value,
            o.side,
            o.order_type,
            o.status,
            o.limit_price,
            o.stop_price,
            o.time_in_force,
            o.extended_hours,
            o.strategy,
            o.currency,
            o.created_at,
            o.initiated_from,
            o.filled_at,
            o.fill_quantity,
            o.fill_price,
            o.fill_type,
            o.trading_method,
            o.fill_currency,
            o.fill_net_value,
            o.fill_realized_pnl,
            o.fill_fx_rate,
            _j(o.taxes),
            _j(o.raw_json),
            o.is_live,
        )
        for o in orders
    ]
    conn = _hook().get_conn()
    with conn.cursor() as cur:
        cur.executemany(
            """
            INSERT INTO trading212.orders (
                account_id, order_id, fill_id, ticker, instrument_name, isin, instrument_currency,
                quantity, filled_quantity, value, filled_value, side, type, status,
                limit_price, stop_price, time_in_force, extended_hours, strategy, currency,
                created_at, initiated_from, filled_at, fill_quantity, fill_price,
                fill_type, trading_method, fill_currency, fill_net_value,
                fill_realized_pnl, fill_fx_rate, taxes, raw_json, is_live
            ) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT ON CONSTRAINT orders_account_order_fill_uniq DO UPDATE SET
                status=EXCLUDED.status,
                filled_quantity=EXCLUDED.filled_quantity,
                filled_value=EXCLUDED.filled_value,
                filled_at=COALESCE(EXCLUDED.filled_at, trading212.orders.filled_at),
                fill_quantity=COALESCE(EXCLUDED.fill_quantity, trading212.orders.fill_quantity),
                fill_price=COALESCE(EXCLUDED.fill_price, trading212.orders.fill_price),
                fill_net_value=COALESCE(EXCLUDED.fill_net_value, trading212.orders.fill_net_value),
                fill_realized_pnl=COALESCE(EXCLUDED.fill_realized_pnl, trading212.orders.fill_realized_pnl),
                fill_fx_rate=COALESCE(EXCLUDED.fill_fx_rate, trading212.orders.fill_fx_rate),
                taxes=COALESCE(EXCLUDED.taxes, trading212.orders.taxes),
                is_live=EXCLUDED.is_live,
                raw_json=EXCLUDED.raw_json,
                updated_at=NOW()
            WHERE
                trading212.orders.status IS DISTINCT FROM EXCLUDED.status
                OR trading212.orders.filled_quantity IS DISTINCT FROM EXCLUDED.filled_quantity
                OR trading212.orders.is_live IS DISTINCT FROM EXCLUDED.is_live
            """,
            rows,
        )
    conn.commit()


def upsert_dividends(dividends: list[Dividend]) -> None:
    if not dividends:
        log.info("no dividends to upsert")
        return
    log.info("upserting %d dividends", len(dividends))
    for d in dividends:
        log.debug(
            "dividend dividend_id=%s ticker=%s amount=%s paid_on=%s",
            d.dividend_id,
            d.ticker,
            d.amount,
            d.paid_on,
        )
    rows = [
        (
            d.account_id,
            d.dividend_id,
            d.ticker,
            d.instrument_name,
            d.isin,
            d.ticker_currency,
            d.quantity,
            d.amount,
            d.amount_in_euro,
            d.currency,
            d.gross_amount_per_share,
            d.paid_on,
            d.dividend_type,
            _j(d.raw_json),
        )
        for d in dividends
    ]
    conn = _hook().get_conn()
    with conn.cursor() as cur:
        cur.executemany(
            """
            INSERT INTO trading212.dividends (
                account_id, dividend_id, ticker, instrument_name, isin, ticker_currency,
                quantity, amount, amount_in_euro, currency, gross_amount_per_share,
                paid_on, dividend_type, raw_json
            ) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (account_id, dividend_id) DO NOTHING
            """,
            rows,
        )
    conn.commit()


def upsert_transactions(transactions: list[Transaction]) -> None:
    if not transactions:
        log.info("no transactions to upsert")
        return
    log.info("upserting %d transactions", len(transactions))
    for t in transactions:
        log.debug(
            "transaction reference=%s type=%s amount=%s date_time=%s",
            t.reference,
            t.transaction_type,
            t.amount,
            t.date_time,
        )
    rows = [
        (
            t.account_id,
            t.reference,
            t.date_time,
            t.transaction_type,
            t.amount,
            t.currency,
            _j(t.raw_json),
        )
        for t in transactions
    ]
    conn = _hook().get_conn()
    with conn.cursor() as cur:
        cur.executemany(
            """
            INSERT INTO trading212.transactions
                (account_id, reference, date_time, transaction_type, amount, currency, raw_json)
            VALUES (%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (account_id, reference) DO NOTHING
            """,
            rows,
        )
    conn.commit()
