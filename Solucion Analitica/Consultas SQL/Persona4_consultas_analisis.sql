-- =====================================================================
-- Proyecto 01 · TI6900 Inteligencia de Negocios · Grupo 02
-- Persona 4 - Solución analítica, parte 1 (pedidos, ingresos y logística)
-- Consultas usadas en los nodos DB Query Reader del workflow
-- Persona4_Analisis (KNIME). Todas leen únicamente el esquema dw.
-- =====================================================================


-- ---------------------------------------------------------------------
-- Pregunta 1. ¿Qué categorías, productos, marcas y campañas generan más
-- pedidos, ingresos y margen por periodo?
-- Nota: el % de margen solo considera líneas con costo_unitario no nulo
-- en ambos términos (137 líneas de 6 productos no tienen costo).
-- Las columnas "Ingreso bruto" y "Margen bruto" repiten los montos en millones
-- de colones; son las que usan los gráficos para que las cifras se lean completas.
-- ---------------------------------------------------------------------

-- Q1.1 Categorías por trimestre
SELECT
    dt.anio || '-T' || dt.trimestre AS periodo,
    dp.nombre_categoria AS categoria,
    COUNT(DISTINCT fdv.id_pedido) AS pedidos,
    SUM(fdv.cantidad) AS unidades,
    SUM(fdv.ingreso_bruto) AS ingreso_bruto,
    SUM(fdv.margen_bruto) AS margen_bruto,
    ROUND(
        SUM(fdv.margen_bruto)::numeric
        / NULLIF(SUM(CASE WHEN fdv.costo_unitario IS NOT NULL THEN fdv.ingreso_bruto END), 0) * 100,
        2
    ) AS porcentaje_margen
FROM dw.fact_detalle_venta fdv
INNER JOIN dw.dim_producto dp
    ON fdv.sk_producto = dp.sk_producto
INNER JOIN dw.dim_tiempo dt
    ON fdv.sk_tiempo_pedido = dt.sk_tiempo
WHERE fdv.sk_producto <> 0
GROUP BY
    dt.anio,
    dt.trimestre,
    dp.nombre_categoria
ORDER BY
    dt.anio,
    dt.trimestre,
    ingreso_bruto DESC;

-- Q1.2 Categorías en todo el periodo
SELECT
    dp.nombre_categoria AS categoria,
    COUNT(DISTINCT fdv.id_pedido) AS pedidos,
    SUM(fdv.cantidad) AS unidades,
    SUM(fdv.ingreso_bruto) AS ingreso_bruto,
    SUM(fdv.margen_bruto) AS margen_bruto,
    ROUND(SUM(fdv.ingreso_bruto)::numeric / 1000000, 2) AS "Ingreso bruto",
    ROUND(SUM(fdv.margen_bruto)::numeric / 1000000, 2) AS "Margen bruto",
    ROUND(
        SUM(fdv.margen_bruto)::numeric
        / NULLIF(SUM(CASE WHEN fdv.costo_unitario IS NOT NULL THEN fdv.ingreso_bruto END), 0) * 100,
        2
    ) AS porcentaje_margen
FROM dw.fact_detalle_venta fdv
INNER JOIN dw.dim_producto dp
    ON fdv.sk_producto = dp.sk_producto
WHERE fdv.sk_producto <> 0
GROUP BY dp.nombre_categoria
ORDER BY ingreso_bruto DESC;

-- Q1.3 Productos (el Top 10 por ingreso y por margen se filtra en KNIME con Top k Row Filter;
-- se agrega el id de origen porque hay 11 nombres de producto repetidos)
SELECT
    dp.nombre_producto || ' (' || dp.id_producto_origen || ')' AS producto,
    dp.nombre_categoria AS categoria,
    dp.nombre_marca AS marca,
    COUNT(DISTINCT fdv.id_pedido) AS pedidos,
    SUM(fdv.cantidad) AS unidades,
    SUM(fdv.ingreso_bruto) AS ingreso_bruto,
    SUM(fdv.margen_bruto) AS margen_bruto,
    ROUND(SUM(fdv.ingreso_bruto)::numeric / 1000000, 2) AS "Ingreso bruto",
    ROUND(SUM(fdv.margen_bruto)::numeric / 1000000, 2) AS "Margen bruto",
    ROUND(
        SUM(fdv.margen_bruto)::numeric
        / NULLIF(SUM(CASE WHEN fdv.costo_unitario IS NOT NULL THEN fdv.ingreso_bruto END), 0) * 100,
        2
    ) AS porcentaje_margen
