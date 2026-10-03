# ETL

Contenido de la carpeta ETL: proceso ETL que traslada los datos desde la fuente transaccional (esquema `public`) hacia el modelo dimensional (esquema `dw`) en PostgreSQL, implementado en **KNIME Analytics Platform 5**.

## Estructura

| Carpeta / archivo | Contenido |
|---|---|
| `Scripts SQL/01_carga_datos_fuente.sql` | Inserta en `public` los datos de la carpeta `Datos` (10 tablas, 10.287 registros). |
| `Scripts SQL/02_reinicio_dw.sql` | Vacía `dw` y recrea los miembros técnicos (llave 0). Lo ejecuta el primer nodo del workflow. |
| `Scripts SQL/03_validacion_etl.sql` | 32 controles de calidad de la carga (volumen, totales, derivaciones, miembros técnicos y homologación). |
| `Workflow KNIME/ETL_Ecommerce_Grupo02.knwf` | Workflow del ETL exportado desde KNIME. |
| `Workflow KNIME/consultas_nodos_knime.sql` | Consultas de extracción (E01-E12) y de lookup de llaves subrogadas (L01-L11) usadas en los nodos. |
| `Workflow KNIME/V01_validacion_para_knime.sql` | Consulta de validación lista para el nodo V01. |
| `Documentacion/Reglas_transformacion_ETL.md` | Cuadro de reglas: campo destino, campo origen, regla aplicada y comentarios. |
| `Evidencias/` |  `validacion_etl.csv`. |

## Instrucciones de ejecución

Requisitos: PostgreSQL 16 o superior (con pgAdmin 4) y KNIME Analytics Platform 5.

1. Crear en PostgreSQL una base de datos llamada `ecommerce_bi`.
2. Ejecutar en el Query Tool, en este orden:
   1. `Base de Datos/ScriptBD_Proyecto1BI.sql`
   2. `ETL/Scripts SQL/01_carga_datos_fuente.sql`
   3. `Data Warehouse/modelo_dimensional.sql`
3. En KNIME, importar `ETL/Workflow KNIME/ETL_Ecommerce_Grupo02.knwf`.
4. Ajustar dos nodos a la computadora local:
   - **C01 Conexión PostgreSQL** (metanodo *1 Conexión y reinicio*): usuario y contraseña de PostgreSQL.
   - **V02 Guardar log de validación** (metanodo *5 Validación*): ruta de salida de `validacion_etl.csv`.
5. Ejecutar con **Execute all**. Al terminar, la tabla del nodo **V01** debe mostrar los 32 controles en `OK`.

El workflow se puede ejecutar varias veces: el primer paso vacía `dw` antes de cargar, por lo que no se duplican datos.

## Resultado esperado

| Tabla | Registros |
|---|---|
| dim_tiempo / dim_cliente / dim_producto / dim_campania | 730 / 450 / 180 / 14 (+ miembro 0) |
| dim_contexto_pedido / dim_operador_logistico / dim_contexto_envio / dim_motivo_evento | 54 / 4 / 23 / 11 (+ miembro 0) |
| fact_pedido / fact_detalle_venta / fact_envio / fact_devolucion_cancelacion | 2.500 / 4.117 / 2.500 / 480 |
