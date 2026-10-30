with origen as (
    select * from {{ source('tpch', 'nation') }}
),

renombrado as (
    select
        n_nationkey as id_nacion,
        n_name as nombre_nacion,
        n_regionkey as id_region,
        n_comment as comentario_nacion
    from origen
)
select * from renombrado