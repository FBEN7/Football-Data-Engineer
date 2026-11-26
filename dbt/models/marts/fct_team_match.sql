-- M5 · TODO: Two rows per match. Shots from both StatsBomb and football-data: keep both, M6 compares them.
-- Columns and tests: see the .yml file in this folder. Replace this whole query.
select
    null::bigint  as match_key,
    null::varchar as team_key,
    null::boolean as is_home,
    null::integer as goals_for,
    null::integer as goals_against,
    null::bigint  as shots_statsbomb,
    null::integer as shots_football_data,
    null::double  as xg_for,
    null::double  as xg_against,
    null::double  as implied_win_prob
where false
