-- M5 · TODO: Two rows per match. Shots from both StatsBomb and football-data: keep both, M6 compares them.
-- Columns and tests: see the .yml file in this folder. Replace this whole query.
with match_sides as (
    select mc.statsbomb_match_id as match_key,
           mc.home_team as team_key,
           true as is_home,
           tm.home_goals as goals_for,
           tm.away_goals as goals_against
    from {{ ref('int_matches__crosswalk') }} mc
    inner join {{ ref('stg_transfermarkt__games') }} tm
        on tm.game_id = mc.transfermarkt_game_id
    union all
    select mc.statsbomb_match_id,
           mc.away_team,
           false,
           tm.away_goals,
           tm.home_goals
    from {{ ref('int_matches__crosswalk') }} mc
    inner join {{ ref('stg_transfermarkt__games') }} tm
        on tm.game_id = mc.transfermarkt_game_id
),
team_metrics as (
    select
        tc.match_key,
        tc.team_key,
        tc.is_home,
        tc.goals_for,
        tc.goals_against,
        count(s.event_id) as shots_statsbomb,
        sum(s.xg) as xg_for
    from match_sides tc
    left join {{ ref('stg_statsbomb__matches') }} sb
        on sb.match_id = tc.match_key
    left join {{ ref('stg_statsbomb__shots') }} s
        on s.match_id = tc.match_key
       and s.team_id = coalesce(
            (select statsbomb_team_id from {{ ref('team_crosswalk') }} c where c.canonical_name = tc.team_key),
            -1
       )
    group by tc.match_key, tc.team_key, tc.is_home, tc.goals_for, tc.goals_against
),
football_shots as (
    select mc.statsbomb_match_id as match_key,
           mc.home_team as team_key,
           fd.home_shots as shots_football_data
    from {{ ref('int_matches__crosswalk') }} mc
    inner join {{ ref('stg_football_data__matches') }} fd
        on fd.match_key = mc.football_data_match_key
    union all
    select mc.statsbomb_match_id,
           mc.away_team,
           fd.away_shots
    from {{ ref('int_matches__crosswalk') }} mc
    inner join {{ ref('stg_football_data__matches') }} fd
        on fd.match_key = mc.football_data_match_key
)
select
    tm.match_key::bigint,
    tm.team_key::varchar,
    tm.is_home::boolean,
    tm.goals_for::integer,
    tm.goals_against::integer,
    tm.shots_statsbomb::bigint,
    fs.shots_football_data::integer,
    tm.xg_for::double,
    0.0::double as xg_against,
    0.0::double as implied_win_prob
from team_metrics tm
left join football_shots fs
    on fs.match_key = tm.match_key
   and fs.team_key = tm.team_key
