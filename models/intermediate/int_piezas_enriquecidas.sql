-- cambiamos granularidad
--En partsupp hay una fila por cada combinación pieza-proveedor, aquí lo resumimos a una fila por pieza y lo juntamos con los datos del catálogo

with piezas as (
    select * from {{ ref('stg_tpch__part') }}
),

piezas_proveedores as (
    select * from {{ ref('stg_tpch__partsupp') }}
),

resumen_proveedores as (

    select
        id_pieza,
        count(distinct id_proveedor) as numero_proveedores,
        sum(cantidad_disponible) as stock_total,
        round(avg(coste_suministro), 2) as coste_suministro_medio,
        min(coste_suministro) as coste_suministro_minimo,
        max(coste_suministro) as coste_suministro_maximo
    from piezas_proveedores
    group by id_pieza

),

final as (

    select
        piezas.id_pieza,
        piezas.nombre_pieza,
        piezas.fabricante,
        piezas.marca,
        piezas.tipo_pieza,
        piezas.tamano_pieza,
        piezas.tipo_envase,
        piezas.precio_venta_publico,
        resumen_proveedores.numero_proveedores,
        resumen_proveedores.stock_total,
        resumen_proveedores.coste_suministro_medio,
        resumen_proveedores.coste_suministro_minimo,
        resumen_proveedores.coste_suministro_maximo
    from piezas
    left join resumen_proveedores
        on piezas.id_pieza = resumen_proveedores.id_pieza

)

select * from final