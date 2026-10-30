--carga incremental
--la primera vez crea la tabla completa, y en las siguientes ejecuciones solo trae las filas nuevas o modificadas y las añade a la tabla que ya existe
--usamos columna fecha para saber que es lo nuevo

{{
    config(
        materialized = 'incremental',
        unique_key = ['id_pedido', 'numero_linea'],
        incremental_strategy = 'merge'
    )
}}

with origen as (
    select * from {{ source('tpch', 'lineitem') }}

    {% if is_incremental() %}
        where l_shipdate >= (select max(fecha_envio) from {{ this }})
    {% endif %}

),

renombrado as (
    select
        l_orderkey as id_pedido,
        l_partkey  as id_pieza,
        l_suppkey as id_proveedor,
        l_linenumber as numero_linea,
        l_quantity as cantidad,
        l_extendedprice as precio_bruto,
        l_discount as descuento,
        l_tax as impuesto,
        l_returnflag as indicador_devolucion,
        l_linestatus as estado_linea,
        l_shipdate as fecha_envio,
        l_commitdate as fecha_compromiso,
        l_receiptdate as fecha_recepcion,
        l_shipinstruct as instrucciones_envio,
        l_shipmode as modo_envio,
        l_comment as comentario_linea,
        current_timestamp() as fecha_carga
    from origen

)

select * from renombrado