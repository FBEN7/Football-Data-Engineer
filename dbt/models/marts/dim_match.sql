-- M5 · TODO: One row per Leverkusen match. Implied probabilities: 1/odds, normalised to sum to 1.
-- Columns and tests: see the .yml file in this folder. Replace this whole query.
select
    null::bigint  as match_key,
    null::bigint  as transfermarkt_game_id,
    null::varchar as football_data_match_key,
    null::date    as match_date,
    null::varchar as home_team_key,
    null::varchar as away_team_key,
    null::integer as home_goals,
    null::integer as away_goals,
    null::varchar as referee,
    null::bigint  as attendance,
    null::double  as implied_prob_home,
    null::double  as implied_prob_draw,
    null::double  as implied_prob_away
where false
