-- Los tres informes deben sumar las mismas ventas que la tabla de hechos, porque son los mismos datos agrupados de otra forma.
with hechos as (
    select sum(importe_neto) as total
    from {{ ref('fct_ventas') }}

),
--calculamos total de cada fila y los apilamos uno debajo de otro
informes as (
    select 'rpt_ventas_mensuales_region' as informe, sum(ventas_netas) as total
    from {{ ref('rpt_ventas_mensuales_region') }}

    union all

    select 'rpt_rendimiento_proveedores', sum(ventas_netas)
    from {{ ref('rpt_rendimiento_proveedores') }}

    union all

    select 'rpt_ventas_por_marca', sum(ventas_netas)
    from {{ ref('rpt_ventas_por_marca') }}

)

select
    informes.informe,
    informes.total as total_informe,
    hechos.total   as total_hechos
from informes
cross join hechos --ponemos el total de hechos al lado de cada una de las 3 filas
where abs(informes.total - hechos.total) > 100 --margen de 100€ 