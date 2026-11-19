# Fuentes de datos

El proyecto lee de una única fuente: el dataset **TPC-H** que Snowflake ofrece como datos de ejemplo, en `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` (escala 1). Simula una empresa mayorista de piezas.

| | |
| --- | --- |
| Base de datos | `SNOWFLAKE_SAMPLE_DATA` |
| Esquema | `TPCH_SF1` |
| Tablas | 8 |
| Periodo de los datos | 1992 a 1998 |
| Acceso | Solo lectura: no se puede modificar |
| Propietario | Snowflake (datos de ejemplo) |
| Declaración en dbt | `models/staging/_tpch__sources.yml`, fuente `tpch` |

Los modelos leen estas tablas con `source('tpch', '<tabla>')`. Así, si el origen cambiara, solo habría que modificarlo en un sitio, y dbt puede dibujar el linaje desde el origen. Cada tabla tiene un modelo de staging que la copia y renombra sus columnas; las columnas de origen siguen la convención antigua de TPC-H, con un prefijo por tabla (`c_` en clientes, `o_` en pedidos...).

```
REGION ── NATION ──┬── CUSTOMER ── ORDERS ── LINEITEM
                   │                            │
                   └── SUPPLIER ── PARTSUPP ────┘
                                     │
                         PART ───────┘
```

{% docs fuente_tpch %}
Dataset TPC-H de ejemplo de Snowflake (escala 1). Simula una empresa mayorista de piezas: clientes, proveedores, catálogo, pedidos y líneas de pedido. Es de solo lectura y sus datos abarcan de 1992 a 1998. La documentación completa está en `documentacion/fuentes.md`.
{% enddocs %}

{% docs fuente_region %}
**Regiones geográficas** (5 filas). Modelo de staging: `stg_tpch__region`.
{% enddocs %}

{% docs fuente_nation %}
**Países** (25 filas), cada uno asociado a una región mediante `n_regionkey`. Modelo de staging: `stg_tpch__nation`.
{% enddocs %}

{% docs fuente_customer %}
**Clientes** de la empresa (150.000 filas). Contiene datos personales: nombre, dirección y teléfono. Cada cliente pertenece a un país mediante `c_nationkey`. Modelo de staging: `stg_tpch__customer`.
{% enddocs %}

{% docs fuente_supplier %}
**Proveedores** de piezas (10.000 filas). Contiene datos de contacto: nombre, dirección y teléfono. Modelo de staging: `stg_tpch__supplier`.
{% enddocs %}

{% docs fuente_part %}
**Catálogo de piezas** (200.000 filas): fabricante, marca, tipo, tamaño, envase y precio. Modelo de staging: `stg_tpch__part`.
{% enddocs %}

{% docs fuente_partsupp %}
**Relación entre piezas y proveedores** (800.000 filas), con el stock y el coste de suministro de cada combinación. Cada pieza tiene 4 proveedores. Modelo de staging: `stg_tpch__partsupp`.
{% enddocs %}

{% docs fuente_orders %}
**Cabecera de los pedidos** (1.500.000 filas): cliente, fecha, estado, prioridad e importe total. Su modelo de staging, `stg_tpch__orders`, es incremental por la fecha del pedido (`o_orderdate`).
{% enddocs %}

{% docs fuente_lineitem %}
**Líneas de cada pedido** (6.001.215 filas): pieza, proveedor, cantidad, precio, descuento, impuesto y fechas de envío, compromiso y recepción. Es la tabla más grande del origen. Su modelo de staging, `stg_tpch__lineitem`, es incremental por la fecha de envío (`l_shipdate`).
{% enddocs %}