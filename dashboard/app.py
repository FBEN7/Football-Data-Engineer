from __future__ import annotations

import os
from pathlib import Path

import duckdb
import pandas as pd
import streamlit as st

st.set_page_config(page_title="Leverkusen 2023/24", page_icon="⚽", layout="wide")

ROOT = Path(__file__).resolve().parents[1]
WAREHOUSE = Path(os.environ.get("CDP_WAREHOUSE", ROOT / "data" / "warehouse.duckdb"))


def read_table(table: str) -> pd.DataFrame:
    if not WAREHOUSE.exists():
        return pd.DataFrame()
    with duckdb.connect(str(WAREHOUSE), read_only=True) as con:
        tables = {row[0] for row in con.execute("show tables").fetchall()}
        if table not in tables:
            return pd.DataFrame()
        return con.execute(f'SELECT * FROM "{table}"').df()


st.title("Bayer Leverkusen 2023/24")
st.caption("Club data platform — consumption via dbt mart and reconciliation tables only")

players = read_table("dim_player")
teams = read_table("dim_team")
matches = read_table("dim_match")
player_match = read_table("fct_player_match")
team_match = read_table("fct_team_match")
reconciliation = read_table("rpt_reconciliation")

available_marts = {
    "dim_team": not teams.empty,
    "dim_player": not players.empty,
    "dim_match": not matches.empty,
    "fct_player_match": not player_match.empty,
    "fct_team_match": not team_match.empty,
    "rpt_reconciliation": not reconciliation.empty,
}
missing_marts = [name for name, available in available_marts.items() if not available]
if missing_marts:
    st.warning(
        "Tables finales non disponibles: " + ", ".join(missing_marts)
        + ". Run `python -m cdp dbt build` after providing the lake sources."
    )

season, players_page, data_quality = st.tabs(["Saison", "Joueurs", "Qualité des données"])

with season:
    col1, col2, col3, col4 = st.columns(4)
    col1.metric("Matchs", len(matches))
    col2.metric("Équipes", len(teams))
    col3.metric("Joueurs", len(players))
    col4.metric("Apparitions", len(player_match))

    st.subheader("Probabilités implicites moyennes")
    probability_columns = ["implied_prob_home", "implied_prob_draw", "implied_prob_away"]
    if set(probability_columns).issubset(matches.columns):
        st.bar_chart(matches[probability_columns].mean())

    st.subheader("Calendrier")
    if matches.empty:
        st.info("Aucun match disponible dans les tables finales.")
    else:
        match_columns = ["match_date", "home_team_key", "away_team_key", "home_goals", "away_goals"]
        st.dataframe(matches[[column for column in match_columns if column in matches.columns]], use_container_width=True)

with players_page:
    st.subheader("Analyse des joueurs")
    if players.empty:
        st.info("Aucun joueur disponible dans `dim_player`.")
    else:
        player_columns = ["player_key", "player_name", "age_at_season_start", "market_value_eur_at_season_start"]
        st.dataframe(players[[column for column in player_columns if column in players.columns]].sort_values(
            "minutes_played", inplace=False
        ) if "minutes_played" in players.columns else players[[column for column in player_columns if column in players.columns]],
            use_container_width=True)

        if "player_key" in player_match.columns:
            summary = player_match.groupby("player_key", as_index=False).agg(
                **{column: (column, "sum") for column in ["minutes_played", "xg", "npxg", "shots", "goals", "assists"] if column in player_match.columns}
            )
            summary = summary.merge(players[["player_key", "player_name"]], on="player_key", how="left")
            st.subheader("Minutes, buts et xG")
            st.dataframe(summary.sort_values("minutes_played", ascending=False) if "minutes_played" in summary else summary,
                         use_container_width=True)

with data_quality:
    st.subheader("Qualité inter-sources")
    if reconciliation.empty:
        st.info("Le rapport de rapprochement est vide.")
    else:
        summary = reconciliation.groupby("check_name", as_index=False).agg(
            rows=("entity_key", "count"),
            matched=("is_match", "sum")
        )
        summary["concordance"] = summary["matched"] / summary["rows"]
        st.dataframe(summary, use_container_width=True)
        st.subheader("Détails")
        st.dataframe(reconciliation, use_container_width=True)
