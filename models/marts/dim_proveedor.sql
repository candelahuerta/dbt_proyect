with proveedores as (
    select * from {{ ref('int_proveedores_enriquecidos') }}
)

select
    {{ generar_clave_subrogada(['id_proveedor']) }} as sk_proveedor,
    id_proveedor,
    nombre_proveedor,
    direccion_proveedor,
    telefono_proveedor,
    saldo_cuenta_proveedor,
    situacion_saldo,
    nombre_nacion,
    nombre_region
from proveedores