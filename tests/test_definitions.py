"""The Dagster code location loads and the lineage from the lake to dbt is wired."""

import dagster as dg

from cdp.definitions import defs


def test_definitions_load():
    repo = defs.get_repository_def()
    keys = {k.to_user_string() for k in repo.asset_graph.get_all_asset_keys()}
    assert {"statsbomb/events", "transfermarkt/games", "football_data/matches"} <= keys
    assert "stg_statsbomb__events" in keys


def test_dbt_sources_are_the_lake_assets():
    graph = defs.get_repository_def().asset_graph
    parents = graph.get(dg.AssetKey("stg_statsbomb__events")).parent_keys
    assert dg.AssetKey(["statsbomb", "events"]) in parents


def test_weekly_schedule():
    schedule = defs.get_schedule_def("refresh_all_schedule")
    assert schedule.cron_schedule == "0 6 * * 1"
