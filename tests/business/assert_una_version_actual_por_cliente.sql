-- Un cliente no puede tener más de una versión vigente a la vez.
select
    id_cliente,
    count(*) as versiones_actuales
from {{ ref('dim_cliente_historico') }}
where es_version_actual
group by id_cliente
having count(*) > 1