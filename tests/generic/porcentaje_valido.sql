{% test porcentaje_valido(model, column_name) %}

    select {{ column_name }}
    from {{ model }}
    where {{ column_name }} < 0
       or {{ column_name }} > 100

{% endtest %}