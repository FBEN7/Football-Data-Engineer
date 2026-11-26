-- M6: one row per check and entity.
with match_scores as (
    select
        'match_score'::varchar as check_name,
        c.statsbomb_match_id::bigint as match_key,
        cast(c.statsbomb_match_id as varchar) as entity_key,
        cast(sb.home_score as varchar) || '-' || cast(sb.away_score as varchar) as statsbomb_value,
        cast(tm.home_goals as varchar) || '-' || cast(tm.away_goals as varchar) as transfermarkt_value,
        cast(fd.home_goals as varchar) || '-' || cast(fd.away_goals as varchar) as football_data_value,
        (sb.home_score = tm.home_goals and sb.away_score = tm.away_goals
         and sb.home_score = fd.home_goals and sb.away_score = fd.away_goals) as is_match
    from {{ ref('int_matches__crosswalk') }} c
    inner join {{ ref('stg_statsbomb__matches') }} sb on sb.match_id = c.statsbomb_match_id
    inner join {{ ref('stg_transfermarkt__games') }} tm on tm.game_id = c.transfermarkt_game_id
    inner join {{ ref('stg_football_data__matches') }} fd on fd.match_key = c.football_data_match_key
),
team_shots as (
    select
        'team_shots'::varchar,
        match_key,
        team_key,
        cast(shots_statsbomb as varchar),
        null::varchar,
        cast(shots_football_data as varchar),
        shots_statsbomb = shots_football_data
    from {{ ref('fct_team_match') }}
),
player_goals as (
    select
        'player_goals'::varchar,
        f.match_key,
        cast(f.player_key as varchar),
        cast(count(case when s.payload ->> '$.shot.outcome.name' = 'Goal' then 1 end) as varchar),
        cast(f.goals as varchar),
        null::varchar,
        count(case when s.payload ->> '$.shot.outcome.name' = 'Goal' then 1 end) = f.goals
    from {{ ref('fct_player_match') }} f
    left join {{ ref('stg_statsbomb__shots') }} s
      on s.match_id = f.match_key and s.player_id = f.player_key
    group by f.match_key, f.player_key, f.goals
),
player_cards as (
    select
        'player_cards'::varchar,
        f.match_key,
        cast(f.player_key as varchar),
        cast(count(case when e.payload ->> '$.foul_committed.card.name' is not null then 1 end) as varchar),
        cast(f.yellow_cards + f.red_cards as varchar),
        null::varchar,
        count(case when e.payload ->> '$.foul_committed.card.name' is not null then 1 end)
            = f.yellow_cards + f.red_cards
    from {{ ref('fct_player_match') }} f
    left join {{ ref('stg_statsbomb__events') }} e
      on e.match_id = f.match_key and e.player_id = f.player_key
     and e.payload ->> '$.foul_committed.card.name' is not null
    group by f.match_key, f.player_key, f.yellow_cards, f.red_cards
)
select * from match_scores
union all
select * from team_shots
union all
select * from player_goals
union all
select * from player_cards
