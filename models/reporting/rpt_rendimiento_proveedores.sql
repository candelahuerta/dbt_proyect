with ventas as (
    select * from {{ ref('fct_ventas') }}
),

proveedores as (
    select * from {{ ref('dim_proveedor') }}
)

select
    proveedores.id_proveedor,
    proveedores.nombre_proveedor,
    proveedores.nombre_nacion,
    proveedores.nombre_region,
    count(*) as lineas_suministradas,
    sum(ventas.cantidad) as unidades_suministradas,
    round(sum(ventas.importe_neto), 2) as ventas_netas,
    round(sum(ventas.margen), 2) as margen_total,
    {{ calcular_porcentaje('sum(ventas.margen)', 'sum(ventas.importe_neto)') }} as porcentaje_margen,
    round(avg(ventas.dias_de_transito), 2) as dias_transito_medio,
    {{ calcular_porcentaje(
        'sum(case when ventas.entregado_con_retraso then 1 else 0 end)',
        'count(*)'
    ) }} as porcentaje_entregas_con_retraso
from ventas
join proveedores
    on ventas.sk_proveedor = proveedores.sk_proveedor
group by
    proveedores.id_proveedor,
    proveedores.nombre_proveedor,
    proveedores.nombre_nacion,
    proveedores.nombre_region