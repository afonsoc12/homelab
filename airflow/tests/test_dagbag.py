from __future__ import annotations


def test_dags_load_without_import_errors(dagbag) -> None:
    assert dagbag.import_errors == {}
    assert "t212_hourly" in dagbag.dags
    assert "t212_daily" in dagbag.dags
