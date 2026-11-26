-- M1: season games only.
select
    l.game_id::bigint as game_id,
    l.club_id::bigint as club_id,
    l.player_id::bigint as player_id,
    l.player_name::varchar as player_name,
    l.number::integer as jersey_number,
    (l.type = 'starting_lineup') as is_starter,
    l.position::varchar as position,
    coalesce(l.team_captain::boolean, false) as is_captain
from {{ source('transfermarkt', 'game_lineups') }} l
inner join {{ ref('stg_transfermarkt__games') }} g
    on g.game_id = l.game_id
