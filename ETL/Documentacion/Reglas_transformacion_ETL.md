# Reglas de transformación del ETL

Proyecto 01 · TI6900 Inteligencia de Negocios · Grupo 02 · Tema 2: Plataforma de comercio electrónico
Herramienta ETL: **KNIME Analytics Platform** · Origen: PostgreSQL, esquema `public` · Destino: PostgreSQL, esquema `dw`

## Reglas generales

| Código | Tipo | Regla | Nodo KNIME |
|---|---|---|---|
| RG1 | Carga | Carga completa (*full load*): antes de cada ejecución se vacía `dw` con `TRUNCATE ... RESTART IDENTITY` y se recrean los miembros técnicos de llave 0. El ETL se puede ejecutar varias veces sin duplicar datos. | DB SQL Executor |
| RG2 | Limpieza | Se eliminan espacios al inicio y al final de los atributos descriptivos de cliente y producto (`strip`). | String Manipulation (Multi Column) |
| RG3 | Limpieza | Los textos descriptivos nulos se reemplazan por `'No informado'`. | Missing Value |
| RG4 | Llaves | Las llaves subrogadas (`sk_*`) las genera PostgreSQL (`IDENTITY`). El identificador de la fuente se guarda como `id_*_origen` para trazabilidad. | DB Row Inserter |
| RG5 | Llaves | La llave subrogada de cada hecho se obtiene con un *lookup* (Joiner, *left outer join*) contra la dimensión ya cargada, usando la llave natural de la fuente. | Joiner |
| RG6 | Llaves | Si el *lookup* no encuentra pareja (llave natural nula o desconocida), se asigna el miembro técnico `0` (`Sin campaña`, `No aplica`, `No informado`). Ningún registro se descarta. | Missing Value |
| RG7 | Derivación | Las medidas de conteo (`cantidad_pedidos`, `cantidad_envios`, `cantidad_eventos`) se cargan con valor constante 1. | Constant Value Column Appender |
| RG8 | Orden | Primero se cargan las 8 dimensiones y después las 4 tablas de hechos. | Merge Variables + variables de flujo |

## DimTiempo (`dw.dim_tiempo`)

| Campo destino | Campo origen | Regla aplicada | Comentarios |
|---|---|---|---|
| dim_tiempo.sk_tiempo | — | Generada por IDENTITY (RG4). | 0 = “No aplica”. |
| dim_tiempo.fecha | pedido.fecha_pedido, envio.fecha_prevista, envio.fecha_entrega_real, devolucioncancelacion.fecha_evento | Calendario continuo, un día por fila, desde el 1 de enero del año de la fecha mínima hasta el 31 de diciembre del año de la fecha máxima. | 730 días (2025-2026). Un calendario sin huecos permite analizar días sin ventas. |
| dim_tiempo.dia | fecha | Día del mes. | Extract Date&Time Fields. |
| dim_tiempo.nombre_dia | fecha | Nombre del día en español (locale es-ES) con mayúscula inicial. | Ej.: “Miércoles”. |
| dim_tiempo.semana | fecha | Número de semana del año (ISO-8601). | |
| dim_tiempo.mes | fecha | Número de mes (1-12). | |
| dim_tiempo.nombre_mes | fecha | Nombre del mes en español con mayúscula inicial. | Ej.: “Enero”. |
| dim_tiempo.trimestre | fecha | Trimestre calendario (1-4). | |
| dim_tiempo.anio | fecha | Año calendario. | |

## DimCliente (`dw.dim_cliente`)

| Campo destino | Campo origen | Regla aplicada | Comentarios |
|---|---|---|---|
| dim_cliente.sk_cliente | — | IDENTITY (RG4). | 0 = “No informado”. |
| dim_cliente.id_cliente_origen | cliente.id_cliente | Copia directa y cambio de nombre. | Trazabilidad con la fuente. |
| dim_cliente.nombre_cliente | cliente.nombre_cliente | `strip` + mayúscula inicial en cada palabra (`capitalize`), sin alterar el resto de letras. | Homologa 4 nombres con apellidos en minúscula (ej. “Godfree felip” → “Godfree Felip”) sin dañar “McHenry” o “D'Alessandro”. |
| dim_cliente.tipo_cliente | cliente.tipo_cliente | `strip`. | Valores válidos: Nuevo, Recurrente, VIP. |
| dim_cliente.fecha_registro | cliente.fecha_registro | Copia directa (DATE). | El CSV original venía como AAAA/MM/DD; al cargarse en la fuente quedó como DATE. |
| — | cliente.correo_electronico | No se carga. | Dato personal sin valor analítico. |

