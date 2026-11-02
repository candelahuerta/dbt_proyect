with clientes as (
    select * from {{ ref('int_clientes_enriquecidos') }}
)

select
    {{ generar_clave_subrogada(['id_cliente']) }} as sk_cliente,
    id_cliente,
    nombre_cliente,
    direccion_cliente,
    telefono_cliente,
    segmento_mercado,
    saldo_cuenta_cliente,
    situacion_saldo,
    nombre_nacion,
    nombre_region
from clientes