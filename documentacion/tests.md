# Tests

El proyecto comprueba automáticamente la calidad de los datos en todas las capas. Un test es una consulta que **busca errores**: si devuelve cero filas, pasa; si devuelve alguna, esas filas son los errores.

## Tipos de test

| Tipo | Qué es | Dónde se definen | Ejemplos |
| --- | --- | --- | --- |
| Genéricos de dbt | Incluidos en dbt | En el `.yml` de cada capa, debajo de cada columna | `unique`, `not_null`, `relationships`, `accepted_values` |
| De paquetes | Ya hechos por la comunidad | En el `.yml`, con el nombre del paquete delante | `dbt_utils.unique_combination_of_columns`, `dbt_utils.accepted_range`, `dbt_expectations.expect_column_pair_values_A_to_be_greater_than_B` |
| Genéricos propios | Plantillas reutilizables escritas por el equipo | `tests/generic/` | `fecha_en_rango`, `no_negativo`, `porcentaje_valido` |
| Singulares propios | Una consulta SQL para una regla concreta | `tests/<capa>/` | Cuadres entre capas, alerta de margen negativo |

**Criterio:** se usan paquetes para las comprobaciones estándar, porque están probados y no tiene sentido reinventarlos, y tests propios para las reglas específicas de este negocio.

**Severidad:** casi todos los tests son de tipo error: si fallan, detienen la carga para que el error no llegue a los informes. La alerta de margen negativo es un aviso (`warn`): vender con pérdidas es posible, pero negocio debe saberlo.

## Paquetes de prueba

Los tests se agrupan en paquetes que se ejecutan con un solo comando, `dbt test --selector <paquete>`. Están definidos en `selectors.yml`.

| Paquete | Qué incluye |
| --- | --- |
| `pruebas_staging` | Todos los tests de staging (etiqueta `tests_staging`) |
| `pruebas_intermediate` | Todos los tests de intermediate (etiqueta `tests_intermediate`) |
| `pruebas_business` | Todos los tests de business (etiqueta `tests_business`) |
| `pruebas_reporting` | Todos los tests de reporting (etiqueta `tests_reporting`) |
| `pruebas_clientes` | Dominio de clientes en todas las capas |
| `pruebas_productos` | Dominio de productos en todas las capas |
| `pruebas_ventas` | Dominio de ventas: comprueba que las cifras de ventas son fiables |
| `pruebas_fechas` | Calendario, fechas de las cargas incrementales y coherencia de fechas logísticas |
| `pruebas_personalizadas` | Solo los tests escritos por el equipo |

Las etiquetas por capa se asignan por carpeta en `dbt_project.yml`; las de dominio, en los modelos (y en algún test concreto, en el caso de las fechas).

## Tests propios

| Test | Tipo | Capa | Comprueba |
| --- | --- | --- | --- |
| `fecha_en_rango` | Genérico | Staging | Fechas entre 1992 y 1998 |
| `no_negativo` | Genérico | Staging | Precios, costes y stock nunca negativos |
| `assert_todos_los_pedidos_tienen_lineas` | Singular | Staging | Ningún pedido sin líneas |
| `assert_fechas_logisticas_coherentes` | Singular | Intermediate | Envío después del pedido y recepción después del envío |
| `assert_pedidos_agregados_cuadran_con_lineas` | Singular | Intermediate | El cambio de granularidad no pierde ni duplica nada |
| `assert_ventas_cuadran_con_origen` | Singular | Business | Las ventas de la estrella coinciden con las del origen |
| `assert_alerta_margen_negativo` | Singular (aviso) | Business | Ventas con pérdidas |
| `assert_una_version_actual_por_cliente` | Singular | Business | Un cliente no tiene dos versiones vigentes |
| `porcentaje_valido` | Genérico | Reporting | Porcentajes entre 0 y 100 |
| `assert_informes_cuadran_con_hechos` | Singular | Reporting | Los informes suman lo mismo que la tabla de hechos |

{% docs test_fecha_en_rango %}
**Test genérico propio.** Comprueba que una columna de fecha está entre una fecha mínima y una máxima. Parámetros: `fecha_minima` y `fecha_maxima`. Se aplica a las fechas de pedido, envío y recepción de staging con el rango del dataset (1992-01-01 a 1998-12-31). Una fecha fuera de ese rango indicaría un error de carga y, además, rompería el filtro de las cargas incrementales.
{% enddocs %}

{% docs test_no_negativo %}
**Test genérico propio.** Comprueba que una columna numérica nunca tiene valores negativos. Se aplica al precio bruto de las líneas y al stock y al coste de suministro de `partsupp`.
{% enddocs %}

{% docs test_porcentaje_valido %}
**Test genérico propio.** Comprueba que un porcentaje está entre 0 y 100. Se aplica al porcentaje de entregas con retraso y al de líneas devueltas. No se aplica al porcentaje de margen, porque puede ser negativo legítimamente.
{% enddocs %}

{% docs assert_todos_los_pedidos_tienen_lineas %}
**Regla de negocio:** no puede existir un pedido sin ninguna línea. Une los pedidos con sus líneas con un `left join` y devuelve los pedidos que no encuentran ninguna.
{% enddocs %}

{% docs assert_fechas_logisticas_coherentes %}
**Regla de negocio:** un pedido no se envía antes de pedirse ni se recibe antes de enviarse. Devuelve las líneas que incumplen cualquiera de las dos condiciones.
{% enddocs %}

{% docs assert_pedidos_agregados_cuadran_con_lineas %}
**Regla técnica:** al cambiar de granularidad, de líneas a pedidos, no se pierde ni se duplica nada. Compara el número de líneas y el importe neto total del detalle con los de la tabla agregada, con una tolerancia de 1 € por redondeos.
{% enddocs %}

{% docs assert_ventas_cuadran_con_origen %}
**Regla de negocio:** las ventas de la tabla de hechos coinciden con las calculadas directamente desde staging. Compara el número de filas y el importe neto total, con una tolerancia de 1 €. Garantiza que entre el origen y la estrella no se ha perdido ni alterado ninguna venta.
{% enddocs %}

{% docs assert_alerta_margen_negativo %}
**Alerta de negocio (severidad `warn`):** ventas en las que la empresa pierde dinero, es decir, con margen negativo. No es un error de datos, por eso avisa sin detener la carga.
{% enddocs %}

{% docs assert_una_version_actual_por_cliente %}
**Regla de negocio de la dimensión histórica:** un cliente no puede tener más de una versión vigente a la vez. Si la tuviera, al cruzar con las ventas se duplicarían.
{% enddocs %}

{% docs assert_informes_cuadran_con_hechos %}
**Regla de negocio:** los tres informes de reporting suman las mismas ventas que la tabla de hechos, porque son los mismos datos agrupados de otra forma. La tolerancia es de 100 €, porque cada fila de los informes se redondea a céntimos y con 10.000 proveedores esos redondeos se acumulan.
{% enddocs %}