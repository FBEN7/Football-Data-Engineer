-- One row per event: the columns every event type shares. Type-specific fields stay in
-- `payload` (JSON) for the models that need them (see stg_statsbomb__shots).
-- Coordinates: 120 x 80, the acting team always attacking towards x = 120.
with source as (
    select match_id, event_id, event_index, payload::json as p
    from {{ source('statsbomb', 'events') }}
)
select
    event_id,
    match_id,
    event_index,
    (p ->> '$.period')::int                       as period,
    p ->> '$.timestamp'                           as period_timestamp,
    (p ->> '$.minute')::int                       as minute,
    (p ->> '$.second')::int                       as second,
    p ->> '$.type.name'                           as type_name,
    (p ->> '$.team.id')::int                      as team_id,
    p ->> '$.team.name'                           as team_name,
    (p ->> '$.player.id')::bigint                 as player_id,
    p ->> '$.player.name'                         as player_name,
    (p ->> '$.possession')::int                   as possession,
    (p ->> '$.possession_team.id')::int           as possession_team_id,
    p ->> '$.play_pattern.name'                   as play_pattern,
    (p -> '$.location[0]')::double                as location_x,
    (p -> '$.location[1]')::double                as location_y,
    coalesce((p ->> '$.under_pressure')::boolean, false) as under_pressure,
    p                                             as payload
from source
