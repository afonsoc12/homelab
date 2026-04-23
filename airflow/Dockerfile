FROM apache/airflow:slim-3.2.1-python3.14

COPY --chown=airflow:root pyproject.toml uv.lock .
COPY --chown=airflow:root dags/ /opt/airflow/dags/

RUN pip install --no-cache-dir uv && \
    uv sync --system --no-dev --no-install-project

CMD ["airflow", "standalone"]
