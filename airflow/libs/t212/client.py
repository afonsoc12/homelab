from __future__ import annotations

import logging
import time
from datetime import datetime, timedelta
from urllib.parse import parse_qs, urlparse

import requests
from airflow.sdk import Variable
from requests.auth import HTTPBasicAuth
from tenacity import (
    RetryCallState,
    retry,
    retry_if_exception_type,
    stop_after_attempt,
)

log = logging.getLogger(__name__)


class RateLimitError(Exception):
    """Raised on HTTP 429 — carries the unix timestamp when the limit resets."""

    def __init__(self, reset_at: float) -> None:
        self.reset_at = reset_at
        super().__init__(f"Rate limited until {reset_at}")


def _wait_for_rate_limit(retry_state: RetryCallState) -> float:
    exc = retry_state.outcome.exception()
    if isinstance(exc, RateLimitError):
        wait = max(
            timedelta(seconds=1),
            timedelta(seconds=exc.reset_at - time.time()) + timedelta(seconds=1),
        )
        log.warning("rate limited — waiting %s until reset", wait)
        return wait.total_seconds()
    return timedelta(seconds=1).total_seconds()


def _log_retry(retry_state: RetryCallState) -> None:
    log.warning("retry attempt=%d error=%s", retry_state.attempt_number, retry_state.outcome.exception())


_RETRY = retry(
    retry=retry_if_exception_type((RateLimitError, requests.ConnectionError, requests.Timeout)),
    wait=_wait_for_rate_limit,
    stop=stop_after_attempt(2),
    before_sleep=_log_retry,
    reraise=True,
)


class T212Client:
    _BASE_URL = "https://live.trading212.com"

    def __init__(self, account_id: str) -> None:
        api_key = Variable.get(f"t212_{account_id}_api_key")
        api_token = Variable.get(f"t212_{account_id}_api_token")
        log.info("account_id=%s api_key=%s", account_id, api_key)
        self._session = requests.Session()
        self._session.auth = HTTPBasicAuth(api_key, api_token)

    def account_summary(self) -> dict:
        log.info("GET /api/v0/equity/account/summary")
        result = self._get("/api/v0/equity/account/summary")
        log.info(
            "account_summary id=%s currency=%s totalValue=%s",
            result.get("id"),
            result.get("currency"),
            result.get("totalValue"),
        )
        return result

    def instruments(self) -> list[dict]:
        log.info("GET /api/v0/equity/metadata/instruments")
        data = self._get("/api/v0/equity/metadata/instruments")
        items = data if isinstance(data, list) else data.get("items", [])
        log.info("instruments count=%d", len(items))
        return items

    def exchanges(self) -> list[dict]:
        log.info("GET /api/v0/equity/metadata/exchanges")
        data = self._get("/api/v0/equity/metadata/exchanges")
        items = data if isinstance(data, list) else data.get("items", [])
        log.info("exchanges count=%d", len(items))
        return items

    def positions(self) -> list[dict]:
        log.info("GET /api/v0/equity/positions")
        data = self._get("/api/v0/equity/positions")
        items = data if isinstance(data, list) else data.get("items", [])
        log.info("positions count=%d", len(items))
        return items

    def live_orders(self) -> list[dict]:
        log.info("GET /api/v0/equity/orders")
        data = self._get("/api/v0/equity/orders")
        items = data if isinstance(data, list) else data.get("items", [])
        log.info("live_orders count=%d", len(items))
        return items

    def paginate(self, path: str, since_ms: int | None = None) -> list[dict]:
        """Paginate from newest, stopping when the oldest timestamp in a batch is before since_ms."""
        log.info("paginate path=%s since_ms=%s", path, since_ms)
        params: dict = {"limit": 50}
        all_items: list[dict] = []
        while True:
            log.debug("GET %s params=%s", path, params)
            data = self._get(path, params=params)
            items = data.get("items", [])
            all_items.extend(items)
            next_page = data.get("nextPagePath")
            log.debug(
                "paginate path=%s page_items=%d total=%d next_page=%s",
                path,
                len(items),
                len(all_items),
                next_page,
            )
            if not next_page or not items:
                break
            if since_ms is not None:
                max_ts = self._max_batch_ts_ms(items)
                if max_ts is not None and max_ts < since_ms:
                    log.info("paginate stopping — max batch ts %d < since %d", max_ts, since_ms)
                    break
            qs = parse_qs(urlparse(next_page).query)
            next_cursor = (qs.get("cursor") or [None])[0]
            if not next_cursor:
                break
            params["cursor"] = next_cursor
        log.info("paginate complete path=%s total=%d", path, len(all_items))
        return all_items

    @staticmethod
    def _max_batch_ts_ms(items: list[dict]) -> int | None:
        _TS_KEYS = ("createdAt", "dateTime", "paidOn", "date", "filledAt")
        max_ts: int | None = None
        for item in items:
            sources = [item, item.get("order") or {}, item.get("fill") or {}]
            for src in sources:
                for key in _TS_KEYS:
                    val = src.get(key)
                    if not val:
                        continue
                    try:
                        ms = int(datetime.fromisoformat(val.replace("Z", "+00:00")).timestamp() * 1000)
                        if max_ts is None or ms > max_ts:
                            max_ts = ms
                    except (ValueError, TypeError):
                        pass
        return max_ts

    @_RETRY
    def _get(self, path: str, **kwargs) -> dict:
        resp = self._session.get(f"{self._BASE_URL}{path}", timeout=30, **kwargs)
        self._check_rate_limit(resp)
        resp.raise_for_status()
        return resp.json()

    @staticmethod
    def _check_rate_limit(resp: requests.Response) -> None:
        remaining = resp.headers.get("x-ratelimit-remaining")
        limit = resp.headers.get("x-ratelimit-limit")
        if remaining is not None:
            log.debug("rate limit remaining=%s/%s", remaining, limit)
        if resp.status_code == 429:
            reset_at = float(resp.headers.get("x-ratelimit-reset", time.time() + 60))
            raise RateLimitError(reset_at=reset_at)
