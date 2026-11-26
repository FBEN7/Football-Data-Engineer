-- M1: only clubs represented in the configured season's games.
with season_games as (
    select * from {{ ref('stg_transfermarkt__games') }}
),
club_ids as (
    select distinct home_club_id as club_id from season_games
    union
    select distinct away_club_id as club_id from season_games
)
select
    c.club_id::bigint as club_id,
    c.name::varchar as club_name,
    c.club_code::varchar as club_code
from {{ source('transfermarkt', 'clubs') }} c
inner join club_ids s on s.club_id = c.club_id
