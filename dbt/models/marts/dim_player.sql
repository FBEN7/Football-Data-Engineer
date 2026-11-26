-- M5 · TODO: One row per linked player. Age on var('season_start') in whole years; market value = latest valuation on or before that date.
-- Columns and tests: see the .yml file in this folder. Replace this whole query.
select
    null::bigint  as player_key,
    null::bigint  as statsbomb_player_id,
    null::varchar as player_name,
    null::varchar as full_name,
    null::date    as date_of_birth,
    null::bigint  as age_at_season_start,
    null::varchar as citizenship,
    null::varchar as position,
    null::varchar as foot,
    null::bigint  as height_cm,
    null::bigint  as market_value_eur_at_season_start
where false
