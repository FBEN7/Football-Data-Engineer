-- M1 · TODO: One row per game of the season. Filter source('transfermarkt', 'games') with var('transfermarkt_competition_id') and var('transfermarkt_season'); rename goal columns.
-- Columns and tests: see the .yml file in this folder. Replace this whole query.
select
    null::bigint  as game_id,
    null::date    as game_date,
    null::varchar as round,
    null::bigint  as home_club_id,
    null::varchar as home_club_name,
    null::bigint  as away_club_id,
    null::varchar as away_club_name,
    null::bigint  as home_goals,
    null::bigint  as away_goals,
    null::varchar as referee,
    null::bigint  as attendance,
    null::varchar as stadium
where false
