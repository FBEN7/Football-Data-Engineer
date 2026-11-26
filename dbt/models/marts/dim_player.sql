-- M5 · TODO: One row per linked player. Age on var('season_start') in whole years; market value = latest valuation on or before that date.
-- Columns and tests: see the .yml file in this folder. Replace this whole query.
with valuations as (
    select
        player_id,
        arg_max(market_value_eur, valued_on) filter (
            where valued_on <= '{{ var("season_start") }}'::date
        ) as market_value_eur_at_season_start
    from {{ ref('stg_transfermarkt__player_valuations') }}
    group by player_id
)
select
    pc.transfermarkt_player_id::bigint as player_key,
    pc.statsbomb_player_id::bigint as statsbomb_player_id,
    pc.transfermarkt_player_name::varchar as player_name,
    pc.statsbomb_player_name::varchar as full_name,
    p.date_of_birth::date as date_of_birth,
    date_diff('year', p.date_of_birth, '{{ var("season_start") }}'::date)::bigint as age_at_season_start,
    p.citizenship::varchar as citizenship,
    p.position::varchar as position,
    p.foot::varchar as foot,
    p.height_cm::bigint as height_cm,
    v.market_value_eur_at_season_start::bigint as market_value_eur_at_season_start
from {{ ref('int_players__crosswalk') }} pc
inner join {{ ref('stg_transfermarkt__players') }} p
    on p.player_id = pc.transfermarkt_player_id
left join valuations v
    on v.player_id = pc.transfermarkt_player_id