## DimProducto (`dw.dim_producto`)

| Campo destino | Campo origen | Regla aplicada | Comentarios |
|---|---|---|---|
| dim_producto.sk_producto | — | IDENTITY (RG4). | 0 = “No informado”. |
| dim_producto.id_producto_origen | producto.id_producto | Copia directa y cambio de nombre. | |
| dim_producto.nombre_producto | producto.nombre_producto | `strip`. | Hay 11 nombres repetidos con distinto id; se conservan como productos distintos. |
| dim_producto.nombre_categoria | categoria.nombre_categoria | Join producto.id_categoria = categoria.id_categoria en la extracción; `strip`. | |
| dim_producto.nombre_marca | marca.nombre_marca | Join producto.id_marca = marca.id_marca en la extracción; `strip`. | |

## DimCampania (`dw.dim_campania`)

| Campo destino | Campo origen | Regla aplicada | Comentarios |
|---|---|---|---|
| dim_campania.sk_campania | — | IDENTITY (RG4). | 0 = “Sin campaña”. |
| dim_campania.id_campania_origen | campania.id_campania | Copia directa y cambio de nombre. | |
| dim_campania.nombre_campania | campania.nombre_campania | Homologación ortográfica: “San Valentin” → “San Valentín”, “Dia de la Madre” → “Día de la Madre”, “Dia del Padre” → “Día del Padre”. | Rule Engine. |
| dim_campania.tipo_descuento | campania.tipo_descuento | Copia directa. | Porcentaje / Monto fijo. |
| dim_campania.valor_descuento | campania.valor_descuento | Copia directa. | % o colones según tipo_descuento. |
| dim_campania.fecha_inicio / fecha_fin | campania.fecha_inicio / fecha_fin | Copia directa. | |

## DimContextoPedido (`dw.dim_contexto_pedido`)

| Campo destino | Campo origen | Regla aplicada | Comentarios |
|---|---|---|---|
| dim_contexto_pedido.sk_contexto_pedido | — | IDENTITY (RG4). | |
| dim_contexto_pedido.canal_dispositivo | pedido.canal_dispositivo | Nulo → “No informado”. | 78 pedidos sin canal. |
| dim_contexto_pedido.metodo_pago | pedido.metodo_pago | Nulo → “No informado”. | 64 pedidos sin método de pago. |
| dim_contexto_pedido.estado_pedido | pedido.estado_pedido | Nulo → “No informado”. | |
| (fila completa) | — | Se eliminan duplicados: una fila por combinación única canal + método + estado. | 54 combinaciones. |

## DimOperadorLogistico (`dw.dim_operador_logistico`)

| Campo destino | Campo origen | Regla aplicada | Comentarios |
|---|---|---|---|
| dim_operador_logistico.sk_operador | — | IDENTITY (RG4). | |
| dim_operador_logistico.id_operador_origen | operadorlogistico.id_operador | Copia directa y cambio de nombre. | |
| dim_operador_logistico.nombre_operador | operadorlogistico.nombre_operador | Copia directa. | 4 operadores. |

## DimContextoEnvio (`dw.dim_contexto_envio`)

| Campo destino | Campo origen | Regla aplicada | Comentarios |
|---|---|---|---|
| dim_contexto_envio.sk_contexto_envio | — | IDENTITY (RG4). | |
| dim_contexto_envio.region | envio.region | Nulo → “No informado”. | 68 envíos sin región. |
| dim_contexto_envio.tipo_envio | envio.tipo_envio | Nulo → “No informado”. | 71 envíos sin tipo. |
| (fila completa) | — | Combinaciones únicas; se excluye (“No informado”, “No informado”) porque ya existe como miembro 0. | 23 combinaciones. Los 4 envíos con ambos campos nulos quedan en sk 0. |

## DimMotivoEvento (`dw.dim_motivo_evento`)

