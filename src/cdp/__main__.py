"""Command line, for when the Dagster UI is not needed.

    python -m cdp ingest                      # all sources into data/lake
    python -m cdp ingest --source statsbomb   # one source (repeatable)
    python -m cdp dbt build                   # any dbt command, run in dbt/ with the right paths
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys

from cdp.config import DBT_DIR, LAKE_DIR, WAREHOUSE

SOURCES = ("statsbomb", "football_data", "transfermarkt")


def ingest(sources: list[str]) -> None:
    from cdp.sources import football_data, statsbomb, transfermarkt

    for name in sources:
        if name == "statsbomb":
            statsbomb.fetch()
            counts = statsbomb.to_lake()
        elif name == "football_data":
            counts = football_data.to_lake()
        else:
            counts = transfermarkt.to_lake()
        print(f"{name}: {counts}", flush=True)


def dbt(args: list[str]) -> int:
    env = os.environ | {"CDP_LAKE_DIR": str(LAKE_DIR), "CDP_WAREHOUSE": str(WAREHOUSE)}
    return subprocess.call(["dbt", *args, "--profiles-dir", str(DBT_DIR)], cwd=DBT_DIR, env=env)


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    if argv[:1] == ["dbt"]:
        return dbt(argv[1:])
    ap = argparse.ArgumentParser(prog="cdp")
    sub = ap.add_subparsers(dest="cmd", required=True)
    i = sub.add_parser("ingest", help="download the sources and land them in data/lake")
    i.add_argument("--source", choices=SOURCES, action="append")
    sub.add_parser("dbt", help="run a dbt command: python -m cdp dbt build")
    args = ap.parse_args(argv)
    ingest(args.source or list(SOURCES))
    return 0


if __name__ == "__main__":
    sys.exit(main())
