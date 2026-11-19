# Macros

Una macro es una función reutilizable escrita en Jinja, el lenguaje de plantillas de dbt. Se escribe una vez en la carpeta `macros` y se usa en muchos modelos. Si hay que cambiar una fórmula, se cambia en un solo sitio y todos los modelos la heredan.

| Macro | Para qué sirve | Dónde se usa |
| --- | --- | --- |
| `generar_clave_subrogada` | Genera una clave hash única a partir de una o varias columnas | Las dimensiones, `fct_ventas` y `dim_cliente_historico` |
| `clave_fecha` | Convierte una fecha en un número AAAAMMDD | `dim_fecha` y las tres fechas de `fct_ventas` |
| `calcular_porcentaje` | Calcula un porcentaje sin fallar si el denominador es cero | Los tres informes de reporting |

**Por qué son importantes en este proyecto:** las claves de la estrella se generan con la misma macro en la dimensión y en la tabla de hechos. Si la fórmula fuera distinta en un lado, las claves no coincidirían y la estrella no se podría unir. La macro garantiza que siempre se calculan igual.

Para ver el SQL que genera una macro, se abre un modelo que la use y se pulsa **Compile**: en lugar de la llamada aparece la fórmula ya escrita.

Los tests genéricos propios (`fecha_en_rango`, `no_negativo` y `porcentaje_valido`) también son, por dentro, un tipo especial de macro. Están documentados en `tests.md`.

{% docs macro_generar_clave_subrogada %}
Genera una **clave subrogada**: un hash MD5 único calculado a partir de una lista de columnas.

**Cómo funciona:**

1. Convierte cada columna a texto.
2. Sustituye los valores nulos por `'_nulo_'`, porque si una columna fuera nula el hash entero saldría nulo.
3. Une las columnas con una barra vertical (`|`), para que, por ejemplo, las columnas `1` y `23` no den el mismo resultado que `12` y `3`.
4. Calcula el hash con `md5`.

**Ejemplos de uso:**

- Con una columna: `{{ generar_clave_subrogada(['id_cliente']) }}`
- Con varias columnas: `{{ generar_clave_subrogada(['id_pedido', 'numero_linea']) }}`
{% enddocs %}

{% docs macro_clave_fecha %}
Convierte una columna de fecha en un **número con formato AAAAMMDD**, por ejemplo `1995-03-15` en `19950315`.

Es la clave de `dim_fecha`. Se usa también en `fct_ventas` para las fechas de pedido, envío y recepción, de modo que las claves coinciden siempre con las de la dimensión.

**Ejemplo de uso:** `{{ clave_fecha('fecha_pedido') }}`. El nombre de la columna va entre comillas simples, porque se le pasa el texto que la macro coloca en la fórmula.
{% enddocs %}

{% docs macro_calcular_porcentaje %}
Calcula un **porcentaje** (numerador ÷ denominador × 100) redondeado, **sin fallar si el denominador es cero**.

Usa `nullif(denominador, 0)`: si el denominador vale cero, lo convierte en nulo, y en SQL dividir entre nulo da nulo en lugar de un error.

Tiene un parámetro opcional, `decimales`, que por defecto vale 2.

**Ejemplo de uso:** `{{ calcular_porcentaje('sum(ventas.margen)', 'sum(ventas.importe_neto)') }}`
{% enddocs %}