FROM dw.fact_detalle_venta fdv
INNER JOIN dw.dim_producto dp
    ON fdv.sk_producto = dp.sk_producto
WHERE fdv.sk_producto <> 0
GROUP BY
    dp.sk_producto,
    dp.id_producto_origen,
    dp.nombre_producto,
    dp.nombre_categoria,
    dp.nombre_marca
ORDER BY ingreso_bruto DESC;

-- Q1.4 Marcas
SELECT
    dp.nombre_marca AS marca,
    COUNT(DISTINCT fdv.id_pedido) AS pedidos,
    SUM(fdv.cantidad) AS unidades,
    SUM(fdv.ingreso_bruto) AS ingreso_bruto,
    SUM(fdv.margen_bruto) AS margen_bruto,
    ROUND(SUM(fdv.ingreso_bruto)::numeric / 1000000, 2) AS "Ingreso bruto",
    ROUND(SUM(fdv.margen_bruto)::numeric / 1000000, 2) AS "Margen bruto",
    ROUND(
        SUM(fdv.margen_bruto)::numeric
        / NULLIF(SUM(CASE WHEN fdv.costo_unitario IS NOT NULL THEN fdv.ingreso_bruto END), 0) * 100,
        2
    ) AS porcentaje_margen
FROM dw.fact_detalle_venta fdv
INNER JOIN dw.dim_producto dp
    ON fdv.sk_producto = dp.sk_producto
WHERE fdv.sk_producto <> 0
GROUP BY dp.nombre_marca
ORDER BY ingreso_bruto DESC;

-- Q1.5 Campañas (incluye el miembro 0 "Sin campaña" como referencia)
SELECT
    dc.nombre_campania AS campania,
    dc.tipo_descuento,
    COUNT(DISTINCT fdv.id_pedido) AS pedidos,
    SUM(fdv.cantidad) AS unidades,
    SUM(fdv.ingreso_bruto) AS ingreso_bruto,
    SUM(fdv.margen_bruto) AS margen_bruto,
    ROUND(SUM(fdv.ingreso_bruto)::numeric / 1000000, 2) AS "Ingreso bruto",
    ROUND(SUM(fdv.margen_bruto)::numeric / 1000000, 2) AS "Margen bruto",
    ROUND(
        SUM(fdv.margen_bruto)::numeric
        / NULLIF(SUM(CASE WHEN fdv.costo_unitario IS NOT NULL THEN fdv.ingreso_bruto END), 0) * 100,
        2
    ) AS porcentaje_margen,
    ROUND(
        SUM(fdv.ingreso_bruto)::numeric
        / NULLIF(COUNT(DISTINCT fdv.id_pedido), 0),
        2
    ) AS ingreso_por_pedido
FROM dw.fact_detalle_venta fdv
INNER JOIN dw.dim_campania dc
    ON fdv.sk_campania = dc.sk_campania
GROUP BY
    dc.sk_campania,
    dc.nombre_campania,
    dc.tipo_descuento
ORDER BY ingreso_bruto DESC;

-- Q1.6 Evolución mensual del total (tendencia por periodo)
SELECT
    dt.anio || '-' || LPAD(dt.mes::text, 2, '0') AS periodo,
    COUNT(DISTINCT fdv.id_pedido) AS pedidos,
    SUM(fdv.ingreso_bruto) AS ingreso_bruto,
    SUM(fdv.margen_bruto) AS margen_bruto,
    ROUND(SUM(fdv.ingreso_bruto)::numeric / 1000000, 1) AS "Ingreso bruto",
    ROUND(SUM(fdv.margen_bruto)::numeric / 1000000, 1) AS "Margen bruto"
FROM dw.fact_detalle_venta fdv
INNER JOIN dw.dim_tiempo dt
    ON fdv.sk_tiempo_pedido = dt.sk_tiempo
GROUP BY
    dt.anio,
    dt.mes
ORDER BY periodo;


-- ---------------------------------------------------------------------
-- Pregunta 2. ¿Cómo se comportan los tiempos de entrega y el porcentaje
-- de entregas a tiempo según operador logístico, región y tipo de envío?
-- Nota: los 234 envíos de pedidos cancelados tienen entrega_a_tiempo y
-- dias_entrega nulos; AVG y COUNT(columna) los ignoran.
-- ---------------------------------------------------------------------

