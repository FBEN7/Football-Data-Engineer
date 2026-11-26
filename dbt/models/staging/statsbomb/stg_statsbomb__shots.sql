-- One row per shot, with StatsBomb's xG. The penalty shoot-out (period 5) is not play.
select
    event_id,
    match_id,
    team_id,
    player_id,
    period,
    minute,
    location_x,
    location_y,
    (payload ->> '$.shot.statsbomb_xg')::double     as xg,
    payload ->> '$.shot.outcome.name'               as outcome,
    payload ->> '$.shot.outcome.name' = 'Goal'      as is_goal,
    payload ->> '$.shot.type.name'                  as shot_type,
    payload ->> '$.shot.type.name' = 'Penalty'      as is_penalty,
    payload ->> '$.shot.body_part.name'             as body_part
from {{ ref('stg_statsbomb__events') }}
where type_name = 'Shot' and period < 5
