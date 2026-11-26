-- M1 · TODO: Every lake column is text. Dates are dd/mm/yyyy (DuckDB: strptime). Choose a unique match_key. Beware: 'AS' is a SQL keyword, quote it.
-- Columns and tests: see the .yml file in this folder. Replace this whole query.
select
    strptime("Date", '%d/%m/%Y')::date::varchar
        || '-' || replace(trim("HomeTeam"), ' ', '-') as match_key,
    strptime("Date", '%d/%m/%Y')::date as match_date,
    try_strptime("Time", '%H:%M')::time as kick_off,
    trim("HomeTeam")::varchar as home_team,
    trim("AwayTeam")::varchar as away_team,
    try_cast("FTHG" as integer) as home_goals,
    try_cast("FTAG" as integer) as away_goals,
    try_cast("HS" as integer) as home_shots,
    try_cast("AS" as integer) as away_shots,
    try_cast("HST" as integer) as home_shots_on_target,
    try_cast("AST" as integer) as away_shots_on_target,
    try_cast("HY" as integer) as home_yellow_cards,
    try_cast("AY" as integer) as away_yellow_cards,
    try_cast("HR" as integer) as home_red_cards,
    try_cast("AR" as integer) as away_red_cards,
    try_cast("AvgH" as double) as odds_home_avg,
    try_cast("AvgD" as double) as odds_draw_avg,
    try_cast("AvgA" as double) as odds_away_avg
from {{ source('football_data', 'matches') }}
