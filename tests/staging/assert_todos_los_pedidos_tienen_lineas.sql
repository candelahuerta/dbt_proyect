-- No puede existir un pedido sin ninguna línea.

select pedidos.id_pedido
from {{ ref('stg_tpch__orders') }} as pedidos
left join {{ ref('stg_tpch__lineitem') }} as lineas
    on pedidos.id_pedido = lineas.id_pedido
where lineas.id_pedido is null --se queda con pedidios sin linea