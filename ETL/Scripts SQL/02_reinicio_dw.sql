-- ============================================================
-- PROYECTO 01 - TI6900 Inteligencia de Negocios
-- Grupo 02 - Tema 2: Plataforma de comercio electrónico
-- ETL: paso 0, reinicio del Data Warehouse
-- Motor: PostgreSQL
--
-- Este script lo ejecuta KNIME al inicio del workflow (nodo DB SQL Executor
-- "00 Reiniciar DW"). Deja el esquema dw vacío y vuelve a crear los miembros
-- técnicos (llave 0) definidos en el modelo dimensional. Así el ETL se puede ejecutar
-- tantas veces como sea necesario (carga completa / full load) sin duplicar
-- registros ni violar llaves únicas.
-- ============================================================

TRUNCATE TABLE
    dw.fact_devolucion_cancelacion,
    dw.fact_envio,
    dw.fact_detalle_venta,
    dw.fact_pedido,
    dw.dim_tiempo,
    dw.dim_cliente,
    dw.dim_producto,
    dw.dim_campania,
    dw.dim_contexto_pedido,
    dw.dim_operador_logistico,
    dw.dim_contexto_envio,
    dw.dim_motivo_evento
RESTART IDENTITY;

-- Miembros técnicos (llave 0) para valores desconocidos / no aplicables
INSERT INTO dw.dim_tiempo (sk_tiempo, fecha, dia, nombre_dia, semana, mes, nombre_mes, trimestre, anio)
VALUES (0, NULL, NULL, 'No aplica', NULL, NULL, 'No aplica', NULL, NULL);

INSERT INTO dw.dim_cliente (sk_cliente, id_cliente_origen, nombre_cliente, tipo_cliente, fecha_registro)
VALUES (0, NULL, 'No informado', 'No informado', NULL);

INSERT INTO dw.dim_producto (sk_producto, id_producto_origen, nombre_producto, nombre_categoria, nombre_marca)
VALUES (0, NULL, 'No informado', 'No informado', 'No informado');

INSERT INTO dw.dim_campania (sk_campania, id_campania_origen, nombre_campania, tipo_descuento, valor_descuento, fecha_inicio, fecha_fin)
VALUES (0, NULL, 'Sin campaña', 'No aplica', 0.00, NULL, NULL);

INSERT INTO dw.dim_contexto_pedido (sk_contexto_pedido, canal_dispositivo, metodo_pago, estado_pedido)
VALUES (0, 'No informado', 'No informado', 'No informado');

INSERT INTO dw.dim_operador_logistico (sk_operador, id_operador_origen, nombre_operador)
VALUES (0, NULL, 'No informado');

INSERT INTO dw.dim_contexto_envio (sk_contexto_envio, region, tipo_envio)
VALUES (0, 'No informado', 'No informado');

INSERT INTO dw.dim_motivo_evento (sk_motivo_evento, tipo_evento, motivo)
VALUES (0, 'No informado', 'No informado');
