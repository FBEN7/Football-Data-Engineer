-- M4 · TODO: One row per StatsBomb player. Do NOT match on names alone (see the yml). Block on match and team, find a reliable linking key, use names only to check, and make sure a player gets the same link in every match.
-- Columns and tests: see the .yml file in this folder. Replace this whole query.
select
    null::bigint  as statsbomb_player_id,
    null::bigint  as transfermarkt_player_id,
    null::varchar as statsbomb_player_name,
    null::varchar as transfermarkt_player_name,
    null::double  as name_similarity,
    null::bigint  as games_listed,
    null::bigint  as games_linked
where false