| Campo destino | Campo origen | Regla aplicada | Comentarios |
|---|---|---|---|
| dim_motivo_evento.sk_motivo_evento | — | IDENTITY (RG4). | |
| dim_motivo_evento.tipo_evento | devolucioncancelacion.tipo_evento | Copia directa. | Cancelación / Devolución. |
| dim_motivo_evento.motivo | devolucioncancelacion.motivo | Nulo → “No informado”. | 19 eventos sin motivo. Se conserva el tipo de evento, por lo que no se pierde información. |
| (fila completa) | — | Combinaciones únicas tipo + motivo. | 11 combinaciones. |

## FactPedido (`dw.fact_pedido`) · una fila por pedido

| Campo destino | Campo origen | Regla aplicada | Comentarios |
|---|---|---|---|
| fact_pedido.id_pedido | pedido.id_pedido | Copia directa. | Trazabilidad con la fuente. |
| fact_pedido.sk_tiempo_pedido | pedido.fecha_pedido | Lookup en dim_tiempo por fecha (RG5). | |
| fact_pedido.sk_cliente | pedido.id_cliente | Lookup en dim_cliente por id_cliente_origen. | |
| fact_pedido.sk_campania | pedido.id_campania | Lookup en dim_campania; nulo → 0 (RG6). | 1.802 pedidos quedan en “Sin campaña”. |
| fact_pedido.sk_contexto_pedido | pedido.canal_dispositivo + metodo_pago + estado_pedido | Nulos → “No informado” y lookup por los 3 campos. | |
| fact_pedido.cantidad_pedidos | — | Constante 1 (RG7). | |
| fact_pedido.monto_total | pedido.monto_total | Copia directa. | Se valida que coincida con la suma de subtotales del pedido. |

## FactDetalleVenta (`dw.fact_detalle_venta`) · una fila por línea de pedido

| Campo destino | Campo origen | Regla aplicada | Comentarios |
|---|---|---|---|
| fact_detalle_venta.id_detalle | detallepedido.id_detalle | Copia directa. | Trazabilidad con la fuente. |
| fact_detalle_venta.id_pedido | detallepedido.id_pedido | Copia directa. | Trazabilidad con la fuente. |
| fact_detalle_venta.sk_tiempo_pedido | pedido.fecha_pedido | Navegación detallepedido → pedido y lookup en dim_tiempo. | |
| fact_detalle_venta.sk_cliente | pedido.id_cliente | Navegación detallepedido → pedido y lookup. | |
| fact_detalle_venta.sk_campania | pedido.id_campania | Lookup; nulo → 0. | |
| fact_detalle_venta.sk_producto | detallepedido.id_producto | Lookup en dim_producto. | |
| fact_detalle_venta.sk_contexto_pedido | pedido.canal_dispositivo + metodo_pago + estado_pedido | Igual que FactPedido. | |
| fact_detalle_venta.cantidad | detallepedido.cantidad | Copia directa. | |
| fact_detalle_venta.precio_venta_unitario | detallepedido.precio_venta_unitario | Copia directa. | Puede diferir del precio de lista por descuentos. |
| fact_detalle_venta.ingreso_bruto | detallepedido.subtotal | Copia directa y cambio de nombre. | |
| fact_detalle_venta.costo_unitario | producto.costo_unitario | Navegación detallepedido → producto; se copia al hecho. | Conserva el costo vigente al momento de la carga. |
| fact_detalle_venta.costo_total | cantidad, costo_unitario | `cantidad × costo_unitario` (Math Formula). | Nulo si el producto no tiene costo. |
| fact_detalle_venta.margen_bruto | ingreso_bruto, costo_total | `ingreso_bruto − costo_total` (Math Formula). | 137 líneas (6 productos sin costo) quedan con margen nulo; no se imputa un costo inventado. |

## FactEnvio (`dw.fact_envio`) · una fila por envío

