-- M1: one row per game in the configured season and competition.
with source as (
    select *
    from {{ source('transfermarkt', 'games') }}
    where competition_id = '{{ var("transfermarkt_competition_id") }}'
      and season = {{ var('transfermarkt_season') }}
)
select
    game_id::bigint as game_id,
    date::date as game_date,
    round,
    home_club_id::bigint as home_club_id,
    home_club_name,
    away_club_id::bigint as away_club_id,
    away_club_name,
    home_club_goals::bigint as home_goals,
    away_club_goals::bigint as away_goals,
    referee,
    attendance::bigint as attendance,
    stadium
from source
