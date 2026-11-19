{% docs sk_cliente %}
Clave subrogada del cliente. Hash MD5 del identificador de origen (`id_cliente`), generado con la macro `generar_clave_subrogada`. Es la clave primaria de `dim_cliente` y la clave foránea de `fct_ventas` hacia esa dimensión.
{% enddocs %}

{% docs sk_proveedor %}
Clave subrogada del proveedor. Hash MD5 de `id_proveedor`, generado con la macro `generar_clave_subrogada`. Clave primaria de `dim_proveedor` y clave foránea en `fct_ventas`.
{% enddocs %}

{% docs sk_producto %}
Clave subrogada del producto. Hash MD5 de `id_pieza`, generado con la macro `generar_clave_subrogada`. Clave primaria de `dim_producto` y clave foránea en `fct_ventas`.
{% enddocs %}

{% docs sk_fecha %}
Clave de fecha en formato numérico AAAAMMDD (por ejemplo, 19950315), generada con la macro `clave_fecha`. Clave primaria de `dim_fecha`. La tabla de hechos la usa en tres papeles: fecha de pedido, de envío y de recepción (dimensión de rol).
{% enddocs %}

{% docs importe_neto %}
Importe que paga el cliente tras aplicar el descuento: precio bruto × (1 − descuento), redondeado a 2 decimales. Es la medida principal de ventas del proyecto.
{% enddocs %}

{% docs margen %}
Beneficio de la línea: importe neto menos coste total (cantidad × coste de suministro). Puede ser negativo cuando la empresa vende por debajo de coste.
{% enddocs %}

{% docs fecha_carga %}
Momento en que la fila se cargó en el almacén. No procede del origen: la añade dbt para trazar las cargas incrementales.
{% enddocs %}