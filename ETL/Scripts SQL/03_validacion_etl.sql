-- ============================================================
-- PROYECTO 01 - TI6900 Inteligencia de Negocios
-- Grupo 02 - Tema 2: Plataforma de comercio electrónico
-- ETL: validación de la carga (controles de calidad)
-- Motor: PostgreSQL
--
-- Se ejecuta al final del workflow de KNIME (nodo "V01 Validación ETL")
-- o manualmente en pgAdmin. Devuelve una fila por control con el valor
-- obtenido en dw, el valor esperado según la fuente y el estado.
-- Todos los controles deben quedar en "OK".
-- ============================================================

WITH controles AS (

    -- 1. Volumen: filas de origen vs filas cargadas (sin contar miembro 0)
    SELECT 1 AS orden, 'Volumen' AS tipo, 'dim_tiempo (días calendario 2025-2026)' AS control,
           (SELECT COUNT(*) FROM dw.dim_tiempo WHERE sk_tiempo <> 0)::NUMERIC AS obtenido,
           730::NUMERIC AS esperado
    UNION ALL SELECT 2, 'Volumen', 'dim_cliente vs public.cliente',
           (SELECT COUNT(*) FROM dw.dim_cliente WHERE sk_cliente <> 0),
           (SELECT COUNT(*) FROM public.cliente)
    UNION ALL SELECT 3, 'Volumen', 'dim_producto vs public.producto',
           (SELECT COUNT(*) FROM dw.dim_producto WHERE sk_producto <> 0),
           (SELECT COUNT(*) FROM public.producto)
    UNION ALL SELECT 4, 'Volumen', 'dim_campania vs public.campania',
           (SELECT COUNT(*) FROM dw.dim_campania WHERE sk_campania <> 0),
           (SELECT COUNT(*) FROM public.campania)
    UNION ALL SELECT 5, 'Volumen', 'dim_contexto_pedido (combinaciones únicas)',
           (SELECT COUNT(*) FROM dw.dim_contexto_pedido WHERE sk_contexto_pedido <> 0), 54
    UNION ALL SELECT 6, 'Volumen', 'dim_operador_logistico vs public.operadorlogistico',
           (SELECT COUNT(*) FROM dw.dim_operador_logistico WHERE sk_operador <> 0),
           (SELECT COUNT(*) FROM public.operadorlogistico)
    UNION ALL SELECT 7, 'Volumen', 'dim_contexto_envio (combinaciones únicas)',
           (SELECT COUNT(*) FROM dw.dim_contexto_envio WHERE sk_contexto_envio <> 0), 23
    UNION ALL SELECT 8, 'Volumen', 'dim_motivo_evento (combinaciones únicas)',
           (SELECT COUNT(*) FROM dw.dim_motivo_evento WHERE sk_motivo_evento <> 0), 11
    UNION ALL SELECT 9, 'Volumen', 'fact_pedido vs public.pedido',
           (SELECT COUNT(*) FROM dw.fact_pedido),
           (SELECT COUNT(*) FROM public.pedido)
    UNION ALL SELECT 10, 'Volumen', 'fact_detalle_venta vs public.detallepedido',
           (SELECT COUNT(*) FROM dw.fact_detalle_venta),
           (SELECT COUNT(*) FROM public.detallepedido)
    UNION ALL SELECT 11, 'Volumen', 'fact_envio vs public.envio',
           (SELECT COUNT(*) FROM dw.fact_envio),
           (SELECT COUNT(*) FROM public.envio)
    UNION ALL SELECT 12, 'Volumen', 'fact_devolucion_cancelacion vs public.devolucioncancelacion',
           (SELECT COUNT(*) FROM dw.fact_devolucion_cancelacion),
           (SELECT COUNT(*) FROM public.devolucioncancelacion)

    -- 2. Totales de control: las medidas no se pierden ni se duplican
    UNION ALL SELECT 13, 'Total de control', 'SUM(monto_total) fact_pedido vs pedido',
           (SELECT SUM(monto_total) FROM dw.fact_pedido),
           (SELECT SUM(monto_total) FROM public.pedido)
    UNION ALL SELECT 14, 'Total de control', 'SUM(ingreso_bruto) vs SUM(detallepedido.subtotal)',
           (SELECT SUM(ingreso_bruto) FROM dw.fact_detalle_venta),
           (SELECT SUM(subtotal) FROM public.detallepedido)
    UNION ALL SELECT 15, 'Total de control', 'SUM(cantidad) unidades vendidas',
           (SELECT SUM(cantidad) FROM dw.fact_detalle_venta),
           (SELECT SUM(cantidad) FROM public.detallepedido)
    UNION ALL SELECT 16, 'Total de control', 'SUM(monto_reembolso) vs fuente',
           (SELECT SUM(monto_reembolso) FROM dw.fact_devolucion_cancelacion),
           (SELECT SUM(monto_reembolso) FROM public.devolucioncancelacion)
    UNION ALL SELECT 17, 'Total de control', 'monto_total = suma de ingreso_bruto por pedido (pedidos que no cuadran)',
           (SELECT COUNT(*) FROM (
                SELECT f.id_pedido FROM dw.fact_pedido f
                JOIN dw.fact_detalle_venta d ON d.id_pedido = f.id_pedido
                GROUP BY f.id_pedido, f.monto_total
                HAVING ABS(f.monto_total - SUM(d.ingreso_bruto)) > 0.01) x), 0

    -- 3. Derivaciones
    UNION ALL SELECT 18, 'Derivación', 'SUM(costo_total) = SUM(cantidad * costo_unitario)',
           (SELECT SUM(costo_total) FROM dw.fact_detalle_venta), 670934832.64
    UNION ALL SELECT 19, 'Derivación', 'SUM(margen_bruto) = ingreso_bruto - costo_total',
           (SELECT SUM(margen_bruto) FROM dw.fact_detalle_venta), 364812244.93
    UNION ALL SELECT 20, 'Derivación', 'Líneas sin costo (producto sin costo_unitario) -> margen nulo',
           (SELECT COUNT(*) FROM dw.fact_detalle_venta WHERE costo_unitario IS NULL AND margen_bruto IS NULL), 137
    UNION ALL SELECT 21, 'Derivación', 'Envíos entregados a tiempo (entrega_a_tiempo = 1)',
           (SELECT COUNT(*) FROM dw.fact_envio WHERE entrega_a_tiempo = 1), 1796
    UNION ALL SELECT 22, 'Derivación', 'Envíos tardíos (entrega_a_tiempo = 0)',
           (SELECT COUNT(*) FROM dw.fact_envio WHERE entrega_a_tiempo = 0), 470
    UNION ALL SELECT 23, 'Derivación', 'Envíos sin entrega real (medidas nulas)',
           (SELECT COUNT(*) FROM dw.fact_envio
             WHERE dias_entrega IS NULL AND dias_desviacion IS NULL AND entrega_a_tiempo IS NULL), 234
    UNION ALL SELECT 24, 'Derivación', 'SUM(dias_entrega)',
           (SELECT SUM(dias_entrega) FROM dw.fact_envio), 6422
    UNION ALL SELECT 25, 'Derivación', 'SUM(dias_desviacion)',
           (SELECT SUM(dias_desviacion) FROM dw.fact_envio), 695

    -- 4. Miembros técnicos (llave 0) asignados donde corresponde
    UNION ALL SELECT 26, 'Miembro 0', 'fact_pedido con sk_campania = 0 (pedido sin campaña)',
           (SELECT COUNT(*) FROM dw.fact_pedido WHERE sk_campania = 0),
           (SELECT COUNT(*) FROM public.pedido WHERE id_campania IS NULL)
    UNION ALL SELECT 27, 'Miembro 0', 'fact_envio con sk_tiempo_entrega_real = 0 (sin entrega)',
           (SELECT COUNT(*) FROM dw.fact_envio WHERE sk_tiempo_entrega_real = 0),
           (SELECT COUNT(*) FROM public.envio WHERE fecha_entrega_real IS NULL)
    UNION ALL SELECT 28, 'Miembro 0', 'fact_envio con sk_contexto_envio = 0 (región y tipo nulos)',
           (SELECT COUNT(*) FROM dw.fact_envio WHERE sk_contexto_envio = 0),
           (SELECT COUNT(*) FROM public.envio WHERE region IS NULL AND tipo_envio IS NULL)
    UNION ALL SELECT 29, 'Miembro 0', 'Llaves en 0 que NO deberían existir (tiempo, cliente, producto, operador, motivo)',
           (SELECT COUNT(*) FROM dw.fact_pedido WHERE 0 IN (sk_tiempo_pedido, sk_cliente, sk_contexto_pedido))
         + (SELECT COUNT(*) FROM dw.fact_detalle_venta WHERE 0 IN (sk_tiempo_pedido, sk_cliente, sk_producto, sk_contexto_pedido))
         + (SELECT COUNT(*) FROM dw.fact_envio WHERE 0 IN (sk_tiempo_pedido, sk_tiempo_previsto, sk_operador, sk_contexto_pedido))
         + (SELECT COUNT(*) FROM dw.fact_devolucion_cancelacion WHERE 0 IN (sk_tiempo_evento, sk_cliente, sk_producto, sk_contexto_pedido, sk_motivo_evento)),
           0

    -- 5. Limpieza y homologación
    UNION ALL SELECT 30, 'Limpieza', 'Textos nulos restantes en dimensiones de contexto',
           (SELECT COUNT(*) FROM dw.dim_contexto_pedido WHERE canal_dispositivo IS NULL OR metodo_pago IS NULL OR estado_pedido IS NULL)
         + (SELECT COUNT(*) FROM dw.dim_contexto_envio WHERE region IS NULL OR tipo_envio IS NULL)
         + (SELECT COUNT(*) FROM dw.dim_motivo_evento WHERE motivo IS NULL), 0
    UNION ALL SELECT 31, 'Homologación', 'Campañas sin tilde corregidas (San Valentín, Día de la Madre, Día del Padre)',
           (SELECT COUNT(*) FROM dw.dim_campania WHERE nombre_campania IN ('San Valentín', 'Día de la Madre', 'Día del Padre')), 3
    UNION ALL SELECT 32, 'Homologación', 'Clientes con palabras en minúscula inicial',
           (SELECT COUNT(*) FROM dw.dim_cliente WHERE sk_cliente <> 0 AND nombre_cliente ~ '(^| )[a-z]'), 0
)
SELECT orden,
       tipo,
       control,
       obtenido,
       esperado,
       CASE WHEN obtenido = esperado THEN 'OK' ELSE 'REVISAR' END AS estado,
       CAST(now() AS TIMESTAMP(0)) AS fecha_ejecucion
FROM controles
ORDER BY orden;
