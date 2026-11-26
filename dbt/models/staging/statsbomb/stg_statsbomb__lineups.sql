-- One row per player listed in a match squad (starters, substitutes used or not).
with teams as (
    select match_id, team_id, payload::json as p from {{ source('statsbomb', 'lineups') }}
),
players as (
    select match_id, team_id, p ->> '$.team_name' as team_name, unnest(p -> '$.lineup[*]') as pl
    from teams
)
select
    match_id,
    team_id,
    team_name,
    (pl ->> '$.player_id')::bigint                         as player_id,
    pl ->> '$.player_name'                                 as player_name,
    pl ->> '$.player_nickname'                             as player_nickname,
    (pl ->> '$.jersey_number')::int                        as jersey_number,
    pl ->> '$.country.name'                                as country_name,
    coalesce(pl ->> '$.positions[0].start_reason' = 'Starting XI', false) as is_starter,
    json_array_length(pl -> '$.positions') > 0            as played
from players
