# Club Data Platform

A football club's data platform in miniature. It takes three providers with three sets of
identifiers, consolidates them into one tested warehouse, and orchestrates it end to end.

**Season:** Bayer Leverkusen 2023/24, the unbeaten Bundesliga title.

```
 StatsBomb Open Data ─┐                 ┌─ staging ─┐   ┌─ crosswalks ─┐   ┌─ marts ───────────┐
 Transfermarkt (CC0) ─┼─► lake (Parquet)┼─ (typed)  ├──►│ teams        ├──►│ dim_team/player/  │
 football-data.co.uk ─┘   raw, as sent  └───────────┘   │ matches      │   │ match, fct_*      │
                                                        │ players      │   └─► rpt_reconciliation
        Python ingestion            dbt + DuckDB        └──────────────┘
        └─────────────────────── orchestrated by Dagster (weekly), tested in CI ──────────────┘
```

| Layer | Tools | What it does |
|---|---|---|
| Ingestion | Python, Dagster assets | Downloads each provider and lands it in Parquet, untransformed. |
| Warehouse | dbt, DuckDB | Staging (parse, rename, type), crosswalks (entity resolution), star schema, reconciliation report. |
| Quality | dbt tests, Dagster asset checks | Every model has tests; they run with every build. |
| Delivery | GitHub Actions, Docker | Lint, ingest, `dbt build`, tests, and an image build on every push. |

## Status

| Part | Status |
|---|---|
| Ingestion of the 3 sources, orchestration, CI, Docker | done |
| Staging StatsBomb | done |
| M1 staging Transfermarkt and football-data | to do |
| M2 team crosswalk | to do |
| M3 match crosswalk | to do |
| M4 player crosswalk (entity resolution) | to do |
| M5 marts | to do |
| M6 cross-source reconciliation | to do |

## Run it

```bash
pip install -e ".[dev]"
python -m cdp ingest              # needs a Kaggle API token for Transfermarkt
python -m cdp dbt build
dagster dev -m cdp.definitions    # http://localhost:3000
```

Or run `docker compose up --build`.

## Why this is not trivial

The same player has different names, ids and spellings across providers. StatsBomb's
"Eduardo dos Santos Haesler" is Transfermarkt's "Dudu", and Transfermarkt lists six
different Dudus. Name matching alone links the wrong people. Team names differ as well
(Heidenheim is "FC Heidenheim", "1. Fußballclub Heidenheim 1846" or "Heidenheim" depending on
the source), and providers count shots and cards in their own ways. The platform has to link entities reliably, and it has to
tell a data defect from a difference of definition.

## Data

- [StatsBomb Open Data](https://github.com/statsbomb/open-data): attribution required by its licence.
- [Transfermarkt dataset on Kaggle](https://www.kaggle.com/datasets/davidcariboo/player-scores) (CC0).
- [football-data.co.uk](https://www.football-data.co.uk/): results, match statistics and odds.

No data is committed to this repository. `python -m cdp ingest` downloads it.
