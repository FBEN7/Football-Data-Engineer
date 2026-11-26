-- M1: season appearances for the player club, not the opponent club.
select
    a.appearance_id::varchar as appearance_id,
    a.game_id::bigint as game_id,
    a.player_id::bigint as player_id,
    a.player_club_id::bigint as club_id,
    a.minutes_played::bigint as minutes_played,
    a.goals::bigint as goals,
    a.assists::bigint as assists,
    a.yellow_cards::bigint as yellow_cards,
    a.red_cards::bigint as red_cards
from {{ source('transfermarkt', 'appearances') }} a
inner join {{ ref('stg_transfermarkt__games') }} g
    on g.game_id = a.game_id
