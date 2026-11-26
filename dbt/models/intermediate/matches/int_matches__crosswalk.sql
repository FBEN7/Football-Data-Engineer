-- M3: map each StatsBomb match to Transfermarkt and football-data.
with statsbomb_mapped as (
    select
        sb.match_id,
        sb.match_date,
        sb.match_week,
        home_canonical.canonical_name as home_team,
        away_canonical.canonical_name as away_team
    from {{ ref('stg_statsbomb__matches') }} sb
    inner join {{ ref('team_crosswalk') }} home_canonical
        on home_canonical.statsbomb_team_id = sb.home_team_id
    inner join {{ ref('team_crosswalk') }} away_canonical
        on away_canonical.statsbomb_team_id = sb.away_team_id
),
transfermarkt_mapped as (
    select
        tm.game_id,
        tm.game_date,
        try_cast(regexp_extract(tm.round, '[0-9]+') as integer) as match_week,
        home_canonical.canonical_name as home_team,
        away_canonical.canonical_name as away_team,
        tm.home_goals,
        tm.away_goals
    from {{ ref('stg_transfermarkt__games') }} tm
    inner join {{ ref('team_crosswalk') }} home_canonical
        on home_canonical.transfermarkt_club_id = tm.home_club_id
    inner join {{ ref('team_crosswalk') }} away_canonical
        on away_canonical.transfermarkt_club_id = tm.away_club_id
),
football_data_mapped as (
    select
        fd.match_key,
        fd.match_date,
        home_canonical.canonical_name as home_team,
        away_canonical.canonical_name as away_team,
        fd.home_goals,
        fd.away_goals
    from {{ ref('stg_football_data__matches') }} fd
    inner join {{ ref('team_crosswalk') }} home_canonical
        on home_canonical.football_data_team = fd.home_team
    inner join {{ ref('team_crosswalk') }} away_canonical
        on away_canonical.football_data_team = fd.away_team
),
match_candidates as (
    select
        sb.match_id as statsbomb_match_id,
        tm.game_id as transfermarkt_game_id,
        sb.match_date,
        sb.home_team,
        sb.away_team
    from statsbomb_mapped sb
    inner join transfermarkt_mapped tm
        on tm.match_week = sb.match_week
       and tm.home_team = sb.home_team
       and tm.away_team = sb.away_team
)
select
    mc.statsbomb_match_id,
    mc.transfermarkt_game_id,
    fd.match_key as football_data_match_key,
    mc.match_date,
    mc.home_team,
    mc.away_team
from match_candidates mc
inner join football_data_mapped fd
    on fd.match_date = mc.match_date
   and fd.home_team = mc.home_team
   and fd.away_team = mc.away_team
