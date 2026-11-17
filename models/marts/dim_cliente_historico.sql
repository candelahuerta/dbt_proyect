with versiones as (
    select
        *,
        row_number() over (
            partition by id_cliente
            order by dbt_valid_from
        ) as numero_version
    from {{ ref('snp_clientes') }}

),

final as (
    select
        {{ generar_clave_subrogada(['id_cliente', 'dbt_valid_from']) }} as sk_cliente_version,
        {{ generar_clave_subrogada(['id_cliente']) }}                   as sk_cliente,
        id_cliente,
        nombre_cliente,
        direccion_cliente,
        telefono_cliente,
        segmento_mercado,
        numero_version,
        case
            when numero_version = 1 then '1900-01-01'::timestamp_ntz
            else dbt_valid_from
        end                                                as valido_desde,
        coalesce(dbt_valid_to, '9999-12-31'::timestamp_ntz) as valido_hasta,
        dbt_valid_to is null                               as es_version_actual
    from versiones

)

select * from final