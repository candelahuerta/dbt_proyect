-- Las ventas de la tabla de hechos deben coincidir con las calculadas directamente desde los datos de origen.
with origen as (
    select
        count(*) as lineas,
        sum(round(precio_bruto * (1 - descuento), 2)) as ventas_netas --calculamos ventas netas
    from {{ ref('stg_tpch__lineitem') }}

),

hechos as (
    select
        count(*) as lineas,
        sum(importe_neto) as ventas_netas
    from {{ ref('fct_ventas') }}

)

select
    origen.lineas       as lineas_origen,
    hechos.lineas       as lineas_hechos,
    origen.ventas_netas as ventas_origen,
    hechos.ventas_netas as ventas_hechos
from origen
cross join hechos
where origen.lineas <> hechos.lineas --que sean distintas
   or abs(origen.ventas_netas - hechos.ventas_netas) > 1 --margen 1