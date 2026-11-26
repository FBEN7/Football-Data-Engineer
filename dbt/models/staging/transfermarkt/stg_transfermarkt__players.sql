-- M1: players listed in at least one season game.
select distinct
    p.player_id::bigint as player_id,
    p.name::varchar as player_name,
    p.first_name::varchar as first_name,
    p.last_name::varchar as last_name,
    p.date_of_birth::date as date_of_birth,
    p.country_of_citizenship::varchar as citizenship,
    p.position::varchar as position,
    p.sub_position::varchar as sub_position,
    p.foot::varchar as foot,
    p.height_in_cm::bigint as height_cm
from {{ source('transfermarkt', 'players') }} p
inner join (
    select player_id from {{ ref('stg_transfermarkt__game_lineups') }}
    union
    select player_id from {{ ref('stg_transfermarkt__appearances') }}
) season_players using (player_id)
