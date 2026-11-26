{#
  Generic test: the model has between min and max rows (inclusive).
  An empty or truncated model fails, which is what a crosswalk or a staging
  filter usually does when it is wrong.
#}
{% test row_count(model, min=1, max=none) %}
with n as (select count(*) as rows from {{ model }})
select rows from n
where rows < {{ min }} {% if max is not none %} or rows > {{ max }} {% endif %}
{% endtest %}
