-- Junta cada línea con su pedido (para saber el cliente y la fecha) y con su coste de proveedor (para calcular el margen)

with lineas as (
    select * from {{ ref('stg_tpch__lineitem') }}
),

pedidos as (
    select * from {{ ref('stg_tpch__orders') }}
),

piezas_proveedores as (
    select * from {{ ref('stg_tpch__partsupp') }}

),

final as (
    select
        -- Claves
        lineas.id_pedido,
        lineas.numero_linea,
        lineas.id_pieza,
        lineas.id_proveedor,
        pedidos.id_cliente,

        -- Datos del pedido
        pedidos.fecha_pedido,
        pedidos.estado_pedido,
        pedidos.prioridad_pedido,

        -- Datos de la línea
        lineas.fecha_envio,
        lineas.fecha_compromiso,
        lineas.fecha_recepcion,
        lineas.modo_envio,
        lineas.indicador_devolucion,
        lineas.estado_linea,

        -- Métricas de origen
        lineas.cantidad,
        lineas.precio_bruto,
        lineas.descuento,
        lineas.impuesto,
        piezas_proveedores.coste_suministro,

        -- Métricas calculadas
        round(lineas.precio_bruto * (1 - lineas.descuento), 2) as importe_neto,
        round(lineas.precio_bruto * (1 - lineas.descuento) * (1 + lineas.impuesto), 2) as importe_con_impuestos,
        round(lineas.cantidad * piezas_proveedores.coste_suministro, 2) as coste_total,
        round(lineas.precio_bruto * (1 - lineas.descuento)
              - lineas.cantidad * piezas_proveedores.coste_suministro, 2) as margen,

        -- Indicadores logísticos
        datediff(day, pedidos.fecha_pedido, lineas.fecha_envio) as dias_hasta_envio,
        datediff(day, lineas.fecha_envio, lineas.fecha_recepcion) as dias_de_transito,
        lineas.fecha_recepcion > lineas.fecha_compromiso as entregado_con_retraso

    from lineas
    left join pedidos
        on lineas.id_pedido = pedidos.id_pedido
    left join piezas_proveedores
        on  lineas.id_pieza = piezas_proveedores.id_pieza
        and lineas.id_proveedor = piezas_proveedores.id_proveedor -- 2 join pq la misma pieza puede costar distinto según a quién se la compres

)

select * from final