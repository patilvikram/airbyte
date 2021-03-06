{#
    Overriding the following macro from dbt-utils:
        https://github.com/fishtown-analytics/dbt-utils/blob/0.6.2/macros/cross_db_utils/concat.sql
    To implement our own version of concat
    Because on postgres, we cannot pass more than 100 arguments to a function
#}

{% macro concat(fields) -%}
  {{ adapter.dispatch('concat')(fields) }}
{%- endmacro %}

{% macro default__concat(fields) -%}
    concat({{ fields|join(', ') }})
{%- endmacro %}

{% macro alternative_concat(fields) %}
    {{ fields|join(' || ') }}
{% endmacro %}


{% macro postgres__concat(fields) %}
    {{ dbt_utils.alternative_concat(fields) }}
{% endmacro %}


{% macro redshift__concat(fields) %}
    {{ dbt_utils.alternative_concat(fields) }}
{% endmacro %}


{% macro snowflake__concat(fields) %}
    {{ dbt_utils.alternative_concat(fields) }}
{% endmacro %}
