from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional


def _first_not_none(*values):
    """Return first value that is not None (0 and False are valid)."""
    for v in values:
        if v is not None:
            return v
    return None


@dataclass
class AccountSnapshot:
    account_id: str
    snapshot_at: datetime
    currency: Optional[str]
    total_value: Optional[float]
    cash_available: Optional[float]
    cash_reserved_for_orders: Optional[float]
    cash_in_pies: Optional[float]
    investments_current_value: Optional[float]
    investments_total_cost: Optional[float]
    unrealized_pnl: Optional[float]
    realized_pnl: Optional[float]
    raw_json: dict

    @classmethod
    def from_api(cls, data: dict, snapshot_at: datetime) -> "AccountSnapshot":
        cash = data.get("cash") or {}
        inv = data.get("investments") or {}
        return cls(
            account_id=str(data["id"]),
            snapshot_at=snapshot_at,
            currency=data.get("currency"),
            total_value=data.get("totalValue"),
            cash_available=cash.get("availableToTrade"),
            cash_reserved_for_orders=cash.get("reservedForOrders"),
            cash_in_pies=cash.get("inPies"),
            investments_current_value=inv.get("currentValue"),
            investments_total_cost=inv.get("totalCost"),
            unrealized_pnl=inv.get("unrealizedProfitLoss"),
            realized_pnl=inv.get("realizedProfitLoss"),
            raw_json=data,
        )


@dataclass
class Position:
    account_id: str
    snapshot_at: datetime
    ticker: str
    instrument_name: Optional[str]
    isin: Optional[str]
    instrument_currency: Optional[str]
    quantity: Optional[float]
    qty_available: Optional[float]
    qty_in_pies: Optional[float]
    current_price: Optional[float]
    avg_price_paid: Optional[float]
    position_created_at: Optional[str]
    wallet_currency: Optional[str]
    current_value: Optional[float]
    total_cost: Optional[float]
    unrealized_pnl: Optional[float]
    fx_impact: Optional[float]
    raw_json: dict

    @classmethod
    def from_api(cls, data: dict, account_id: str, snapshot_at: datetime) -> "Position":
        inst = data.get("instrument") or {}
        wi = data.get("walletImpact") or {}
        ticker = inst.get("ticker") or data.get("ticker", "")
        return cls(
            account_id=account_id,
            snapshot_at=snapshot_at,
            ticker=ticker,
            instrument_name=inst.get("name"),
            isin=inst.get("isin"),
            instrument_currency=inst.get("currency"),
            quantity=data.get("quantity"),
            qty_available=data.get("quantityAvailableForTrading"),
            qty_in_pies=data.get("quantityInPies"),
            current_price=data.get("currentPrice"),
            avg_price_paid=_first_not_none(data.get("averagePricePaid"), data.get("averagePrice")),
            position_created_at=data.get("createdAt"),
            wallet_currency=wi.get("currency"),
            current_value=wi.get("currentValue"),
            total_cost=wi.get("totalCost"),
            unrealized_pnl=_first_not_none(wi.get("unrealizedProfitLoss"), data.get("ppl")),
            fx_impact=wi.get("fxImpact"),
            raw_json=data,
        )


