-- cambiamos granularidad:
--El anterior tiene una fila por línea de pedido; este tiene una fila por pedido, resumiendo todas sus líneas

with lineas as (
    select * from {{ ref('int_lineas_pedido_enriquecidas') }}
),

final as (
    select
        id_pedido,
        id_cliente,
        fecha_pedido,
        estado_pedido,
        prioridad_pedido,

        count(*) as numero_lineas,
        sum(cantidad) as cantidad_total,
        sum(importe_neto) as importe_neto_total,
        sum(importe_con_impuestos) as importe_con_impuestos_total,
        sum(margen) as margen_total,
        round(avg(descuento), 4) as descuento_medio,
        sum(case when entregado_con_retraso then 1 else 0 end) as lineas_con_retraso

    from lineas
    group by --agrupamos las lineas de un solo pedidio en una fila
        id_pedido,
        id_cliente,
        fecha_pedido,
        estado_pedido,
        prioridad_pedido

)

select * from final