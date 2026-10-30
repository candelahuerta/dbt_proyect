with origen as (
    select * from {{ source('tpch', 'partsupp') }}
),

renombrado as (
    select
        ps_partkey as id_pieza,
        ps_suppkey as id_proveedor,
        ps_availqty as cantidad_disponible,
        ps_supplycost as coste_suministro,
        ps_comment as comentario_pieza_proveedor
    from origen
)
select * from renombrado