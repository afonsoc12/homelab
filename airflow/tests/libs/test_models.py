from __future__ import annotations

from datetime import datetime, timezone

from libs.t212.models import (
    AccountSnapshot,
    Dividend,
    HistoricalOrder,
    Position,
    Transaction,
    _first_not_none,
)

NOW = datetime(2026, 1, 15, 12, 0, 0, tzinfo=timezone.utc)


class TestFirstNotNone:
    def test_returns_first_non_none(self):
        assert _first_not_none(None, None, "found") == "found"

    def test_zero_is_valid(self):
        assert _first_not_none(None, 0) == 0

    def test_false_is_valid(self):
        assert _first_not_none(None, False) is False

    def test_all_none_returns_none(self):
        assert _first_not_none(None, None) is None

    def test_first_wins(self):
        assert _first_not_none("first", "second") == "first"


class TestAccountSnapshot:
    def _api_data(self, **overrides):
        data = {
            "id": 123456,
            "currency": "GBP",
            "totalValue": 10000.0,
            "cash": {
                "availableToTrade": 500.0,
                "reservedForOrders": 100.0,
                "inPies": 200.0,
            },
            "investments": {
                "currentValue": 9200.0,
                "totalCost": 8000.0,
                "unrealizedProfitLoss": 1200.0,
                "realizedProfitLoss": 300.0,
            },
        }
        data.update(overrides)
        return data

    def test_from_api_full(self):
        snap = AccountSnapshot.from_api(self._api_data(), NOW)
        assert snap.account_id == "123456"
        assert snap.snapshot_at == NOW
        assert snap.currency == "GBP"
        assert snap.total_value == 10000.0
        assert snap.cash_available == 500.0
        assert snap.cash_reserved_for_orders == 100.0
        assert snap.cash_in_pies == 200.0
        assert snap.investments_current_value == 9200.0
        assert snap.investments_total_cost == 8000.0
        assert snap.unrealized_pnl == 1200.0
        assert snap.realized_pnl == 300.0

    def test_from_api_missing_cash(self):
        data = self._api_data()
        del data["cash"]
        snap = AccountSnapshot.from_api(data, NOW)
        assert snap.cash_available is None
        assert snap.cash_reserved_for_orders is None

    def test_from_api_missing_investments(self):
        data = self._api_data()
        del data["investments"]
        snap = AccountSnapshot.from_api(data, NOW)
        assert snap.investments_current_value is None
        assert snap.unrealized_pnl is None

    def test_raw_json_preserved(self):
        data = self._api_data()
        snap = AccountSnapshot.from_api(data, NOW)
        assert snap.raw_json is data


class TestPosition:
    def _api_data(self, **overrides):
        data = {
            "instrument": {"ticker": "AAPL", "name": "Apple Inc", "isin": "US0378331005", "currency": "USD"},
            "quantity": 10.0,
            "quantityAvailableForTrading": 10.0,
            "quantityInPies": 0.0,
            "currentPrice": 150.0,
            "averagePricePaid": 120.0,
            "createdAt": "2025-01-01T00:00:00Z",
            "walletImpact": {
                "currency": "GBP",
                "currentValue": 1200.0,
                "totalCost": 960.0,
                "unrealizedProfitLoss": 240.0,
                "fxImpact": -10.0,
            },
        }
        data.update(overrides)
        return data

    def test_from_api_full(self):
        pos = Position.from_api(self._api_data(), "acc1", NOW)
        assert pos.account_id == "acc1"
        assert pos.ticker == "AAPL"
        assert pos.instrument_name == "Apple Inc"
        assert pos.isin == "US0378331005"
        assert pos.instrument_currency == "USD"
        assert pos.quantity == 10.0
        assert pos.avg_price_paid == 120.0
        assert pos.wallet_currency == "GBP"
        assert pos.unrealized_pnl == 240.0
        assert pos.fx_impact == -10.0

    def test_from_api_falls_back_to_average_price(self):
        data = self._api_data()
        del data["averagePricePaid"]
        data["averagePrice"] = 115.0
        pos = Position.from_api(data, "acc1", NOW)
        assert pos.avg_price_paid == 115.0

    def test_from_api_falls_back_to_ppl_for_pnl(self):
        data = self._api_data()
        data["walletImpact"] = {}
        data["ppl"] = 99.0
        pos = Position.from_api(data, "acc1", NOW)
        assert pos.unrealized_pnl == 99.0

    def test_from_api_ticker_fallback(self):
        data = self._api_data()
        data["instrument"] = {}
        data["ticker"] = "MSFT"
        pos = Position.from_api(data, "acc1", NOW)
        assert pos.ticker == "MSFT"

    def test_from_api_missing_wallet_impact(self):
        data = self._api_data()
        del data["walletImpact"]
        pos = Position.from_api(data, "acc1", NOW)
        assert pos.current_value is None
        assert pos.wallet_currency is None


