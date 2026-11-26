# M7 — Tableau de bord Streamlit

## Lancer

```bash
pip install -e ".[dashboard]"
streamlit run dashboard/app.py
```

Le tableau de bord lit uniquement les tables DuckDB construites par dbt:
`dim_team`, `dim_player`, `dim_match`, `fct_player_match`, `fct_team_match`,
et `rpt_reconciliation`.

Il ne lit jamais les fichiers lake bruts ni les tables staging/intermediate.
