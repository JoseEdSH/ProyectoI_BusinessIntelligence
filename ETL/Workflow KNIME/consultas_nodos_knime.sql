-- ============================================================
-- PROYECTO 01 - TI6900 Inteligencia de Negocios
-- Grupo 02 - Tema 2: Plataforma de comercio electrónico
-- ETL en KNIME
--
-- Consultas que se copian dentro de los nodos "DB Query Reader" del
-- workflow ETL_Ecommerce_Grupo02.knwf. Cada bloque indica el nodo exacto.
--
--   E = Extracción desde la fuente transaccional (esquema public)
--   L = Lookup de llaves subrogadas desde el Data Warehouse (esquema dw)
--
-- Las consultas E solo seleccionan y navegan relaciones de la fuente
-- (llaves foráneas). La limpieza, homologación, derivación y asignación de
-- llaves subrogadas se realiza con nodos de KNIME (ver GUIA_ETL_KNIME.md).
-- ============================================================


-- ============================================================
-- E. EXTRACCIÓN (fuente transaccional)
-- ============================================================

-- [E01] DimTiempo - calendario continuo que cubre todas las fechas de la fuente
--       (desde el 1 de enero del primer año hasta el 31 de diciembre del último).
WITH fechas AS (
    SELECT fecha_pedido       AS fecha FROM public.pedido
    UNION
    SELECT fecha_prevista              FROM public.envio
    UNION
    SELECT fecha_entrega_real          FROM public.envio
    UNION
    SELECT fecha_evento                FROM public.devolucioncancelacion
),
rango AS (
    SELECT CAST(date_trunc('year', MIN(fecha)) AS DATE)                              AS desde,
           CAST(date_trunc('year', MAX(fecha)) + INTERVAL '1 year - 1 day' AS DATE) AS hasta
    FROM fechas
)
SELECT CAST(gs AS DATE) AS fecha
FROM rango, generate_series(rango.desde, rango.hasta, INTERVAL '1 day') AS gs
ORDER BY 1;


-- [E02] DimCliente
SELECT id_cliente, nombre_cliente, tipo_cliente, fecha_registro
FROM public.cliente;


-- [E03] DimProducto (desnormaliza Categoria y Marca)
SELECT p.id_producto,
       p.nombre_producto,
       c.nombre_categoria,
       m.nombre_marca
FROM public.producto  p
JOIN public.categoria c ON c.id_categoria = p.id_categoria
JOIN public.marca     m ON m.id_marca     = p.id_marca;


-- [E04] DimCampania
SELECT id_campania, nombre_campania, tipo_descuento, valor_descuento, fecha_inicio, fecha_fin
FROM public.campania;


-- [E05] DimContextoPedido
SELECT canal_dispositivo, metodo_pago, estado_pedido
FROM public.pedido;


-- [E06] DimOperadorLogistico
SELECT id_operador, nombre_operador
FROM public.operadorlogistico;


-- [E07] DimContextoEnvio
SELECT region, tipo_envio
FROM public.envio;


-- [E08] DimMotivoEvento
SELECT tipo_evento, motivo
FROM public.devolucioncancelacion;


-- [E09] FactPedido
SELECT id_pedido, id_cliente, id_campania, fecha_pedido,
       canal_dispositivo, metodo_pago, estado_pedido, monto_total
FROM public.pedido;


-- [E10] FactDetalleVenta (navega DetallePedido -> Pedido y -> Producto)
SELECT d.id_detalle, d.id_pedido, d.id_producto,
       d.cantidad, d.precio_venta_unitario, d.subtotal,
       p.id_cliente, p.id_campania, p.fecha_pedido,
       p.canal_dispositivo, p.metodo_pago, p.estado_pedido,
       pr.costo_unitario
FROM public.detallepedido d
JOIN public.pedido   p  ON p.id_pedido   = d.id_pedido
JOIN public.producto pr ON pr.id_producto = d.id_producto;


-- [E11] FactEnvio (navega Envio -> Pedido)
SELECT e.id_envio, e.id_pedido, e.id_operador, e.region, e.tipo_envio,
       p.fecha_pedido, e.fecha_prevista, e.fecha_entrega_real,
       p.canal_dispositivo, p.metodo_pago, p.estado_pedido
FROM public.envio  e
JOIN public.pedido p ON p.id_pedido = e.id_pedido;


-- [E12] FactDevolucionCancelacion (navega Evento -> DetallePedido -> Pedido)
SELECT dc.id_evento, dc.id_detalle, dc.tipo_evento, dc.motivo,
       dc.fecha_evento, dc.monto_reembolso,
       d.id_producto,
       p.id_cliente, p.id_campania,
       p.canal_dispositivo, p.metodo_pago, p.estado_pedido
FROM public.devolucioncancelacion dc
JOIN public.detallepedido d ON d.id_detalle = dc.id_detalle
JOIN public.pedido        p ON p.id_pedido  = d.id_pedido;


-- ============================================================
-- L. LOOKUP DE LLAVES SUBROGADAS (Data Warehouse)
-- Cada consulta devuelve la llave subrogada con el MISMO nombre que usa
-- la tabla de hechos y la llave natural con el MISMO nombre que trae la
-- extracción, para que el nodo Joiner se configure directamente.
-- Se excluye el miembro 0: lo que no encuentre pareja queda nulo y luego
-- el nodo Missing Value lo convierte en 0.
-- ============================================================

-- [L01] Tiempo - rol fecha de pedido
SELECT fecha AS fecha_pedido, sk_tiempo AS sk_tiempo_pedido
FROM dw.dim_tiempo WHERE sk_tiempo <> 0;

-- [L02] Tiempo - rol fecha prevista
SELECT fecha AS fecha_prevista, sk_tiempo AS sk_tiempo_previsto
FROM dw.dim_tiempo WHERE sk_tiempo <> 0;

-- [L03] Tiempo - rol fecha de entrega real
SELECT fecha AS fecha_entrega_real, sk_tiempo AS sk_tiempo_entrega_real
FROM dw.dim_tiempo WHERE sk_tiempo <> 0;

-- [L04] Tiempo - rol fecha del evento
SELECT fecha AS fecha_evento, sk_tiempo AS sk_tiempo_evento
FROM dw.dim_tiempo WHERE sk_tiempo <> 0;

-- [L05] Cliente
SELECT id_cliente_origen AS id_cliente, sk_cliente
FROM dw.dim_cliente WHERE sk_cliente <> 0;

-- [L06] Producto
SELECT id_producto_origen AS id_producto, sk_producto
FROM dw.dim_producto WHERE sk_producto <> 0;

-- [L07] Campaña
SELECT id_campania_origen AS id_campania, sk_campania
FROM dw.dim_campania WHERE sk_campania <> 0;

-- [L08] Contexto de pedido (llave natural compuesta)
SELECT canal_dispositivo, metodo_pago, estado_pedido, sk_contexto_pedido
FROM dw.dim_contexto_pedido WHERE sk_contexto_pedido <> 0;

-- [L09] Operador logístico
SELECT id_operador_origen AS id_operador, sk_operador
FROM dw.dim_operador_logistico WHERE sk_operador <> 0;

-- [L10] Contexto de envío (llave natural compuesta)
SELECT region, tipo_envio, sk_contexto_envio
FROM dw.dim_contexto_envio WHERE sk_contexto_envio <> 0;

-- [L11] Motivo del evento (llave natural compuesta)
SELECT tipo_evento, motivo, sk_motivo_evento
FROM dw.dim_motivo_evento WHERE sk_motivo_evento <> 0;
