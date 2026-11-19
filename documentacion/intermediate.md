# Capa intermediate

Segunda capa del proyecto. Combina las tablas de staging y prepara las piezas con las que se construye el modelo en estrella. Cubre los tres tipos de transformación del enunciado:

- **Combinación de entidades:** clientes y proveedores con su país y su región; líneas de pedido con su pedido y su coste.
- **Campos calculados:** situación del saldo, importe neto, importe con impuestos, coste, margen, días de entrega y retrasos.
- **Cambio de granularidad:** de líneas a pedidos, y de pieza-proveedor a pieza.

| | |
| --- | --- |
| Esquema | `<esquema>_intermediate` |
| Materialización | Vista (no ocupa espacio y siempre refleja lo último de staging) |
| Carga | Total (una vista siempre se calcula entera) |
| Propietario | Equipo de ingeniería de datos |
| Acceso | `ROL_ANALISTA` |
| Etiquetas | `intermediate` (modelos), `tests_intermediate` (tests) |

{% docs int_clientes_enriquecidos %}
**Clientes con su país y su región**, y una clasificación nueva según su saldo. Es la base de `dim_cliente`.

- **Lee de:** `stg_tpch__customer`, `stg_tpch__nation`, `stg_tpch__region`
- **Transformación:** combinación de entidades (dos `left join`, para no perder ningún cliente aunque le faltara el país) y campo calculado
- **Granularidad:** una fila por cliente (150.000)
- **Campo calculado:** `situacion_saldo` = Deudor si el saldo es negativo; Solvente en caso contrario, incluido el saldo cero
- **Datos personales:** nombre, dirección y teléfono
- **Tests:** cliente único y no nulo; región siempre informada (prueba que los joins funcionan); `situacion_saldo` solo admite Deudor o Solvente
- **Dominio:** clientes
{% enddocs %}

{% docs int_proveedores_enriquecidos %}
**Proveedores con su país y su región**, y la misma clasificación según su saldo. Es la base de `dim_proveedor`.

- **Lee de:** `stg_tpch__supplier`, `stg_tpch__nation`, `stg_tpch__region`
- **Transformación:** combinación de entidades y campo calculado
- **Granularidad:** una fila por proveedor (10.000)
- **Datos de contacto:** nombre, dirección y teléfono
- **Tests:** proveedor único y no nulo; región siempre informada; `situacion_saldo` solo admite Deudor o Solvente
{% enddocs %}

{% docs int_lineas_pedido_enriquecidas %}
**Cada línea de pedido con los datos de su pedido, el coste de su proveedor y las métricas de negocio calculadas.** Es la base de `fct_ventas` y el modelo más importante de la capa.

- **Lee de:** `stg_tpch__lineitem`, `stg_tpch__orders`, `stg_tpch__partsupp`
- **Transformación:** combinación de entidades y campos calculados
- **Granularidad:** una fila por línea de pedido (6.001.215, las mismas que en staging: los joins no duplican nada)
- **Join con el coste:** se hace por dos columnas (pieza + proveedor), porque la misma pieza cuesta distinto según quién la suministre
- **Métricas calculadas:**

| Métrica | Fórmula |
| --- | --- |
| `importe_neto` | precio bruto × (1 − descuento) |
| `importe_con_impuestos` | importe neto × (1 + impuesto) |
| `coste_total` | cantidad × coste de suministro |
| `margen` | importe neto − coste total |
| `dias_hasta_envio` | días entre pedido y envío |
| `dias_de_transito` | días entre envío y recepción |
| `entregado_con_retraso` | recepción posterior a la fecha comprometida |

- **Tests:** pedido y cliente no nulos; coste siempre informado (si fuera nulo, el join con partsupp habría fallado); combinación única de pedido y línea; fechas logísticas coherentes (test propio singular)
- **Dominio:** ventas
{% enddocs %}

{% docs int_pedidos_agregados %}
**Un resumen por pedido de todas sus líneas.** Cambia la granularidad de línea a pedido para responder preguntas como "¿cuál es el importe medio de un pedido?".

- **Lee de:** `int_lineas_pedido_enriquecidas` (reutiliza sus cálculos en lugar de repetirlos)
- **Transformación:** cambio de granularidad con `group by`
- **Granularidad:** una fila por pedido (1.500.000)
- **Medidas:** número de líneas, unidades, importe neto, importe con impuestos, margen, descuento medio y líneas con retraso
- **Tests:** pedido único y no nulo; número de líneas informado; los totales cuadran con el detalle de líneas (test propio singular)
- **Dominio:** ventas
{% enddocs %}

{% docs int_piezas_enriquecidas %}
**Cada pieza con los datos del catálogo y el resumen de sus proveedores.** Es la base de `dim_producto`.

- **Lee de:** `stg_tpch__part`, `stg_tpch__partsupp`
- **Transformación:** cambio de granularidad (de pieza-proveedor a pieza) y combinación de entidades
- **Granularidad:** una fila por pieza (200.000)
- **Decisión de diseño:** primero se agrupa `partsupp` por pieza y después se une con el catálogo. Si se uniera antes de agrupar, cada pieza saldría repetida 4 veces, una por proveedor.
- **Medidas:** número de proveedores, stock total y coste de suministro medio, mínimo y máximo
- **Tests:** pieza única y no nula; número de proveedores informado
- **Dominio:** productos
{% enddocs %}