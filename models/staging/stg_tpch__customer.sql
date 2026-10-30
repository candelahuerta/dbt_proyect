with origen as (
    select * from {{ source('tpch', 'customer') }}
),

renombrado as (
    select
        c_custkey as id_cliente,
        c_name as nombre_cliente,
        c_address  as direccion_cliente,
        c_nationkey as id_nacion,
        c_phone  as telefono_cliente,
        c_acctbal as saldo_cuenta_cliente,
        c_mktsegment as segmento_mercado,
        c_comment as comentario_cliente
    from origen
)
select * from renombrado