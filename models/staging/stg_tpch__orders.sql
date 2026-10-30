--carga incremental
--la primera vez crea la tabla completa, y en las siguientes ejecuciones solo trae las filas nuevas o modificadas y las añade a la tabla que ya existe
--usamos columna fecha para saber que es lo nuevo
{{
    config(
        materialized = 'incremental',
        unique_key = 'id_pedido',
        incremental_strategy = 'merge'
    )
}}

with origen as (
    select * from {{ source('tpch', 'orders') }}
    {% if is_incremental() %}
        where o_orderdate >= (select max(fecha_pedido) from {{ this }})
    {% endif %}

),

renombrado as (

    select
        o_orderkey as id_pedido,
        o_custkey as id_cliente,
        o_orderstatus as estado_pedido,
        o_totalprice as precio_total_pedido,
        o_orderdate as fecha_pedido,
        o_orderpriority as prioridad_pedido,
        o_clerk as empleado,
        o_shippriority as prioridad_envio,
        o_comment as comentario_pedido,
        current_timestamp() as fecha_carga
    from origen

)

select * from renombrado