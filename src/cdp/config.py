"""What the platform covers and where it keeps its files. Override paths with CDP_DATA_DIR."""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = Path(os.environ.get("CDP_DATA_DIR", ROOT / "data")).resolve()
CACHE_DIR = DATA_DIR / "cache"  # downloads, exactly as received
LAKE_DIR = DATA_DIR / "lake"  # raw layer: one Parquet file per source table, no transformation
WAREHOUSE = DATA_DIR / "warehouse.duckdb"  # built by dbt from the lake
DBT_DIR = ROOT / "dbt"


@dataclass(frozen=True)
class Season:
    """One club season, as each source identifies it."""

    label: str
    statsbomb_competition_id: int
    statsbomb_season_id: int
    football_data_league: str  # football-data.co.uk division code
    football_data_season: str  # e.g. "2324"
    transfermarkt_competition_id: str
    transfermarkt_season: int  # year the season starts
    focus_club: str  # as StatsBomb names it


SEASON = Season(
    label="Bayer Leverkusen 2023/24",
    statsbomb_competition_id=9,
    statsbomb_season_id=281,
    football_data_league="D1",
    football_data_season="2324",
    transfermarkt_competition_id="L1",
    transfermarkt_season=2023,
    focus_club="Bayer Leverkusen",
)
