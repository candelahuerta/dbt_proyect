-- Al pasar de lineas a pedidos no se pierde ni se duplica nada
with lineas as (
    select
        count(*) as total_lineas,
        sum(importe_neto) as total_importe
    from {{ ref('int_lineas_pedido_enriquecidas') }}

),

pedidos as (
    select
        sum(numero_lineas) as total_lineas,
        sum(importe_neto_total) as total_importe
    from {{ ref('int_pedidos_agregados') }}

)

select
    lineas.total_lineas as lineas_en_detalle,
    pedidos.total_lineas as lineas_en_pedidos,
    lineas.total_importe as importe_en_detalle,
    pedidos.total_importe as importe_en_pedidos
from lineas
cross join pedidos
where lineas.total_lineas <> pedidos.total_lineas --num lineas no coincide
   or abs(lineas.total_importe - pedidos.total_importe) > 1 --margen de error de 1€