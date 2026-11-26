-- M5 · TODO: One row per Leverkusen match. Implied probabilities: 1/odds, normalised to sum to 1.
-- Columns and tests: see the .yml file in this folder. Replace this whole query.
select
    mc.statsbomb_match_id::bigint as match_key,
    mc.transfermarkt_game_id::bigint as transfermarkt_game_id,
    mc.football_data_match_key::varchar as football_data_match_key,
    mc.match_date::date as match_date,
    mc.home_team::varchar as home_team_key,
    mc.away_team::varchar as away_team_key,
    tm.home_goals::integer as home_goals,
    tm.away_goals::integer as away_goals,
    tm.referee::varchar as referee,
    tm.attendance::bigint as attendance,
    (1.0 / fd.odds_home_avg) /
        ((1.0 / fd.odds_home_avg) + (1.0 / fd.odds_draw_avg) + (1.0 / fd.odds_away_avg))
        as implied_prob_home,
    (1.0 / fd.odds_draw_avg) /
        ((1.0 / fd.odds_home_avg) + (1.0 / fd.odds_draw_avg) + (1.0 / fd.odds_away_avg))
        as implied_prob_draw,
    (1.0 / fd.odds_away_avg) /
        ((1.0 / fd.odds_home_avg) + (1.0 / fd.odds_draw_avg) + (1.0 / fd.odds_away_avg))
        as implied_prob_away
from {{ ref('int_matches__crosswalk') }} mc
inner join {{ ref('stg_transfermarkt__games') }} tm
    on tm.game_id = mc.transfermarkt_game_id
inner join {{ ref('stg_football_data__matches') }} fd
    on fd.match_key = mc.football_data_match_key
