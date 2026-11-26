"""Transfermarkt, via the public-domain Kaggle dataset "davidcariboo/player-scores".

Needs a Kaggle API token: KAGGLE_API_TOKEN (bearer), or KAGGLE_USERNAME + KAGGLE_KEY, or
~/.kaggle/kaggle.json. The CSV files are landed whole (every competition and season):
filtering to the season is done in dbt, so the raw layer stays a faithful copy.
"""

from __future__ import annotations

import json
import os
import zipfile
from pathlib import Path

import duckdb

from cdp.config import CACHE_DIR, LAKE_DIR
from cdp.sources.http import download

DATASET = "davidcariboo/player-scores"
CACHE = CACHE_DIR / "transfermarkt"
LAKE = LAKE_DIR / "transfermarkt"
TABLES = ["competitions", "clubs", "players", "games", "appearances", "game_events",
          "game_lineups", "player_valuations"]


def _auth():
    if token := os.environ.get("KAGGLE_API_TOKEN"):
        return None, {"Authorization": f"Bearer {token}"}
    user, key = os.environ.get("KAGGLE_USERNAME"), os.environ.get("KAGGLE_KEY")
    cfg = Path.home() / ".kaggle" / "kaggle.json"
    if not (user and key) and cfg.exists():
        creds = json.loads(cfg.read_text())
        user, key = creds["username"], creds["key"]
    if not (user and key):
        raise RuntimeError("Kaggle credentials not found: set KAGGLE_API_TOKEN, or "
                           "KAGGLE_USERNAME and KAGGLE_KEY, or create ~/.kaggle/kaggle.json")
    return (user, key), None


def fetch() -> Path:
    dest = CACHE / "player-scores.zip"
    if dest.exists():  # delete it to pick up the dataset's weekly update
        return dest
    auth, headers = _auth()
    url = f"https://www.kaggle.com/api/v1/datasets/download/{DATASET}"
    return download(url, dest, auth=auth, headers=headers)


def to_lake() -> dict[str, int]:
    archive = fetch()
    extracted = CACHE / "csv"
    with zipfile.ZipFile(archive) as zf:
        for t in TABLES:
            if not (extracted / f"{t}.csv").exists():
                zf.extract(f"{t}.csv", extracted)
    LAKE.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect()
    counts = {}
    for t in TABLES:
        out = LAKE / f"{t}.parquet"
        con.execute(f"COPY (SELECT * FROM read_csv_auto('{extracted / f'{t}.csv'}', "
                    f"sample_size = -1)) TO '{out}' (FORMAT parquet)")
        counts[t] = con.execute(f"SELECT count(*) FROM '{out}'").fetchone()[0]
    con.close()
    return counts
