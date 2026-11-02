with lineas as (
    select * from {{ ref('int_lineas_pedido_enriquecidas') }}
)

select
    -- Clave de la tabla de hechos
    {{ generar_clave_subrogada(['id_pedido', 'numero_linea']) }} as sk_venta,

    -- Claves hacia las dimensiones
    {{ generar_clave_subrogada(['id_cliente']) }}   as sk_cliente,
    {{ generar_clave_subrogada(['id_proveedor']) }} as sk_proveedor,
    {{ generar_clave_subrogada(['id_pieza']) }}     as sk_producto,
    {{ clave_fecha('fecha_pedido') }}               as sk_fecha_pedido,
    {{ clave_fecha('fecha_envio') }}                as sk_fecha_envio,
    {{ clave_fecha('fecha_recepcion') }}            as sk_fecha_recepcion,

    -- Dimensiones degeneradas
    id_pedido,
    numero_linea,
    estado_pedido,
    prioridad_pedido,
    modo_envio,
    indicador_devolucion,
    estado_linea,

    -- Medidas
    cantidad,
    precio_bruto,
    descuento,
    impuesto,
    importe_neto,
    importe_con_impuestos,
    coste_total,
    margen,
    dias_hasta_envio,
    dias_de_transito,
    entregado_con_retraso

from lineas