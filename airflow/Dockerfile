FROM apache/airflow:slim-3.2.1-python3.14

ENV PYTHONPATH=/opt/airflow/libs:$PYTHONPATH

COPY --chown=airflow:root pyproject.toml uv.lock .
COPY --chown=airflow:root . /opt/airflow

USER root
RUN mkdir -p /data && chown -R airflow:root /data

USER airflow
RUN pip install --no-cache-dir uv && \
    uv export --frozen --no-dev --no-emit-project --format requirements.txt --output-file requirements.txt && \
    uv pip sync --python /home/airflow/.local/bin/python requirements.txt && \
    rm requirements.txt

CMD ["airflow", "standalone"]
