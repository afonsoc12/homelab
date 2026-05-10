from __future__ import annotations

from datetime import datetime, timezone
from unittest.mock import MagicMock, patch

from libs.t212.models import AccountSnapshot, Dividend, HistoricalOrder, Position, Transaction

NOW = datetime(2026, 1, 15, 12, 0, 0, tzinfo=timezone.utc)


def _patch_hook():
    return patch("libs.t212.db.PostgresHook")


def _snapshot():
    return AccountSnapshot(
        account_id="acc1",
        snapshot_at=NOW,
        currency="GBP",
        total_value=10000.0,
        cash_available=500.0,
        cash_reserved_for_orders=100.0,
        cash_in_pies=200.0,
        investments_current_value=9200.0,
        investments_total_cost=8000.0,
        unrealized_pnl=1200.0,
        realized_pnl=300.0,
        raw_json={"id": "acc1"},
    )


def _position():
    return Position(
        account_id="acc1",
        snapshot_at=NOW,
        ticker="AAPL",
        instrument_name="Apple",
        isin="US0378331005",
        instrument_currency="USD",
        quantity=10.0,
        qty_available=10.0,
        qty_in_pies=0.0,
        current_price=150.0,
        avg_price_paid=120.0,
        position_created_at="2025-01-01T00:00:00Z",
        wallet_currency="GBP",
        current_value=1200.0,
        total_cost=960.0,
        unrealized_pnl=240.0,
        fx_impact=-10.0,
        raw_json={},
    )


def _order(order_id="ord-001", status="FILLED", filled_quantity=5.0, is_live=False):
    return HistoricalOrder(
        account_id="acc1",
        order_id=order_id,
        ticker="TSLA",
        instrument_name=None,
        isin=None,
        instrument_currency=None,
        quantity=5.0,
        filled_quantity=filled_quantity,
        value=1000.0,
        filled_value=995.0,
        side="BUY",
        order_type="MARKET",
        status=status,
        limit_price=None,
        stop_price=None,
        time_in_force=None,
        extended_hours=False,
        strategy=None,
        currency="GBP",
        created_at="2026-01-10T09:00:00Z",
        initiated_from=None,
        fill_id=None,
        filled_at=None,
        fill_quantity=None,
        fill_price=None,
        fill_type=None,
        trading_method=None,
        fill_currency=None,
        fill_net_value=None,
        fill_realized_pnl=None,
        fill_fx_rate=None,
        taxes=[],
        raw_json={},
        is_live=is_live,
    )


def _dividend():
    return Dividend(
        account_id="acc1",
        dividend_id="div-001",
        ticker="MSFT",
        instrument_name="Microsoft",
        isin="US5949181045",
        ticker_currency="USD",
        quantity=5.0,
        amount=3.75,
        amount_in_euro=4.10,
        currency="USD",
        gross_amount_per_share=0.75,
        paid_on="2026-01-10T00:00:00Z",
        dividend_type="ORDINARY",
        raw_json={},
    )


def _transaction():
    return Transaction(
        account_id="acc1",
        reference="txn-001",
        date_time="2026-01-14T09:30:00Z",
        transaction_type="DEPOSIT",
        amount=500.0,
        currency="GBP",
        raw_json={},
    )


class TestInitSchema:
    def test_runs_schema_sql(self):
        with _patch_hook() as mock_cls:
            mock_hook = MagicMock()
            mock_cls.return_value = mock_hook
            from libs.t212 import db

            db.init_schema()
            mock_hook.run.assert_called_once()
            sql = mock_hook.run.call_args[0][0]
            assert "CREATE SCHEMA IF NOT EXISTS trading212" in sql
            assert "CREATE TABLE IF NOT EXISTS trading212.orders" in sql


class TestInsertAccountSnapshot:
    def test_inserts_all_fields(self):
        with _patch_hook() as mock_cls:
            mock_hook = MagicMock()
            mock_cls.return_value = mock_hook
            from libs.t212 import db

            db.insert_account_snapshot(_snapshot())
            mock_hook.run.assert_called_once()
            params = mock_hook.run.call_args.kwargs["parameters"]
            assert params[0] == "acc1"
            assert params[1] == NOW
            assert params[2] == "GBP"
            assert params[3] == 10000.0


