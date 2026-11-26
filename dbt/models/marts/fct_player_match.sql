-- M5 · TODO: One row per player who PLAYED. Minutes, goals, assists, cards from Transfermarkt; shots, xG, npxG, passes from StatsBomb events (periods 1-4).
-- Columns and tests: see the .yml file in this folder. Replace this whole query.
with appearance_stats as (
    select
        mc.statsbomb_match_id,
        pc.statsbomb_player_id,
        pc.transfermarkt_player_id,
        tc.canonical_name as team_key,
        coalesce(ll.is_starter, false) as is_starter,
        a.minutes_played,
        a.goals,
        a.assists,
        a.yellow_cards,
        a.red_cards
    from {{ ref('int_matches__crosswalk') }} mc
    inner join {{ ref('stg_transfermarkt__appearances') }} a
        on a.game_id = mc.transfermarkt_game_id
    inner join {{ ref('int_players__crosswalk') }} pc
        on pc.transfermarkt_player_id = a.player_id
    inner join {{ ref('team_crosswalk') }} tc
        on tc.transfermarkt_club_id = a.club_id
    left join {{ ref('stg_transfermarkt__game_lineups') }} ll
        on ll.game_id = mc.transfermarkt_game_id
       and ll.player_id = a.player_id
),
shot_stats as (
    select
        match_id,
        player_id,
        count(*) as shots,
        sum(xg) as xg,
        sum(case when not is_penalty then xg else 0 end) as npxg
    from {{ ref('stg_statsbomb__shots') }}
    group by match_id, player_id
),
pass_stats as (
    select
        match_id,
        player_id,
        count(*) as passes,
        sum(case
            when payload ->> '$.pass.outcome.name' is null then 1
            else 0
        end) as passes_completed
    from {{ ref('stg_statsbomb__events') }}
    where type_name = 'Pass'
    group by match_id, player_id
)
select
    ap.statsbomb_match_id::bigint as match_key,
    ap.transfermarkt_player_id::bigint as player_key,
    ap.team_key::varchar as team_key,
    ap.is_starter::boolean as is_starter,
    ap.minutes_played::bigint as minutes_played,
    ap.goals::bigint as goals,
    ap.assists::bigint as assists,
    ap.yellow_cards::bigint as yellow_cards,
    ap.red_cards::bigint as red_cards,
    coalesce(s.shots, 0)::bigint as shots,
    coalesce(s.xg, 0.0)::double as xg,
    coalesce(s.npxg, 0.0)::double as npxg,
    coalesce(p.passes, 0)::bigint as passes,
    coalesce(p.passes_completed, 0)::bigint as passes_completed
from appearance_stats ap
left join shot_stats s
    on s.match_id = ap.statsbomb_match_id
   and s.player_id = ap.statsbomb_player_id
left join pass_stats p
    on p.match_id = ap.statsbomb_match_id
   and p.player_id = ap.statsbomb_player_id
