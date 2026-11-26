"""Dagster definitions: the lake (Python ingestion) feeding the dbt project.

    dagster dev -m cdp.definitions        # UI on http://localhost:3000

Asset keys of the lake tables are [source, table], which is how dagster-dbt names dbt
sources: the lineage from the provider files to the marts is drawn automatically.
"""

import os

import dagster as dg
from dagster_dbt import DbtCliResource, DbtProject, dbt_assets

from cdp.config import DBT_DIR, LAKE_DIR, WAREHOUSE
from cdp.sources import football_data, statsbomb, transfermarkt

# dbt resolves the lake and the warehouse through these, whatever directory it runs from.
os.environ.setdefault("CDP_LAKE_DIR", str(LAKE_DIR))
os.environ.setdefault("CDP_WAREHOUSE", str(WAREHOUSE))

dbt_project = DbtProject(project_dir=DBT_DIR, profiles_dir=DBT_DIR)
dbt_project.prepare_if_dev()  # `dbt parse` when running under `dagster dev`


def _lake_specs(source: str, tables: list[str], description: str) -> list[dg.AssetSpec]:
    return [
        dg.AssetSpec([source, t], group_name="lake", kinds={"python", "parquet"},
                     description=f"{description} Table `{t}`, landed as received.")
        for t in tables
    ]


@dg.multi_asset(specs=_lake_specs("statsbomb", ["matches", "events", "lineups"],
                                  "StatsBomb Open Data for the season."))
def statsbomb_lake(context: dg.AssetExecutionContext):
    ids = statsbomb.fetch()
    context.log.info(f"{len(ids)} matches in cache")
    for table, rows in statsbomb.to_lake().items():
        if table in ("matches", "events", "lineups"):
            yield dg.MaterializeResult(asset_key=["statsbomb", table], metadata={"rows": rows})


@dg.multi_asset(specs=_lake_specs("transfermarkt", transfermarkt.TABLES,
                                  "Transfermarkt (Kaggle, CC0), every competition."))
def transfermarkt_lake():
    for table, rows in transfermarkt.to_lake().items():
        yield dg.MaterializeResult(asset_key=["transfermarkt", table], metadata={"rows": rows})


@dg.multi_asset(specs=_lake_specs("football_data", ["matches"],
                                  "football-data.co.uk season CSV."))
def football_data_lake():
    for table, rows in football_data.to_lake().items():
        yield dg.MaterializeResult(asset_key=["football_data", table], metadata={"rows": rows})


@dbt_assets(manifest=dbt_project.manifest_path)
def club_dbt_assets(context: dg.AssetExecutionContext, dbt: DbtCliResource):
    """Every enabled dbt model; its tests run as asset checks."""
    yield from dbt.cli(["build"], context=context).stream()


refresh_all = dg.define_asset_job("refresh_all", selection=dg.AssetSelection.all())

defs = dg.Definitions(
    assets=[statsbomb_lake, transfermarkt_lake, football_data_lake, club_dbt_assets],
    jobs=[refresh_all],
    schedules=[
        dg.ScheduleDefinition(job=refresh_all, cron_schedule="0 6 * * 1",
                              execution_timezone="Europe/Brussels"),
    ],
    resources={"dbt": DbtCliResource(project_dir=dbt_project)},
)
