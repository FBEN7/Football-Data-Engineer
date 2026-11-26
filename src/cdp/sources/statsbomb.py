"""StatsBomb Open Data: matches, events, lineups (and optionally 360 frames) of one season.

Landed in the lake as JSON payloads, one row per object, without flattening:
parsing is the job of the dbt staging models.
"""

from __future__ import annotations

import json
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import duckdb
import pandas as pd

from cdp.config import CACHE_DIR, LAKE_DIR, SEASON, Season
from cdp.sources.http import NotFound, download

BASE_URL = "https://raw.githubusercontent.com/statsbomb/open-data/master/data"
CACHE = CACHE_DIR / "statsbomb"
LAKE = LAKE_DIR / "statsbomb"


def _get(rel: str) -> Path:
    return download(f"{BASE_URL}/{rel}", CACHE / rel)


def _read(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def fetch(
    season: Season = SEASON, with_360: bool = False, max_matches: int | None = None
) -> list[int]:
    """Download the season into the cache. Returns the match ids."""
    matches = _read(_get(f"matches/{season.statsbomb_competition_id}/"
                         f"{season.statsbomb_season_id}.json"))
    ids = sorted(m["match_id"] for m in matches)[:max_matches]

    def one(match_id: int):
        _get(f"events/{match_id}.json")
        _get(f"lineups/{match_id}.json")
        if with_360:
            try:
                _get(f"three-sixty/{match_id}.json")
            except NotFound:
                pass

    with ThreadPoolExecutor(max_workers=8) as pool:
        list(pool.map(one, ids))
    return ids


def _write(df: pd.DataFrame, name: str) -> int:
    LAKE.mkdir(parents=True, exist_ok=True)
    out = LAKE / f"{name}.parquet"
    con = duckdb.connect()
    con.register("df", df)
    con.execute(f"COPY (SELECT * FROM df) TO '{out}' (FORMAT parquet)")
    con.close()
    return len(df)


def to_lake(season: Season = SEASON, max_matches: int | None = None) -> dict[str, int]:
    """Write matches / events / lineups (/ frames_360) Parquet files from the cache."""
    matches = _read(CACHE / f"matches/{season.statsbomb_competition_id}/"
                            f"{season.statsbomb_season_id}.json")
    matches = sorted(matches, key=lambda m: m["match_id"])[:max_matches]
    rows = {"matches": [], "events": [], "lineups": [], "frames_360": []}
    for m in matches:
        mid = m["match_id"]
        rows["matches"].append({"match_id": mid, "payload": json.dumps(m)})
        for e in _read(CACHE / f"events/{mid}.json"):
            rows["events"].append({"match_id": mid, "event_id": e["id"],
                                   "event_index": e["index"], "payload": json.dumps(e)})
        for team in _read(CACHE / f"lineups/{mid}.json"):
            rows["lineups"].append({"match_id": mid, "team_id": team["team_id"],
                                    "payload": json.dumps(team)})
        p360 = CACHE / f"three-sixty/{mid}.json"
        if p360.exists():
            for fr in _read(p360):
                rows["frames_360"].append({"match_id": mid, "event_id": fr["event_uuid"],
                                           "payload": json.dumps(fr)})
    return {name: _write(pd.DataFrame(r), name) for name, r in rows.items() if r}
