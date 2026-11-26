-- M1 · TODO: Season games only. jersey_number arrives as text; is_starter comes from the 'type' column.
-- Columns and tests: see the .yml file in this folder. Replace this whole query.
select
    null::bigint  as game_id,
    null::bigint  as club_id,
    null::bigint  as player_id,
    null::varchar as player_name,
    null::integer as jersey_number,
    null::boolean as is_starter,
    null::varchar as position,
    null::boolean as is_captain
where false
