-- para comprobar que una fecha esta entre una minima y una maxima

{% test fecha_en_rango(model, column_name, fecha_minima, fecha_maxima) %}

    select {{ column_name }}
    from {{ model }}
    where {{ column_name }} < '{{ fecha_minima }}'::date
       or {{ column_name }} > '{{ fecha_maxima }}'::date

{% endtest %}