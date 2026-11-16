-- Un pedido no se envía antes de pedirse ni se recibe antes de enviarse.
select
    id_pedido,
    numero_linea,
    fecha_pedido,
    fecha_envio,
    fecha_recepcion
from {{ ref('int_lineas_pedido_enriquecidas') }}
where fecha_envio < fecha_pedido
   or fecha_recepcion < fecha_envio