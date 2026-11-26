{# Small generic tests, so the project needs no package download. #}

{% test accepted_range(model, column_name, min=none, max=none) %}
select {{ column_name }} from {{ model }}
where {{ column_name }} is not null
  and ( false
  {% if min is not none %} or {{ column_name }} < {{ min }} {% endif %}
  {% if max is not none %} or {{ column_name }} > {{ max }} {% endif %} )
{% endtest %}

{% test unique_combination(model, columns) %}
select {{ columns | join(', ') }}, count(*) as n
from {{ model }}
group by {{ columns | join(', ') }}
having count(*) > 1
{% endtest %}

{# Every value of to.field appears in model.column_name (the reverse of `relationships`). #}
{% test covers(model, column_name, to, field) %}
select distinct t.{{ field }} as missing
from {{ to }} as t
where t.{{ field }} is not null
  and t.{{ field }} not in (select {{ column_name }} from {{ model }} where {{ column_name }} is not null)
{% endtest %}

{# Each row of `rows` (a list of value lists matching `columns`) must exist in the model. #}
{% test expected_rows(model, columns, rows) %}
with expected ({{ columns | join(', ') }}) as (
    values {% for r in rows %}({% for v in r %}{% if v is string %}'{{ v }}'{% else %}{{ v }}{% endif %}{{ ", " if not loop.last }}{% endfor %}){{ ", " if not loop.last }}{% endfor %}
)
select * from expected
except
select {{ columns | join(', ') }} from {{ model }}
{% endtest %}

{# Rows for which a SQL boolean expression is false. #}
{% test expression_is_true(model, expression, column_name=none) %}
select * from {{ model }} where not ({{ expression }})
{% endtest %}

{# Crosswalked matches whose final score differs between StatsBomb, Transfermarkt and football-data. #}
{% test scores_agree(model) %}
select c.*, sb.home_score, sb.away_score, tm.home_goals as tm_home, tm.away_goals as tm_away,
       fd.home_goals as fd_home, fd.away_goals as fd_away
from {{ model }} c
join {{ ref('stg_statsbomb__matches') }} sb on sb.match_id = c.statsbomb_match_id
join {{ ref('stg_transfermarkt__games') }} tm on tm.game_id = c.transfermarkt_game_id
join {{ ref('stg_football_data__matches') }} fd on fd.match_key = c.football_data_match_key
where not (sb.home_score = tm.home_goals and sb.away_score = tm.away_goals
           and sb.home_score = fd.home_goals and sb.away_score = fd.away_goals)
{% endtest %}
