"""football-data.co.uk: one CSV per league and season (results, match stats, referee, odds).

Landed as text columns: dates are dd/mm/yyyy and team names are the site's own short
names, so typing and naming belong to the staging model.
"""

from __future__ import annotations

import duckdb

from cdp.config import CACHE_DIR, LAKE_DIR, SEASON, Season
from cdp.sources.http import download

CACHE = CACHE_DIR / "football_data"
LAKE = LAKE_DIR / "football_data"


def fetch(season: Season = SEASON):
    url = (f"https://www.football-data.co.uk/mmz4281/{season.football_data_season}/"
           f"{season.football_data_league}.csv")
    return download(url, CACHE / f"{season.football_data_league}_{season.football_data_season}.csv")


def to_lake(season: Season = SEASON) -> dict[str, int]:
    src = fetch(season)
    LAKE.mkdir(parents=True, exist_ok=True)
    out = LAKE / "matches.parquet"
    con = duckdb.connect()
    con.execute(f"""
        COPY (
            SELECT *, '{season.football_data_league}' AS _league,
                   '{season.football_data_season}' AS _season
            FROM read_csv('{src}', all_varchar = true, header = true)
        ) TO '{out}' (FORMAT parquet)""")
    n = con.execute(f"SELECT count(*) FROM '{out}'").fetchone()[0]
    con.close()
    return {"matches": n}
