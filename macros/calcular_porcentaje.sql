{% macro calcular_porcentaje(numerador, denominador, decimales=2) %}

    round(100 * {{ numerador }} / nullif({{ denominador }}, 0), {{ decimales }})
-- con el nullif no nos da error pq convierte a nulo el denominador si es 0
{% endmacro %}