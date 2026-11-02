with ventas as (
    select * from {{ ref('fct_ventas') }}
),

clientes as (
    select * from {{ ref('dim_cliente') }}
),

fechas as (
    select * from {{ ref('dim_fecha') }}
)

select
    clientes.nombre_region,
    fechas.anio,
    fechas.mes,
    fechas.nombre_mes,
    count(distinct ventas.id_pedido) as numero_pedidos,
    count(distinct ventas.sk_cliente) as numero_clientes,
    sum(ventas.cantidad) as unidades_vendidas,
    round(sum(ventas.importe_neto), 2) as ventas_netas,
    round(sum(ventas.margen), 2) as margen_total,
    {{ calcular_porcentaje('sum(ventas.margen)', 'sum(ventas.importe_neto)') }} as porcentaje_margen
from ventas
join clientes
    on ventas.sk_cliente = clientes.sk_cliente
join fechas
    on ventas.sk_fecha_pedido = fechas.sk_fecha
group by
    clientes.nombre_region,
    fechas.anio,
    fechas.mes,
    fechas.nombre_mes