-- One row per match. Worked example of a staging model: parse, rename, type. Nothing else.
with source as (
    select match_id, payload::json as p from {{ source('statsbomb', 'matches') }}
)
select
    match_id,
    (p ->> '$.match_date')::date                          as match_date,
    (p ->> '$.kick_off')::time                            as kick_off,
    (p ->> '$.competition.competition_id')::int           as competition_id,
    (p ->> '$.season.season_id')::int                     as season_id,
    (p ->> '$.match_week')::int                           as match_week,
    (p ->> '$.home_team.home_team_id')::int               as home_team_id,
    p ->> '$.home_team.home_team_name'                    as home_team_name,
    (p ->> '$.away_team.away_team_id')::int               as away_team_id,
    p ->> '$.away_team.away_team_name'                    as away_team_name,
    (p ->> '$.home_score')::int                           as home_score,
    (p ->> '$.away_score')::int                           as away_score,
    p ->> '$.referee.name'                                as referee_name,
    p ->> '$.stadium.name'                                as stadium_name
from source
