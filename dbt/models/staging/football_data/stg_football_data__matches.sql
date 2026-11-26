-- M1 · TODO: Every lake column is text. Dates are dd/mm/yyyy (DuckDB: strptime). Choose a unique match_key. Beware: 'AS' is a SQL keyword, quote it.
-- Columns and tests: see the .yml file in this folder. Replace this whole query.
select
    null::varchar as match_key,
    null::date    as match_date,
    null::time    as kick_off,
    null::varchar as home_team,
    null::varchar as away_team,
    null::integer as home_goals,
    null::integer as away_goals,
    null::integer as home_shots,
    null::integer as away_shots,
    null::integer as home_shots_on_target,
    null::integer as away_shots_on_target,
    null::integer as home_yellow_cards,
    null::integer as away_yellow_cards,
    null::integer as home_red_cards,
    null::integer as away_red_cards,
    null::double  as odds_home_avg,
    null::double  as odds_draw_avg,
    null::double  as odds_away_avg
where false
