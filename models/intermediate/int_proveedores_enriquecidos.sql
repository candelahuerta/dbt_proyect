with proveedores as (
    select * from {{ ref('stg_tpch__supplier') }}
),

naciones as (
    select * from {{ ref('stg_tpch__nation') }}
),

regiones as (
    select * from {{ ref('stg_tpch__region') }}
),

final as (
    select
        proveedores.id_proveedor,
        proveedores.nombre_proveedor,
        proveedores.direccion_proveedor,
        proveedores.telefono_proveedor,
        proveedores.saldo_cuenta_proveedor,
        case
            when proveedores.saldo_cuenta_proveedor < 0 then 'Deudor'
            else 'Solvente'
        end as situacion_saldo,
        naciones.id_nacion,
        naciones.nombre_nacion,
        regiones.id_region,
        regiones.nombre_region
    from proveedores
    left join naciones
        on proveedores.id_nacion = naciones.id_nacion
    left join regiones
        on naciones.id_region = regiones.id_region

)
select * from final