@dataclass
class HistoricalOrder:
    account_id: str
    order_id: str
    ticker: Optional[str]
    instrument_name: Optional[str]
    isin: Optional[str]
    instrument_currency: Optional[str]
    quantity: Optional[float]
    filled_quantity: Optional[float]
    value: Optional[float]
    filled_value: Optional[float]
    side: Optional[str]
    order_type: Optional[str]
    status: Optional[str]
    limit_price: Optional[float]
    stop_price: Optional[float]
    time_in_force: Optional[str]
    extended_hours: Optional[bool]
    strategy: Optional[str]
    currency: Optional[str]
    created_at: Optional[str]
    initiated_from: Optional[str]
    fill_id: Optional[int]
    filled_at: Optional[str]
    fill_quantity: Optional[float]
    fill_price: Optional[float]
    fill_type: Optional[str]
    trading_method: Optional[str]
    fill_currency: Optional[str]
    fill_net_value: Optional[float]
    fill_realized_pnl: Optional[float]
    fill_fx_rate: Optional[float]
    taxes: list[dict] = field(default_factory=list)
    raw_json: dict = field(default_factory=dict)
    is_live: bool = False

    @classmethod
    def from_api(cls, data: dict, account_id: str, is_live: bool = False) -> "HistoricalOrder":
        if "order" in data:
            o = data["order"]
            f = data.get("fill") or {}
        else:
            o = data
            f = {}
        inst = o.get("instrument") or {}
        wi = f.get("walletImpact") or {}
        return cls(
            account_id=account_id,
            order_id=str(o.get("id")),
            ticker=_first_not_none(o.get("ticker"), inst.get("ticker")),
            instrument_name=inst.get("name"),
            isin=inst.get("isin"),
            instrument_currency=inst.get("currency"),
            quantity=o.get("quantity"),
            filled_quantity=o.get("filledQuantity"),
            value=o.get("value"),
            filled_value=o.get("filledValue"),
            side=o.get("side"),
            order_type=o.get("type"),
            status=o.get("status"),
            limit_price=o.get("limitPrice"),
            stop_price=o.get("stopPrice"),
            time_in_force=o.get("timeInForce"),
            extended_hours=o.get("extendedHours"),
            strategy=o.get("strategy"),
            currency=o.get("currency"),
            created_at=_first_not_none(o.get("createdAt"), o.get("dateCreated"), o.get("date")),
            initiated_from=o.get("initiatedFrom"),
            fill_id=f.get("id"),
            filled_at=f.get("filledAt"),
            fill_quantity=f.get("quantity"),
            fill_price=_first_not_none(f.get("price"), o.get("fillPrice")),
            fill_type=f.get("type"),
            trading_method=f.get("tradingMethod"),
            fill_currency=wi.get("currency"),
            fill_net_value=wi.get("netValue"),
            fill_realized_pnl=wi.get("realisedProfitLoss"),
            fill_fx_rate=wi.get("fxRate"),
            taxes=wi.get("taxes") or [],
            raw_json=data,
            is_live=is_live,
        )


@dataclass
class Dividend:
    account_id: str
    dividend_id: str
    ticker: Optional[str]
    instrument_name: Optional[str]
    isin: Optional[str]
    ticker_currency: Optional[str]
    quantity: Optional[float]
    amount: Optional[float]
    amount_in_euro: Optional[float]
    currency: Optional[str]
    gross_amount_per_share: Optional[float]
    paid_on: Optional[str]
    dividend_type: Optional[str]
    raw_json: dict

    @classmethod
    def from_api(cls, data: dict, account_id: str) -> "Dividend":
        inst = data.get("instrument") or {}
        return cls(
            account_id=account_id,
            dividend_id=str(_first_not_none(data.get("reference"), data.get("id"))),
            ticker=_first_not_none(data.get("ticker"), inst.get("ticker")),
            instrument_name=inst.get("name"),
            isin=inst.get("isin"),
            ticker_currency=_first_not_none(data.get("tickerCurrency"), inst.get("currency")),
            quantity=data.get("quantity"),
            amount=_first_not_none(data.get("amount"), data.get("grossAmount")),
            amount_in_euro=data.get("amountInEuro"),
            currency=data.get("currency"),
            gross_amount_per_share=data.get("grossAmountPerShare"),
            paid_on=_first_not_none(data.get("paidOn"), data.get("date")),
            dividend_type=data.get("type"),
            raw_json=data,
        )


@dataclass
class Transaction:
    account_id: str
    reference: str
    date_time: Optional[str]
    transaction_type: Optional[str]
    amount: Optional[float]
    currency: Optional[str]
    raw_json: dict

    @classmethod
    def from_api(cls, data: dict, account_id: str) -> "Transaction":
        return cls(
            account_id=account_id,
            reference=str(_first_not_none(data.get("reference"), data.get("id"))),
            date_time=_first_not_none(data.get("dateTime"), data.get("date")),
            transaction_type=data.get("type"),
            amount=data.get("amount"),
            currency=data.get("currency"),
            raw_json=data,
        )
