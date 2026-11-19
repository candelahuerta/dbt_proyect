# Snapshots

Los snapshots guardan el **historial de cambios** de las dimensiones de variación lenta (SCD, *slowly changing dimensions*): datos que cambian de vez en cuando, como el segmento de un cliente o el precio de un producto. Sin ellos, cada recarga de staging sobrescribiría el valor antiguo y se perdería el pasado.

| | |
| --- | --- |
| Esquema | `<esquema>_snapshots` |
| Tipo de historial | SCD tipo 2: cuando un registro cambia, se cierra la versión antigua y se añade una nueva |
| Estrategia | `check`: se comparan las columnas vigiladas, porque TPC-H no tiene columna de fecha de modificación |
| Definición | `snapshots/snapshots.yml` |
| Ejecución | Job `01 - Diario staging`, con `tag:snapshots`, después de cargar staging |
| Acceso | `ROL_ANALISTA` |
| Etiquetas | `snapshots` |

**Columnas que añade dbt a cada versión:**

| Columna | Significado |
| --- | --- |
| `dbt_scd_id` | Identificador único de la versión |
| `dbt_updated_at` | Momento en que dbt registró la versión |
| `dbt_valid_from` | Inicio de validez de la versión |
| `dbt_valid_to` | Fin de validez. Vacío en la versión actual |

**Decisiones de diseño:**

- **Solo se hace snapshot de lo que puede cambiar.** Clientes, productos y proveedores sí; `dim_fecha` no, porque es un calendario generado que nunca cambia.
- **El saldo no se vigila.** El saldo de clientes y proveedores cambia a diario, con cada pago o factura, así que no es una dimensión de variación lenta sino rápida. Vigilarlo crearía una versión nueva casi cada día por registro y el snapshot crecería con cambios que no aportan al análisis. Los atributos que cambian a diario se tratan como hechos, no como historial de la dimensión.
- **Uso del historial:** `snp_clientes` alimenta `dim_cliente_historico`, que permite analizar las ventas con los atributos que tenía el cliente en el momento de la compra.
- **Espacio:** el snapshot solo crece con los cambios reales. En producción, `snp_clientes` ocupa unos 14,6 MB con 150.000 filas, un 40 % más que staging por las columnas de control.

{% docs snp_clientes %}
**Historial de cambios de los clientes** (SCD tipo 2).

- **Lee de:** `stg_tpch__customer`
- **Clave:** `id_cliente`
- **Columnas vigiladas:** nombre, dirección, teléfono y segmento de mercado
- **No vigila:** el saldo, porque cambia a diario
- **Datos personales:** nombre, dirección y teléfono
- **Se usa en:** `dim_cliente_historico`
- **Tests:** identificador de versión único y no nulo; cliente no nulo
- **Demostración realizada:** se simuló que el cliente 1 pasaba de BUILDING a MACHINERY; el snapshot cerró la versión antigua y abrió la nueva.
{% enddocs %}

{% docs snp_productos %}
**Historial de cambios del catálogo de productos** (SCD tipo 2).

- **Lee de:** `stg_tpch__part`
- **Clave:** `id_pieza`
- **Columnas vigiladas:** nombre, marca, tipo, tamaño, envase y precio de venta al público
- **Tests:** identificador de versión único y no nulo; pieza no nula
{% enddocs %}

{% docs snp_proveedores %}
**Historial de cambios de los proveedores** (SCD tipo 2).

- **Lee de:** `stg_tpch__supplier`
- **Clave:** `id_proveedor`
- **Columnas vigiladas:** nombre, dirección y teléfono
- **No vigila:** el saldo, porque cambia a diario
- **Tests:** identificador de versión único y no nulo; proveedor no nulo
{% enddocs %}