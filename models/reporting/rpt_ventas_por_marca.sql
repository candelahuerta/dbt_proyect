with ventas as (
    select * from {{ ref('fct_ventas') }}
),

productos as (
    select * from {{ ref('dim_producto') }}
)

select
    productos.fabricante,
    productos.marca,
    count(distinct ventas.sk_producto) as productos_vendidos,
    sum(ventas.cantidad) as unidades_vendidas,
    round(sum(ventas.importe_neto), 2) as ventas_netas,
    round(sum(ventas.margen), 2) as margen_total,
    {{ calcular_porcentaje('sum(ventas.margen)', 'sum(ventas.importe_neto)') }} as porcentaje_margen,
    {{ calcular_porcentaje(
        "sum(case when ventas.indicador_devolucion = 'R' then 1 else 0 end)",
        'count(*)'
    ) }} as porcentaje_lineas_devueltas
from ventas
join productos
    on ventas.sk_producto = productos.sk_producto
group by
    productos.fabricante,
    productos.marca