class TestInsertPositions:
    def test_empty_list_skips_insert(self):
        with _patch_hook() as mock_cls:
            mock_hook = MagicMock()
            mock_cls.return_value = mock_hook
            from libs.t212 import db

            db.insert_positions([])
            mock_hook.get_conn.assert_not_called()

    def test_inserts_all_positions(self):
        with _patch_hook() as mock_cls:
            mock_conn = MagicMock()
            mock_cur = MagicMock()
            mock_conn.cursor.return_value.__enter__ = MagicMock(return_value=mock_cur)
            mock_conn.cursor.return_value.__exit__ = MagicMock(return_value=False)
            mock_cls.return_value.get_conn.return_value = mock_conn
            from libs.t212 import db

            db.insert_positions([_position(), _position()])
            mock_cur.executemany.assert_called_once()
            rows = mock_cur.executemany.call_args[0][1]
            assert len(rows) == 2
            assert rows[0][2] == "AAPL"


class TestUpsertOrders:
    def test_empty_list_skips_upsert(self):
        with _patch_hook() as mock_cls:
            mock_hook = MagicMock()
            mock_cls.return_value = mock_hook
            from libs.t212 import db

            db.upsert_orders([])
            mock_hook.get_conn.assert_not_called()

    def test_upserts_with_correct_field_count(self):
        with _patch_hook() as mock_cls:
            mock_conn = MagicMock()
            mock_cur = MagicMock()
            mock_conn.cursor.return_value.__enter__ = MagicMock(return_value=mock_cur)
            mock_conn.cursor.return_value.__exit__ = MagicMock(return_value=False)
            mock_cls.return_value.get_conn.return_value = mock_conn
            from libs.t212 import db

            db.upsert_orders([_order()])
            sql, rows = mock_cur.executemany.call_args[0]
            assert "ON CONFLICT ON CONSTRAINT orders_account_order_fill_uniq DO UPDATE SET" in sql
            assert len(rows[0]) == 34

    def test_conflict_update_guarded_by_where_clause(self):
        with _patch_hook() as mock_cls:
            mock_conn = MagicMock()
            mock_cur = MagicMock()
            mock_conn.cursor.return_value.__enter__ = MagicMock(return_value=mock_cur)
            mock_conn.cursor.return_value.__exit__ = MagicMock(return_value=False)
            mock_cls.return_value.get_conn.return_value = mock_conn
            from libs.t212 import db

            db.upsert_orders([_order()])
            sql = mock_cur.executemany.call_args[0][0]
            assert "WHERE" in sql
            assert "IS DISTINCT FROM" in sql

    def test_updated_at_set_on_conflict(self):
        with _patch_hook() as mock_cls:
            mock_conn = MagicMock()
            mock_cur = MagicMock()
            mock_conn.cursor.return_value.__enter__ = MagicMock(return_value=mock_cur)
            mock_conn.cursor.return_value.__exit__ = MagicMock(return_value=False)
            mock_cls.return_value.get_conn.return_value = mock_conn
            from libs.t212 import db

            db.upsert_orders([_order()])
            sql = mock_cur.executemany.call_args[0][0]
            assert "updated_at=NOW()" in sql


class TestUpsertDividends:
    def test_empty_list_skips(self):
        with _patch_hook() as mock_cls:
            mock_hook = MagicMock()
            mock_cls.return_value = mock_hook
            from libs.t212 import db

            db.upsert_dividends([])
            mock_hook.get_conn.assert_not_called()

    def test_uses_do_nothing_on_conflict(self):
        with _patch_hook() as mock_cls:
            mock_conn = MagicMock()
            mock_cur = MagicMock()
            mock_conn.cursor.return_value.__enter__ = MagicMock(return_value=mock_cur)
            mock_conn.cursor.return_value.__exit__ = MagicMock(return_value=False)
            mock_cls.return_value.get_conn.return_value = mock_conn
            from libs.t212 import db

            db.upsert_dividends([_dividend()])
            sql = mock_cur.executemany.call_args[0][0]
            assert "DO NOTHING" in sql


class TestUpsertTransactions:
    def test_empty_list_skips(self):
        with _patch_hook() as mock_cls:
            mock_hook = MagicMock()
            mock_cls.return_value = mock_hook
            from libs.t212 import db

            db.upsert_transactions([])
            mock_hook.get_conn.assert_not_called()

    def test_uses_do_nothing_on_conflict(self):
        with _patch_hook() as mock_cls:
            mock_conn = MagicMock()
            mock_cur = MagicMock()
            mock_conn.cursor.return_value.__enter__ = MagicMock(return_value=mock_cur)
            mock_conn.cursor.return_value.__exit__ = MagicMock(return_value=False)
            mock_cls.return_value.get_conn.return_value = mock_conn
            from libs.t212 import db

            db.upsert_transactions([_transaction()])
            sql = mock_cur.executemany.call_args[0][0]
            assert "DO NOTHING" in sql
