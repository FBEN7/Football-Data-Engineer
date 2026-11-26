FROM python:3.12-slim

WORKDIR /opt/cdp
COPY pyproject.toml README.md ./
COPY src ./src
COPY dbt ./dbt
# Editable install: the code finds dbt/ next to src/.
RUN pip install --no-cache-dir -e . \
 && cd dbt && dbt parse --profiles-dir . --quiet

ENV CDP_DATA_DIR=/data \
    DAGSTER_HOME=/opt/dagster_home
RUN mkdir -p /data "$DAGSTER_HOME"

EXPOSE 3000
CMD ["dagster", "dev", "-h", "0.0.0.0", "-p", "3000", "-m", "cdp.definitions"]
