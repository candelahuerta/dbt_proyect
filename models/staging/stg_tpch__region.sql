with origen as (
    select * from {{ source('tpch', 'region') }}

),

renombrado as (
    select
        r_regionkey as id_region,
        r_name as nombre_region,
        r_comment as comentario_region
    from origen
)
select * from renombrado