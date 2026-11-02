with clientes as (
    select * from {{ ref('stg_tpch__customer') }}
),

naciones as (
    select * from {{ ref('stg_tpch__nation') }}
),

regiones as (
    select * from {{ ref('stg_tpch__region') }}
),

final as (
    select
        clientes.id_cliente,
        clientes.nombre_cliente,
        clientes.direccion_cliente,
        clientes.telefono_cliente,
        clientes.segmento_mercado,
        clientes.saldo_cuenta_cliente,
        case
            when clientes.saldo_cuenta_cliente < 0 then 'Deudor'
            else 'Solvente'
        end as situacion_saldo,
        naciones.id_nacion,
        naciones.nombre_nacion,
        regiones.id_region,
        regiones.nombre_region
    from clientes
    left join naciones
        on clientes.id_nacion = naciones.id_nacion
    left join regiones
        on naciones.id_region = regiones.id_region

)
select * from final