-- M3 · TODO: One row per StatsBomb match. Translate team ids with the team_crosswalk seed, then find the same match in Transfermarkt and football-data. Which columns identify a league match without relying on the date?
-- Columns and tests: see the .yml file in this folder. Replace this whole query.
select
    null::bigint  as statsbomb_match_id,
    null::bigint  as transfermarkt_game_id,
    null::varchar as football_data_match_key,
    null::date    as match_date,
    null::varchar as home_team,
    null::varchar as away_team
where false
