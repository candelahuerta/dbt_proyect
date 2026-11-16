-- Alerta donde ventas en las que la empresa pierde dinero.

{{ config(severity = 'warn') }} --si encuentra lo marcara como aviso

select
    sk_venta,
    importe_neto,
    coste_total,
    margen
from {{ ref('fct_ventas') }}
where margen < 0