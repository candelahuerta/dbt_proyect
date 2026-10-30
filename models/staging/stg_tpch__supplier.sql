with origen as (
    select * from {{ source('tpch', 'supplier') }}
),

renombrado as (
    select
        s_suppkey as id_proveedor,
        s_name as nombre_proveedor,
        s_address as direccion_proveedor,
        s_nationkey as id_nacion,
        s_phone as telefono_proveedor,
        s_acctbal as saldo_cuenta_proveedor,
        s_comment as comentario_proveedor
    from origen
)
select * from renombrado