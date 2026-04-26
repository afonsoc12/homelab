FROM apache/airflow:slim-3.2.1-python3.14

COPY --chown=airflow:root pyproject.toml uv.lock .
COPY --chown=airflow:root dags/ /opt/airflow/dags/

RUN pip install --no-cache-dir uv && \
    uv export --frozen --no-dev --no-emit-project --format requirements.txt --output-file requirements.txt && \
    uv pip sync --python /home/airflow/.local/bin/python requirements.txt && \
    rm requirements.txt

CMD ["airflow", "standalone"]