| Campo destino | Campo origen | Regla aplicada | Comentarios |
|---|---|---|---|
| fact_envio.id_envio | envio.id_envio | Copia directa. | Trazabilidad con la fuente. |
| fact_envio.id_pedido | envio.id_pedido | Copia directa. | |
| fact_envio.sk_tiempo_pedido | pedido.fecha_pedido | Navegación envio → pedido y lookup (rol fecha de pedido). | |
| fact_envio.sk_tiempo_previsto | envio.fecha_prevista | Lookup (rol fecha prevista). | |
| fact_envio.sk_tiempo_entrega_real | envio.fecha_entrega_real | Lookup (rol fecha real); nulo → 0 “No aplica”. | 234 envíos de pedidos cancelados no tienen entrega. |
| fact_envio.sk_operador | envio.id_operador | Lookup en dim_operador_logistico. | |
| fact_envio.sk_contexto_envio | envio.region + envio.tipo_envio | Nulos → “No informado” y lookup por ambos campos. | 4 envíos quedan en 0. |
| fact_envio.sk_contexto_pedido | pedido.canal_dispositivo + metodo_pago + estado_pedido | Igual que FactPedido. | |
| fact_envio.cantidad_envios | — | Constante 1. | |
| fact_envio.dias_entrega | pedido.fecha_pedido, envio.fecha_entrega_real | Diferencia en días `fecha_entrega_real − fecha_pedido` (Date&Time Difference). | Nulo si no hubo entrega. |
| fact_envio.dias_desviacion | envio.fecha_prevista, envio.fecha_entrega_real | `fecha_entrega_real − fecha_prevista`. | Positivo = atraso; 0 o negativo = a tiempo. |
| fact_envio.entrega_a_tiempo | dias_desviacion | Rule Engine: ≤ 0 → 1; > 0 → 0; sin entrega → nulo. | 1.796 a tiempo, 470 tardíos, 234 no aplica. |

## FactDevolucionCancelacion (`dw.fact_devolucion_cancelacion`) · una fila por evento

| Campo destino | Campo origen | Regla aplicada | Comentarios |
|---|---|---|---|
| fact_devolucion_cancelacion.id_evento | devolucioncancelacion.id_evento | Copia directa. | Trazabilidad con la fuente. |
| fact_devolucion_cancelacion.id_detalle_origen | devolucioncancelacion.id_detalle | Copia directa y cambio de nombre. | |
| fact_devolucion_cancelacion.sk_tiempo_evento | devolucioncancelacion.fecha_evento | Lookup (rol fecha del evento). | |
| fact_devolucion_cancelacion.sk_cliente | pedido.id_cliente | Navegación evento → detallepedido → pedido y lookup. | |
| fact_devolucion_cancelacion.sk_campania | pedido.id_campania | Misma navegación; nulo → 0. | |
| fact_devolucion_cancelacion.sk_producto | detallepedido.id_producto | Navegación evento → detallepedido y lookup. | |
| fact_devolucion_cancelacion.sk_contexto_pedido | pedido.canal_dispositivo + metodo_pago + estado_pedido | Igual que FactPedido. | |
| fact_devolucion_cancelacion.sk_motivo_evento | devolucioncancelacion.tipo_evento + motivo | Motivo nulo → “No informado” y lookup por ambos campos. | |
| fact_devolucion_cancelacion.cantidad_eventos | — | Constante 1. | |
| fact_devolucion_cancelacion.monto_reembolso | devolucioncancelacion.monto_reembolso | Copia directa. | |

## Hallazgos de calidad de datos en la fuente

| Hallazgo | Registros | Tratamiento |
|---|---|---|
| Pedidos sin campaña (id_campania nulo) | 1.802 | Válido por negocio → sk_campania = 0 “Sin campaña”. |
| Pedidos sin canal / sin método de pago | 78 / 64 | “No informado”. |
| Envíos sin región / sin tipo de envío | 68 / 71 | “No informado”; 4 con ambos nulos → sk 0. |
| Envíos sin fecha de entrega real | 234 (todos de pedidos cancelados) | sk_tiempo_entrega_real = 0 y medidas de entrega nulas. |
| Eventos posventa sin motivo | 19 | “No informado”. |
| Productos sin costo unitario | 6 productos / 137 líneas | costo_total y margen_bruto nulos. |
| Nombres de campaña sin tilde | 3 | Homologación ortográfica. |
| Nombres de cliente con palabras en minúscula | 4 | Mayúscula inicial. |
| Integridad referencial, subtotales (cantidad × precio) y monto_total vs suma de líneas | 0 inconsistencias | Verificado en la validación. |
