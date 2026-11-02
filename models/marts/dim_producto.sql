with piezas as (
    select * from {{ ref('int_piezas_enriquecidas') }}
)

select
    {{ generar_clave_subrogada(['id_pieza']) }} as sk_producto,
    id_pieza,
    nombre_pieza,
    fabricante,
    marca,
    tipo_pieza,
    tamano_pieza,
    tipo_envase,
    precio_venta_publico,
    numero_proveedores,
    stock_total,
    coste_suministro_medio,
    coste_suministro_minimo,
    coste_suministro_maximo
from piezas