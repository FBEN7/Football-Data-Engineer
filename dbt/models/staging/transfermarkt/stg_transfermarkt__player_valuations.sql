-- M1 · TODO: All valuations (every date) of the players in stg_transfermarkt__players.
-- Columns and tests: see the .yml file in this folder. Replace this whole query.
-- M1: all valuations for players present in the season.
select
    v.player_id::bigint as player_id,
    v.date::date as valued_on,
    v.market_value_in_eur::bigint as market_value_eur
from {{ source('transfermarkt', 'player_valuations') }} v
inner join {{ ref('stg_transfermarkt__players') }} p
    on p.player_id = v.player_id
