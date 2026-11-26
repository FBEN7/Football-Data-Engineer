"""Source adapters: configuration and the football-data landing (small, no credentials)."""

import duckdb

from cdp.config import LAKE_DIR, SEASON
from cdp.sources import football_data


def test_season_is_consistent():
    assert SEASON.football_data_season == "2324"
    assert SEASON.transfermarkt_season == 2023


def test_football_data_landing():
    counts = football_data.to_lake()
    assert counts == {"matches": 306}
    cols = duckdb.sql(f"DESCRIBE SELECT * FROM '{LAKE_DIR}/football_data/matches.parquet'").df()
    assert set(cols["column_type"]) == {"VARCHAR"}  # raw layer: text, typed in staging
