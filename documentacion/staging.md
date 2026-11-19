# Capa staging

Primera capa del proyecto. Contiene una copia limpia de cada una de las 8 tablas del dataset TPC-H (`SNOWFLAKE_SAMPLE_DATA.TPCH_SF1`), con los nombres de columna traducidos a nombres claros en castellano. No combina tablas ni calcula nada: su objetivo es leer el sistema origen una sola vez y de forma rápida, para no cargarlo.

| | |
| --- | --- |
| Esquema | `<esquema>_staging` |
| Materialización | Tabla |
| Carga | Total en 6 modelos; incremental en `orders` y `lineitem` |
| Propietario | Equipo de ingeniería de datos |
| Acceso | `ROL_ANALISTA` |
| Etiquetas | `staging` (modelos), `tests_staging` (tests) |

Las fichas de cada modelo están en los bloques de documentación de abajo. dbt las enlaza desde `_stg_tpch__models.yml`.

{% docs stg_tpch__region %}
**Regiones geográficas** en las que opera la empresa (5 filas: AFRICA, AMERICA, ASIA, EUROPE y MIDDLE EAST).

- **Origen:** `TPCH_SF1.REGION`
- **Granularidad:** una fila por región
- **Carga:** total
- **Clave:** `id_region`
- **Tests:** clave única y no nula
{% enddocs %}

{% docs stg_tpch__nation %}
**Países** (25 filas) y la región a la que pertenece cada uno.

- **Origen:** `TPCH_SF1.NATION`
- **Granularidad:** una fila por país
- **Carga:** total
- **Clave:** `id_nacion`
- **Relaciones:** `id_region` → `stg_tpch__region`
- **Tests:** clave única y no nula; integridad referencial con las regiones
{% enddocs %}

{% docs stg_tpch__customer %}
**Clientes** de la empresa (150.000 filas).

- **Origen:** `TPCH_SF1.CUSTOMER`
- **Granularidad:** una fila por cliente
- **Carga:** total
- **Clave:** `id_cliente`
- **Relaciones:** `id_nacion` → `stg_tpch__nation`
- **Datos personales:** nombre, dirección y teléfono (marcados con `pii: true`)
- **Tests:** clave única y no nula; integridad referencial con los países; segmento dentro de los 5 valores permitidos
- **Dominio:** clientes
{% enddocs %}

{% docs stg_tpch__supplier %}
**Proveedores** que suministran las piezas (10.000 filas).

- **Origen:** `TPCH_SF1.SUPPLIER`
- **Granularidad:** una fila por proveedor
- **Carga:** total
- **Clave:** `id_proveedor`
- **Relaciones:** `id_nacion` → `stg_tpch__nation`
- **Datos de contacto:** nombre, dirección y teléfono (marcados con `pii: true`)
- **Tests:** clave única y no nula; integridad referencial con los países
{% enddocs %}

{% docs stg_tpch__part %}
**Catálogo de piezas** (productos) que vende la empresa (200.000 filas).

- **Origen:** `TPCH_SF1.PART`
- **Granularidad:** una fila por pieza
- **Carga:** total
- **Clave:** `id_pieza`
- **Tests:** clave única y no nula
- **Dominio:** productos
{% enddocs %}

{% docs stg_tpch__partsupp %}
**Qué proveedores suministran cada pieza**, con su stock y su coste (800.000 filas). Cada pieza tiene 4 proveedores.

- **Origen:** `TPCH_SF1.PARTSUPP`
- **Granularidad:** una fila por combinación de pieza y proveedor
- **Carga:** total
- **Clave compuesta:** `id_pieza` + `id_proveedor`
- **Relaciones:** `id_pieza` → `stg_tpch__part`; `id_proveedor` → `stg_tpch__supplier`
- **Tests:** combinación única de pieza y proveedor (`dbt_utils`); integridad referencial; stock y coste nunca negativos (test propio `no_negativo`)
- **Dominio:** productos
{% enddocs %}

{% docs stg_tpch__orders %}
**Cabecera de los pedidos**: cliente, fecha, estado e importe total (1.500.000 filas).

- **Origen:** `TPCH_SF1.ORDERS`
- **Granularidad:** una fila por pedido
- **Carga:** **incremental** con estrategia `merge`. En cada ejecución solo se leen los pedidos con fecha igual o posterior a la más reciente ya cargada. Se usa `>=` para volver a procesar el último día por si llegaron datos tarde; el `merge` evita duplicados.
- **Clave:** `id_pedido`
- **Relaciones:** `id_cliente` → `stg_tpch__customer`
- **Columna de control:** `fecha_carga`, añadida por dbt para saber cuándo se cargó cada fila
- **Tests:** clave única y no nula; integridad referencial con los clientes; estado y prioridad dentro de los valores permitidos; fecha de pedido no nula y entre 1992 y 1998 (test propio `fecha_en_rango`)
- **Dominio:** ventas y fechas
{% enddocs %}

{% docs stg_tpch__lineitem %}
**Líneas de cada pedido**: pieza, proveedor, cantidad, precio, descuento, impuesto y fechas logísticas (6.001.215 filas). Es la tabla más grande del origen.

- **Origen:** `TPCH_SF1.LINEITEM`
- **Granularidad:** una fila por línea de pedido
- **Carga:** **incremental** con estrategia `merge`, por fecha de envío, con el mismo criterio que `stg_tpch__orders`
- **Clave compuesta:** `id_pedido` + `numero_linea`
- **Relaciones:** `id_pedido` → `stg_tpch__orders`
- **Columna de control:** `fecha_carga`
- **Reglas de negocio comprobadas:**
  - Cantidad entre 1 y 50; descuento entre 0 % y 10 %; impuesto entre 0 % y 8 % (`dbt_utils.accepted_range`)
  - Fecha de recepción igual o posterior a la de envío (`dbt_expectations`)
  - Fechas de envío y recepción entre 1992 y 1998 (test propio `fecha_en_rango`)
  - Precio bruto nunca negativo (test propio `no_negativo`)
- **Dominio:** ventas y fechas
{% enddocs %}