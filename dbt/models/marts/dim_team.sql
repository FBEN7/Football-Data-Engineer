-- M5 · TODO: One row per club, from the seed, with Transfermarkt's official name.
-- Columns and tests: see the .yml file in this folder. Replace this whole query.
select
    tc.canonical_name::varchar as team_key,
    tc.statsbomb_team_id::integer as statsbomb_team_id,
    tc.transfermarkt_club_id::bigint as transfermarkt_club_id,
    tc.football_data_team::varchar as football_data_team,
    c.club_name::varchar as club_name
from {{ ref('team_crosswalk') }} tc
left join {{ ref('stg_transfermarkt__clubs') }} c
    on c.club_id = tc.transfermarkt_club_id
