# Capa business

Corazón del proyecto: el **modelo en estrella** que consumen las unidades de negocio. Una tabla de hechos en el centro (`fct_ventas`) y cuatro dimensiones alrededor (cliente, proveedor, producto y fecha), más una dimensión histórica de clientes construida a partir del snapshot.

| | |
| --- | --- |
| Esquema | `<esquema>_business` |
| Carpeta en dbt | `models/marts` |
| Materialización | Tabla (es lo que más se consulta, así responde más rápido) |
| Carga | Total |
| Propietario | Equipo de analítica |
| Acceso | `ROL_ANALISTA` y `ROL_NEGOCIO` |
| Etiquetas | `business` (modelos), `tests_business` (tests) |

**Decisiones de diseño de la estrella:**

- **Granularidad de los hechos:** una fila por línea de pedido, el nivel más detallado. Desde ahí se puede agregar a pedido, cliente o mes; si fuera el pedido, se perderían el producto y el proveedor.
- **Claves subrogadas (`sk_`):** las dimensiones se unen a los hechos con un hash generado por la macro `generar_clave_subrogada`, no con los identificadores del origen. Así el modelo no depende de cómo numere el sistema origen. Se conserva también el identificador original para rastrear cada dato.
- **Dimensión de rol:** las tres fechas de la tabla de hechos (pedido, envío y recepción) apuntan a la misma `dim_fecha`.
- **Dimensiones degeneradas:** datos del pedido como su número o el modo de envío se quedan en la tabla de hechos porque no justifican una dimensión propia.
- **Desnormalización:** las dimensiones incluyen ya el país y la región, para filtrar sin joins adicionales.

{% docs dim_cliente %}
**Dimensión de clientes** con su estado actual.

- **Lee de:** `int_clientes_enriquecidos`
- **Granularidad:** una fila por cliente (150.000)
- **Clave primaria:** `sk_cliente` (clave subrogada); clave natural `id_cliente`
- **Atributos:** datos de contacto, segmento de mercado, saldo y su situación, país y región
- **Datos personales:** nombre, dirección y teléfono. Nota de gobierno: esta tabla es accesible para `ROL_NEGOCIO`, que no necesita estos datos; la mejora sería ocultarlos con una política de enmascaramiento.
- **Tests:** clave subrogada y clave natural únicas y no nulas; región siempre informada
- **Dominio:** clientes
{% enddocs %}

{% docs dim_proveedor %}
**Dimensión de proveedores.**

- **Lee de:** `int_proveedores_enriquecidos`
- **Granularidad:** una fila por proveedor (10.000)
- **Clave primaria:** `sk_proveedor`; clave natural `id_proveedor`
- **Atributos:** datos de contacto, saldo y su situación, país y región
- **Tests:** clave subrogada y clave natural únicas y no nulas
{% enddocs %}

{% docs dim_producto %}
**Dimensión de productos** (piezas), con el resumen de sus proveedores.

- **Lee de:** `int_piezas_enriquecidas`
- **Granularidad:** una fila por pieza (200.000)
- **Clave primaria:** `sk_producto`; clave natural `id_pieza`
- **Atributos:** fabricante, marca, tipo, tamaño, envase, precio, número de proveedores, stock y costes
- **Tests:** clave subrogada y clave natural únicas y no nulas
- **Dominio:** productos
{% enddocs %}

{% docs dim_fecha %}
**Dimensión de calendario**, con un día por fila de 1992-01-01 a 1998-12-31 (2.557 días).

- **Origen:** no procede del sistema origen; se genera en dbt con la función `generator` de Snowflake
- **Clave primaria:** `sk_fecha`, número con formato AAAAMMDD generado por la macro `clave_fecha`
- **Atributos:** año, trimestre, mes y día con sus nombres en castellano, día de la semana (estándar ISO: lunes = 1) y si es fin de semana
- **Dimensión de rol:** la tabla de hechos la usa como fecha de pedido, de envío y de recepción
- **Por qué no lleva snapshot:** es un calendario que nunca cambia
- **Tests:** clave y fecha únicas y no nulas; trimestre entre 1 y 4
- **Dominio:** fechas
{% enddocs %}

{% docs fct_ventas %}
**Tabla de hechos de ventas**, centro del modelo en estrella.

- **Lee de:** `int_lineas_pedido_enriquecidas`
- **Granularidad:** una fila por línea de pedido (6.001.215)
- **Clave primaria:** `sk_venta` (hash de pedido + número de línea)
- **Claves foráneas:** `sk_cliente`, `sk_proveedor`, `sk_producto`, `sk_fecha_pedido`, `sk_fecha_envio`, `sk_fecha_recepcion`
- **Dimensiones degeneradas:** número de pedido y de línea, estado, prioridad, modo de envío, indicador de devolución y estado de la línea
- **Medidas:**
  - Aditivas (se pueden sumar): cantidad, precio bruto, importe neto, importe con impuestos, coste total y margen
  - No aditivas (se promedian): descuento, impuesto y días de entrega
- **Tests:**
  - Clave de venta única y no nula
  - Integridad referencial con las cuatro dimensiones, incluidas las tres fechas (las claves de la estrella siempre encuentran su pareja)
  - Las ventas cuadran con las del origen en número de filas e importe (test propio singular)
  - Alerta, sin bloquear, de las ventas con margen negativo (test propio singular con `severity: warn`)
- **Dominio:** ventas
{% enddocs %}

{% docs dim_cliente_historico %}
**Dimensión histórica de clientes (SCD tipo 2)**, con una fila por cada versión de cada cliente y su periodo de validez.

- **Lee de:** el snapshot `snp_clientes`
- **Granularidad:** una fila por versión de cliente
- **Clave primaria:** `sk_cliente_version` (hash de cliente + inicio de validez); `sk_cliente` es común a todas las versiones y se cruza con `fct_ventas`
- **Para qué sirve:** analizar las ventas con los atributos que tenía el cliente **en el momento de la compra**, no los de hoy. Se cruza con los hechos por `sk_cliente` y exigiendo que la fecha de la venta caiga entre `valido_desde` y `valido_hasta`.
- **Decisiones de diseño:**
  - La primera versión es válida desde 1900, porque el snapshot empezó en 2026 y las ventas son de 1992 a 1998
  - La versión actual es válida hasta 9999-12-31, para que los cruces por rango de fechas funcionen
- **Espacio:** ocupa algo más que el snapshot (unos 15,3 MB frente a 14,6 MB en producción), porque añade dos claves y las columnas de validez
- **Tests:** clave de versión única y no nula; integridad referencial con `dim_cliente`; un cliente solo puede tener una versión vigente (test propio singular)
- **Dominio:** clientes
{% enddocs %}