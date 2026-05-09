from __future__ import annotations

from datetime import timedelta


class TestT212HourlyDag:
    def test_dag_loaded(self, dagbag):
        assert "t212_hourly" in dagbag.dags
        assert dagbag.import_errors == {}

    def test_schedule(self, dagbag):
        dag = dagbag.dags["t212_hourly"]
        assert str(dag.schedule) == "@hourly"

    def test_tags(self, dagbag):
        dag = dagbag.dags["t212_hourly"]
        assert "t212" in dag.tags
        assert "finance" in dag.tags

    def test_no_catchup(self, dagbag):
        dag = dagbag.dags["t212_hourly"]
        assert dag.catchup is False

    def test_retries(self, dagbag):
        dag = dagbag.dags["t212_hourly"]
        assert dag.default_args["retries"] == 2
        assert dag.default_args["retry_delay"] == timedelta(minutes=1)

    def test_expected_task_ids(self, dagbag):
        dag = dagbag.dags["t212_hourly"]
        task_ids = set(dag.task_ids)
        assert "init_schema" in task_ids
        assert "account_a.fetch_account_summary" in task_ids
        assert "account_a.fetch_positions" in task_ids
        assert "account_a.fetch_orders" in task_ids
        assert "account_a.fetch_live_orders" in task_ids
        assert "account_a.fetch_dividends" in task_ids
        assert "account_a.fetch_transactions" in task_ids

    def test_init_schema_upstream_of_account_group(self, dagbag):
        dag = dagbag.dags["t212_hourly"]
        fetch_summary = dag.get_task("account_a.fetch_account_summary")
        upstream_ids = {t.task_id for t in fetch_summary.upstream_list}
        assert "init_schema" in upstream_ids

    def test_fetch_summary_upstream_of_all_fetchers(self, dagbag):
        dag = dagbag.dags["t212_hourly"]
        dependent_tasks = [
            "account_a.fetch_positions",
            "account_a.fetch_orders",
            "account_a.fetch_live_orders",
            "account_a.fetch_dividends",
            "account_a.fetch_transactions",
        ]
        for task_id in dependent_tasks:
            upstream_ids = {t.task_id for t in dag.get_task(task_id).upstream_list}
            assert "account_a.fetch_account_summary" in upstream_ids, f"{task_id} missing upstream"