-- Q2.1 Operador logístico
SELECT
    dol.nombre_operador AS operador,
    COUNT(fe.entrega_a_tiempo) AS envios_entregados,
    ROUND(AVG(fe.dias_entrega)::numeric, 2) AS dias_promedio_entrega,
    SUM(fe.entrega_a_tiempo) AS entregas_a_tiempo,
    ROUND(
        SUM(fe.entrega_a_tiempo)::numeric
        / NULLIF(COUNT(fe.entrega_a_tiempo), 0) * 100,
        2
    ) AS porcentaje_a_tiempo,
    ROUND(AVG(CASE WHEN fe.dias_desviacion > 0 THEN fe.dias_desviacion END)::numeric, 2) AS dias_atraso_promedio
FROM dw.fact_envio fe
INNER JOIN dw.dim_operador_logistico dol
    ON fe.sk_operador = dol.sk_operador
GROUP BY dol.nombre_operador
ORDER BY porcentaje_a_tiempo DESC;

-- Q2.2 Región (se excluye el miembro 0 "No informado")
SELECT
    dce.region,
    COUNT(fe.entrega_a_tiempo) AS envios_entregados,
    ROUND(AVG(fe.dias_entrega)::numeric, 2) AS dias_promedio_entrega,
    SUM(fe.entrega_a_tiempo) AS entregas_a_tiempo,
    ROUND(
        SUM(fe.entrega_a_tiempo)::numeric
        / NULLIF(COUNT(fe.entrega_a_tiempo), 0) * 100,
        2
    ) AS porcentaje_a_tiempo,
    ROUND(AVG(CASE WHEN fe.dias_desviacion > 0 THEN fe.dias_desviacion END)::numeric, 2) AS dias_atraso_promedio
FROM dw.fact_envio fe
INNER JOIN dw.dim_contexto_envio dce
    ON fe.sk_contexto_envio = dce.sk_contexto_envio
WHERE fe.sk_contexto_envio <> 0
GROUP BY dce.region
ORDER BY porcentaje_a_tiempo DESC;

-- Q2.3 Tipo de envío
SELECT
    dce.tipo_envio,
    COUNT(fe.entrega_a_tiempo) AS envios_entregados,
    ROUND(AVG(fe.dias_entrega)::numeric, 2) AS dias_promedio_entrega,
    SUM(fe.entrega_a_tiempo) AS entregas_a_tiempo,
    ROUND(
        SUM(fe.entrega_a_tiempo)::numeric
        / NULLIF(COUNT(fe.entrega_a_tiempo), 0) * 100,
        2
    ) AS porcentaje_a_tiempo,
    ROUND(AVG(CASE WHEN fe.dias_desviacion > 0 THEN fe.dias_desviacion END)::numeric, 2) AS dias_atraso_promedio
FROM dw.fact_envio fe
INNER JOIN dw.dim_contexto_envio dce
    ON fe.sk_contexto_envio = dce.sk_contexto_envio
WHERE fe.sk_contexto_envio <> 0
GROUP BY dce.tipo_envio
ORDER BY porcentaje_a_tiempo DESC;

-- Q2.4 Operador por tipo de envío (cruce para detectar dónde falla cada operador)
SELECT
    dol.nombre_operador AS operador,
    dce.tipo_envio,
    COUNT(fe.entrega_a_tiempo) AS envios_entregados,
    ROUND(AVG(fe.dias_entrega)::numeric, 2) AS dias_promedio_entrega,
    ROUND(
        SUM(fe.entrega_a_tiempo)::numeric
        / NULLIF(COUNT(fe.entrega_a_tiempo), 0) * 100,
        2
    ) AS porcentaje_a_tiempo
FROM dw.fact_envio fe
INNER JOIN dw.dim_operador_logistico dol
    ON fe.sk_operador = dol.sk_operador
INNER JOIN dw.dim_contexto_envio dce
    ON fe.sk_contexto_envio = dce.sk_contexto_envio
WHERE fe.sk_contexto_envio <> 0
  AND dce.tipo_envio <> 'No informado'
GROUP BY
    dol.nombre_operador,
    dce.tipo_envio
ORDER BY
    dol.nombre_operador,
    dce.tipo_envio;
