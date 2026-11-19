# Capa reporting

Capa añadida por encima del enunciado. La estrella es muy flexible, pero para usarla hay que saber hacer joins y agregaciones. Reporting ofrece **resúmenes ya preparados para cada departamento**, listos para conectar a un dashboard o para que alguien sin conocimientos de SQL los consulte directamente. Solo lee de la capa business.

| | |
| --- | --- |
| Esquema | `<esquema>_reporting` |
| Materialización | Vista (consultas ligeras sobre la estrella, siempre al día) |
| Carga | Total |
| Propietario | Unidades de negocio |
| Acceso | `ROL_ANALISTA` y `ROL_NEGOCIO` |
| Etiquetas | `reporting` (modelos), `tests_reporting` (tests) |

Los porcentajes se calculan con la macro `calcular_porcentaje`, que evita el error de dividir entre cero y redondea siempre igual.

{% docs rpt_ventas_mensuales_region %}
**Informe para el área Comercial:** evolución mensual de ventas, margen, pedidos y clientes en cada región.

- **Lee de:** `fct_ventas`, `dim_cliente`, `dim_fecha`
- **Granularidad:** una fila por región y mes (400 filas: 5 regiones × 80 meses, de enero de 1992 a agosto de 1998)
- **Medidas:** pedidos, clientes, unidades, ventas netas, margen y porcentaje de margen
- **Tests:** región y año informados; mes entre 1 y 12; las ventas totales cuadran con la tabla de hechos (test propio singular)
- **Dominio:** ventas
{% enddocs %}

{% docs rpt_rendimiento_proveedores %}
**Informe para Compras y Logística:** ventas, margen y puntualidad de cada proveedor.

- **Lee de:** `fct_ventas`, `dim_proveedor`
- **Granularidad:** una fila por proveedor (10.000)
- **Medidas:** líneas y unidades suministradas, ventas netas, margen, porcentaje de margen, días de tránsito medio y porcentaje de entregas con retraso
- **Tests:** proveedor único y no nulo; porcentaje de retrasos entre 0 y 100 (test propio `porcentaje_valido`); las ventas totales cuadran con la tabla de hechos
{% enddocs %}

{% docs rpt_ventas_por_marca %}
**Informe para el área de Producto:** ventas, margen y devoluciones por fabricante y marca.

- **Lee de:** `fct_ventas`, `dim_producto`
- **Granularidad:** una fila por marca (25)
- **Medidas:** productos vendidos, unidades, ventas netas, margen, porcentaje de margen y porcentaje de líneas devueltas
- **Tests:** marca única y no nula; porcentaje de devoluciones entre 0 y 100 (test propio `porcentaje_valido`); las ventas totales cuadran con la tabla de hechos
- **Dominio:** productos
- **Nota:** el porcentaje de margen no lleva el test `porcentaje_valido` porque puede ser negativo legítimamente, cuando se vende por debajo de coste.
{% enddocs %}