class TestHistoricalOrder:
    def _flat_data(self, **overrides):
        data = {
            "id": "ord-001",
            "ticker": "TSLA",
            "quantity": 5.0,
            "filledQuantity": 5.0,
            "value": 1000.0,
            "filledValue": 995.0,
            "side": "BUY",
            "type": "MARKET",
            "status": "FILLED",
            "currency": "GBP",
            "createdAt": "2026-01-10T09:00:00Z",
            "extendedHours": False,
        }
        data.update(overrides)
        return data

    def _nested_data(self, **overrides):
        data = {
            "order": {
                "id": "ord-002",
                "ticker": "AAPL",
                "quantity": 3.0,
                "filledQuantity": 3.0,
                "filledValue": 450.0,
                "side": "SELL",
                "type": "LIMIT",
                "status": "FILLED",
                "currency": "GBP",
                "dateCreated": "2026-01-12T10:00:00Z",
            },
            "fill": {
                "id": 9001,
                "filledAt": "2026-01-12T10:01:00Z",
                "quantity": 3.0,
                "price": 150.0,
                "type": "MARKET",
                "tradingMethod": "REGULAR",
                "walletImpact": {
                    "currency": "GBP",
                    "netValue": 449.0,
                    "realisedProfitLoss": 10.0,
                    "fxRate": 1.25,
                    "taxes": [{"name": "stamp_duty", "amount": 1.0}],
                },
            },
        }
        data.update(overrides)
        return data

    def test_from_api_flat(self):
        order = HistoricalOrder.from_api(self._flat_data(), "acc1")
        assert order.order_id == "ord-001"
        assert order.ticker == "TSLA"
        assert order.status == "FILLED"
        assert order.fill_id is None
        assert order.is_live is False

    def test_from_api_nested_with_fill(self):
        order = HistoricalOrder.from_api(self._nested_data(), "acc1")
        assert order.order_id == "ord-002"
        assert order.fill_id == 9001
        assert order.fill_price == 150.0
        assert order.fill_net_value == 449.0
        assert order.fill_realized_pnl == 10.0
        assert order.fill_fx_rate == 1.25
        assert order.taxes == [{"name": "stamp_duty", "amount": 1.0}]

    def test_from_api_is_live(self):
        order = HistoricalOrder.from_api(self._flat_data(), "acc1", is_live=True)
        assert order.is_live is True

    def test_from_api_created_at_fallback_chain(self):
        data = self._flat_data()
        del data["createdAt"]
        data["dateCreated"] = "2026-01-10T08:00:00Z"
        order = HistoricalOrder.from_api(data, "acc1")
        assert order.created_at == "2026-01-10T08:00:00Z"

        data2 = self._flat_data()
        del data2["createdAt"]
        data2["date"] = "2026-01-10T07:00:00Z"
        order2 = HistoricalOrder.from_api(data2, "acc1")
        assert order2.created_at == "2026-01-10T07:00:00Z"

    def test_from_api_ticker_from_instrument(self):
        data = self._flat_data()
        del data["ticker"]
        data["instrument"] = {"ticker": "GOOG"}
        order = HistoricalOrder.from_api(data, "acc1")
        assert order.ticker == "GOOG"

    def test_from_api_empty_fill(self):
        data = {"order": self._flat_data()}
        order = HistoricalOrder.from_api(data, "acc1")
        assert order.fill_id is None
        assert order.taxes == []


class TestDividend:
    def _api_data(self, **overrides):
        data = {
            "reference": "div-abc123",
            "ticker": "MSFT",
            "quantity": 5.0,
            "amount": 3.75,
            "amountInEuro": 4.10,
            "currency": "USD",
            "grossAmountPerShare": 0.75,
            "paidOn": "2026-01-10T00:00:00Z",
            "type": "ORDINARY",
            "instrument": {"name": "Microsoft Corp", "isin": "US5949181045", "currency": "USD"},
        }
        data.update(overrides)
        return data

    def test_from_api_full(self):
        div = Dividend.from_api(self._api_data(), "acc1")
        assert div.dividend_id == "div-abc123"
        assert div.ticker == "MSFT"
        assert div.amount == 3.75
        assert div.amount_in_euro == 4.10
        assert div.gross_amount_per_share == 0.75
        assert div.paid_on == "2026-01-10T00:00:00Z"
        assert div.dividend_type == "ORDINARY"
        assert div.instrument_name == "Microsoft Corp"

    def test_from_api_id_fallback(self):
        data = self._api_data()
        del data["reference"]
        data["id"] = "div-fallback"
        div = Dividend.from_api(data, "acc1")
        assert div.dividend_id == "div-fallback"

    def test_from_api_amount_fallback(self):
        data = self._api_data()
        del data["amount"]
        data["grossAmount"] = 3.50
        div = Dividend.from_api(data, "acc1")
        assert div.amount == 3.50

    def test_from_api_paid_on_fallback(self):
        data = self._api_data()
        del data["paidOn"]
        data["date"] = "2026-01-09T00:00:00Z"
        div = Dividend.from_api(data, "acc1")
        assert div.paid_on == "2026-01-09T00:00:00Z"

    def test_from_api_ticker_currency_from_instrument(self):
        data = self._api_data()
        del data["ticker"]
        div = Dividend.from_api(data, "acc1")
        assert div.ticker is None
        assert div.ticker_currency == "USD"


class TestTransaction:
    def _api_data(self, **overrides):
        data = {
            "reference": "txn-xyz",
            "dateTime": "2026-01-14T09:30:00Z",
            "type": "DEPOSIT",
            "amount": 500.0,
            "currency": "GBP",
        }
        data.update(overrides)
        return data

    def test_from_api_full(self):
        txn = Transaction.from_api(self._api_data(), "acc1")
        assert txn.reference == "txn-xyz"
        assert txn.date_time == "2026-01-14T09:30:00Z"
        assert txn.transaction_type == "DEPOSIT"
        assert txn.amount == 500.0
        assert txn.currency == "GBP"
        assert txn.account_id == "acc1"

    def test_from_api_id_fallback(self):
        data = self._api_data()
        del data["reference"]
        data["id"] = "txn-fallback"
        txn = Transaction.from_api(data, "acc1")
        assert txn.reference == "txn-fallback"

    def test_from_api_date_fallback(self):
        data = self._api_data()
        del data["dateTime"]
        data["date"] = "2026-01-14"
        txn = Transaction.from_api(data, "acc1")
        assert txn.date_time == "2026-01-14"

    def test_from_api_raw_json_preserved(self):
        data = self._api_data()
        txn = Transaction.from_api(data, "acc1")
        assert txn.raw_json is data
