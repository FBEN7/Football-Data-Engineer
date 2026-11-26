-- M1 · TODO: Players listed in the season's lineups. date_of_birth arrives as TIMESTAMP: make it a DATE.
-- Columns and tests: see the .yml file in this folder. Replace this whole query.
select
    null::bigint  as player_id,
    null::varchar as player_name,
    null::varchar as first_name,
    null::varchar as last_name,
    null::date    as date_of_birth,
    null::varchar as citizenship,
    null::varchar as position,
    null::varchar as sub_position,
    null::varchar as foot,
    null::bigint  as height_cm
where false
