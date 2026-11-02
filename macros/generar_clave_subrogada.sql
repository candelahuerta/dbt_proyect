--recibe lista de columnas y crea clave unica a partir de ellas
--cada col a texto, sino nula
{% macro generar_clave_subrogada(columnas) %}

    md5(
        concat_ws(
            '|',
            {%- for columna in columnas %}
            coalesce(cast({{ columna }} as varchar), '_nulo_')
            {%- if not loop.last %},{% endif %}
            {%- endfor %}
        )
    )

{% endmacro %}