with origen as (
    select * from {{ source('tpch', 'part') }}
),

renombrado as (
    select
        p_partkey as id_pieza,
        p_name as nombre_pieza,
        p_mfgr as fabricante,
        p_brand as marca,
        p_type as tipo_pieza,
        p_size as tamano_pieza,
        p_container as tipo_envase,
        p_retailprice as precio_venta_publico,
        p_comment as comentario_pieza
    from origen
)
select * from renombrado