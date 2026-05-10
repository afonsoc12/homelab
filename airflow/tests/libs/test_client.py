from __future__ import annotations

import time
from datetime import datetime, timezone
from unittest.mock import MagicMock, patch

import pytest
import requests

from libs.t212.client import RateLimitError, T212Client


def _make_client(api_key="key", api_token="token"):
    with patch("libs.t212.client.Variable") as mock_var:
        mock_var.get.side_effect = lambda name: api_key if "key" in name else api_token
        return T212Client("a")


def _resp(json_data, status=200, headers=None):
    r = MagicMock(spec=requests.Response)
    r.status_code = status
    r.json.return_value = json_data
    r.headers = headers or {}
    r.raise_for_status = MagicMock()
    return r


class TestMaxBatchTsMs:
    def test_picks_up_created_at(self):
        items = [{"createdAt": "2026-01-15T10:00:00Z"}]
        ts = T212Client._max_batch_ts_ms(items)
        expected = int(datetime(2026, 1, 15, 10, 0, 0, tzinfo=timezone.utc).timestamp() * 1000)
        assert ts == expected

    def test_returns_max_across_items(self):
        items = [
            {"createdAt": "2026-01-15T10:00:00Z"},
            {"createdAt": "2026-01-15T12:00:00Z"},
            {"createdAt": "2026-01-15T11:00:00Z"},
        ]
        ts = T212Client._max_batch_ts_ms(items)
        expected = int(datetime(2026, 1, 15, 12, 0, 0, tzinfo=timezone.utc).timestamp() * 1000)
        assert ts == expected

    def test_checks_nested_order_and_fill(self):
        items = [{"order": {"createdAt": "2026-01-15T09:00:00Z"}, "fill": {"filledAt": "2026-01-15T09:01:00Z"}}]
        ts = T212Client._max_batch_ts_ms(items)
        expected = int(datetime(2026, 1, 15, 9, 1, 0, tzinfo=timezone.utc).timestamp() * 1000)
        assert ts == expected

    def test_falls_back_to_date_time(self):
        items = [{"dateTime": "2026-01-14T08:00:00Z"}]
        ts = T212Client._max_batch_ts_ms(items)
        assert ts is not None

    def test_empty_list_returns_none(self):
        assert T212Client._max_batch_ts_ms([]) is None

    def test_no_timestamp_keys_returns_none(self):
        assert T212Client._max_batch_ts_ms([{"foo": "bar"}]) is None

    def test_invalid_timestamp_skipped(self):
        items = [{"createdAt": "not-a-date"}]
        assert T212Client._max_batch_ts_ms(items) is None


class TestRateLimitHandling:
    def test_429_raises_rate_limit_error(self):
        client = _make_client()
        reset_at = time.time() + 1
        resp = _resp({}, status=429, headers={"x-ratelimit-reset": str(reset_at)})
        resp.raise_for_status = MagicMock()
        client._session.get = MagicMock(return_value=resp)
        with pytest.raises(RateLimitError) as exc_info:
            client._get("/some/path")
        assert exc_info.value.reset_at == reset_at

    def test_rate_limit_error_carries_reset_ts(self):
        err = RateLimitError(reset_at=1234567890.0)
        assert err.reset_at == 1234567890.0
        assert "1234567890" in str(err)


class TestPaginate:
    def test_single_page_no_next(self):
        client = _make_client()
        client._session.get = MagicMock(return_value=_resp({"items": [{"createdAt": "2026-01-15T10:00:00Z"}]}))
        result = client.paginate("/api/v0/equity/history/orders")
        assert len(result) == 1

    def test_multi_page_collects_all(self):
        client = _make_client()
        page1 = _resp({"items": [{"createdAt": "2026-01-15T12:00:00Z"}], "nextPagePath": "/path?cursor=abc"})
        page2 = _resp({"items": [{"createdAt": "2026-01-15T11:00:00Z"}]})
        client._session.get = MagicMock(side_effect=[page1, page2])
        result = client.paginate("/api/v0/equity/history/orders")
        assert len(result) == 2

    def test_stops_when_batch_older_than_since_ms(self):
        client = _make_client()
        since = int(datetime(2026, 1, 15, 11, 0, 0, tzinfo=timezone.utc).timestamp() * 1000)
        page1 = _resp({"items": [{"createdAt": "2026-01-15T12:00:00Z"}], "nextPagePath": "/path?cursor=abc"})
        page2 = _resp({"items": [{"createdAt": "2026-01-15T09:00:00Z"}], "nextPagePath": "/path?cursor=def"})
        client._session.get = MagicMock(side_effect=[page1, page2])
        result = client.paginate("/api/v0/equity/history/orders", since_ms=since)
        assert len(result) == 2
        assert client._session.get.call_count == 2

    def test_stops_on_missing_cursor(self):
        client = _make_client()
        page1 = _resp({"items": [{"createdAt": "2026-01-15T12:00:00Z"}], "nextPagePath": "/path"})
        client._session.get = MagicMock(return_value=page1)
        result = client.paginate("/api/v0/equity/history/orders")
        assert len(result) == 1
        assert client._session.get.call_count == 1

    def test_stops_on_empty_items(self):
        client = _make_client()
        page = _resp({"items": [], "nextPagePath": "/path?cursor=abc"})
        client._session.get = MagicMock(return_value=page)
        result = client.paginate("/api/v0/equity/history/orders")
        assert result == []

    def test_list_response_handled(self):
        client = _make_client()
        client._session.get = MagicMock(return_value=_resp([{"createdAt": "2026-01-15T10:00:00Z"}]))
        result = client.positions()
        assert len(result) == 1


class TestClientMethods:
    def test_account_summary_returns_json(self):
        client = _make_client()
        payload = {"id": 123, "currency": "GBP", "totalValue": 5000.0}
        client._session.get = MagicMock(return_value=_resp(payload))
        result = client.account_summary()
        assert result == payload

    def test_live_orders_unwraps_items(self):
        client = _make_client()
        payload = {"items": [{"id": "o1"}, {"id": "o2"}]}
        client._session.get = MagicMock(return_value=_resp(payload))
        result = client.live_orders()
        assert result == [{"id": "o1"}, {"id": "o2"}]
