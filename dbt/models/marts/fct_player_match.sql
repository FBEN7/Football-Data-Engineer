-- M5 · TODO: One row per player who PLAYED. Minutes, goals, assists, cards from Transfermarkt; shots, xG, npxG, passes from StatsBomb events (periods 1-4).
-- Columns and tests: see the .yml file in this folder. Replace this whole query.
select
    null::bigint  as match_key,
    null::bigint  as player_key,
    null::varchar as team_key,
    null::boolean as is_starter,
    null::bigint  as minutes_played,
    null::bigint  as goals,
    null::bigint  as assists,
    null::bigint  as yellow_cards,
    null::bigint  as red_cards,
    null::bigint  as shots,
    null::double  as xg,
    null::double  as npxg,
    null::bigint  as passes,
    null::bigint  as passes_completed
where false
