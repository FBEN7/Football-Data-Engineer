-- M4: reliable block is match + team + jersey number; names only validate candidates.
with statsbomb_players as (
    select
        sb.match_id,
        sb.team_id,
        sb.player_id as statsbomb_player_id,
        coalesce(nullif(sb.player_nickname, ''), sb.player_name) as statsbomb_player_name,
        sb.jersey_number
    from {{ ref('stg_statsbomb__lineups') }} sb
),
match_team_links as (
    select
        m.statsbomb_match_id,
        m.transfermarkt_game_id,
        m.home_team,
        m.away_team
    from {{ ref('int_matches__crosswalk') }} m
),
candidate_links as (
    select
        sp.statsbomb_player_id,
        sp.statsbomb_player_name,
        tm.player_id as transfermarkt_player_id,
        tm.player_name as transfermarkt_player_name,
        jaro_winkler_similarity(
            lower(replace(sp.statsbomb_player_name, ' ', '')),
            lower(replace(tm.player_name, ' ', ''))
        ) as name_similarity,
        count(*) over (partition by sp.match_id, sp.team_id, sp.statsbomb_player_id) as candidate_count
    from statsbomb_players sp
    inner join match_team_links mt
        on mt.statsbomb_match_id = sp.match_id
    inner join {{ ref('team_crosswalk') }} tc
        on tc.statsbomb_team_id = sp.team_id
       and (tc.canonical_name = mt.home_team or tc.canonical_name = mt.away_team)
    inner join {{ ref('stg_transfermarkt__game_lineups') }} tm
        on tm.game_id = mt.transfermarkt_game_id
       and tm.club_id = tc.transfermarkt_club_id
       and tm.jersey_number = sp.jersey_number
),
consistent_links as (
    select
        statsbomb_player_id,
        transfermarkt_player_id,
        max(statsbomb_player_name) as statsbomb_player_name,
        max(transfermarkt_player_name) as transfermarkt_player_name,
        max(name_similarity) as name_similarity,
        candidate_count,
        count(distinct transfermarkt_player_id) as transfermarkt_link_count
    from candidate_links
    group by statsbomb_player_id, transfermarkt_player_id, candidate_count
),
linked_players as (
    select
        statsbomb_player_id,
        transfermarkt_player_id,
        statsbomb_player_name,
        transfermarkt_player_name,
        name_similarity
    from consistent_links
    where candidate_count = 1
      and transfermarkt_link_count = 1
),
listed as (
    select
        statsbomb_player_id,
        count(distinct match_id) as games_listed
    from statsbomb_players
    group by statsbomb_player_id
),
linked as (
    select
        statsbomb_player_id,
        count(distinct sp.match_id) as games_linked
    from statsbomb_players sp
    inner join linked_players lp using (statsbomb_player_id)
    group by statsbomb_player_id
)
select
    lp.statsbomb_player_id,
    lp.transfermarkt_player_id,
    lp.statsbomb_player_name,
    lp.transfermarkt_player_name,
    lp.name_similarity,
    l.games_listed,
    coalesce(g.games_linked, 0) as games_linked
from linked_players lp
inner join listed l using (statsbomb_player_id)
left join linked g using (statsbomb_player_id)
