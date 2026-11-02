--En la tabla de hechos vamos a calcular tres claves de fecha (pedido, envío y recepción)

{% macro clave_fecha(columna) %}

    to_number(to_char({{ columna }}, 'YYYYMMDD'))

{% endmacro %}