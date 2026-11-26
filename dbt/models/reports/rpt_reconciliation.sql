-- M6 · TODO: One row per check and entity: match_score (3 sources), team_shots (StatsBomb vs football-data), player_goals and player_cards (StatsBomb events vs Transfermarkt). is_match = all available sources agree.
-- Columns and tests: see the .yml file in this folder. Replace this whole query.
select
    null::varchar as check_name,
    null::bigint  as match_key,
    null::varchar as entity_key,
    null::varchar as statsbomb_value,
    null::varchar as transfermarkt_value,
    null::varchar as football_data_value,
    null::boolean as is_match
where false
