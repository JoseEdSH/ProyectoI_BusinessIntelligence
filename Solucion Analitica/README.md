# Solución Analítica

Contenido de la carpeta Solución Analítica: componente analítico construido sobre el modelo dimensional (esquema `dw`) ya cargado por el ETL. Se implementó en **KNIME Analytics Platform 5** mediante reportes (gráficos de barras y tablas) que responden las preguntas de negocio del Tema 2.

## Persona 4 — Preguntas 1 y 2

Estudiante: Francisco Alejandro Díaz Palma

- **Pregunta 1.** ¿Qué categorías, productos, marcas y campañas generan más pedidos, ingresos y margen por periodo?
- **Pregunta 2.** ¿Cómo se comportan los tiempos de entrega y el porcentaje de entregas a tiempo según operador logístico, región y tipo de envío?

### Estructura

| Carpeta / archivo | Contenido |
|---|---|
| `Workflow KNIME/Persona4_Analisis.knwf` | Workflow exportado desde KNIME: un DB Connector, 10 consultas (DB Query Reader), nodos Sorter / Top k Row Filter y las vistas (Bar Chart y Table View). |
| `Consultas SQL/Persona4_consultas_analisis.sql` | Las 10 consultas que usan los nodos DB Query Reader. Todas leen únicamente el esquema `dw`. |
| `Evidencias/Persona 4/` | Capturas de cada vista del workflow (Q0 = workflow general, Q1_xx = pregunta 1, Q2_xx = pregunta 2). |

### Vistas del workflow

| Pregunta | Vista | Captura |
|---|---|---|
| Q1 | Ingreso y margen por categoría | `Q1_01_categorias_ingreso_margen.png` |
| Q1 | % de margen por categoría | `Q1_02_categorias_porcentaje_margen.png` |
| Q1 | Tabla categoría x trimestre | `Q1_03_categorias_por_trimestre_tabla.png` |
| Q1 | Top 10 productos por ingreso | `Q1_04_top10_productos_ingreso.png` |
| Q1 | Top 10 productos por margen | `Q1_05_top10_productos_margen.png` |
| Q1 | Top 10 marcas | `Q1_06_top10_marcas.png` |
| Q1 | Ingreso y margen por campaña | `Q1_07_campanas_ingreso_margen.png` |
| Q1 | Pedidos por campaña | `Q1_08_campanas_pedidos.png` |
| Q1 | Tendencia mensual | `Q1_09_evolucion_mensual.png` |
| Q2 | % a tiempo por operador | `Q2_01_operador_pct_a_tiempo.png` |
| Q2 | Días de entrega y de atraso por operador | `Q2_02_operador_dias.png` |
| Q2 | % a tiempo por región | `Q2_03_region_pct_a_tiempo.png` |
| Q2 | Días de entrega por región | `Q2_04_region_dias.png` |
| Q2 | % a tiempo por tipo de envío | `Q2_05_tipo_envio_pct_a_tiempo.png` |
| Q2 | Días de entrega por tipo de envío | `Q2_06_tipo_envio_dias.png` |
| Q2 | Tabla operador x tipo de envío | `Q2_07_operador_x_tipo_envio_tabla.png` |

En los gráficos de montos, el ingreso y el margen se muestran en **millones de colones** (columnas `"Ingreso bruto"` y `"Margen bruto"` de las consultas), ya que el Bar Chart de KNIME no permite dar formato a los números y las cifras completas aparecían en notación científica. Las tablas conservan los montos completos.

### Instrucciones de ejecución

Requisitos: haber ejecutado antes el ETL (ver `ETL/README.md`), de modo que la base `ecommerce_bi` tenga cargado el esquema `dw`.

1. En KNIME, importar `Solucion Analitica/Workflow KNIME/Persona4_Analisis.knwf`.
2. Al abrir el workflow, KNIME solicita la credencial `postgres`: indicar el usuario y la contraseña de PostgreSQL de la computadora local. El workflow no guarda contraseñas.
3. Si el servidor no está en `localhost:5432`, ajustar la URL del nodo **DB Connector** (`jdbc:postgresql://localhost:5432/ecommerce_bi`).
4. Ejecutar con **Execute all**.
5. Seleccionar cualquier nodo Bar Chart o Table View para ver su resultado en el panel inferior.


## Persona 5 — Preguntas 3 y 4 e indicador adicional

Estudiante: Alexandra Pamela Cruz Segura

- **Pregunta 3.** ¿Qué productos presentan mayores tasas de cancelación o devolución y cuáles son las razones más frecuentes?
- **Pregunta 4.** ¿Cómo varían el ticket promedio y la recurrencia de compra según segmento de cliente, dispositivo y método de pago?
- **Indicador adicional.** Margen bruto promedio por pedido.

### Estructura

| **Carpeta / archivo** | **Contenido** |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `Workflow KNIME/Persona5_Analisis.knwf` | Workflow exportado desde KNIME con las consultas y visualizaciones correspondientes a Q3, Q4 y el indicador adicional. |
| `Evidencias/Persona 5/` | Capturas de las vistas generadas para Q3, Q4 y el indicador de rentabilidad por pedido. |

### Vistas del workflow

| **Pregunta / indicador** | **Vista** | **Captura** |
| ------------ | ---------------------------------------- | ------------------------------------------ |
| Q3 | Top 5 productos por tasa de cancelación | `Top 5 productos por tasa de cancelación.png` |
| Q3 | Top 5 productos por tasa de devolución | `Top 5 productos por tasa de devolución.png` |
| Q3 | Principales razones de cancelación y devolución | `Principales razones de cancelación y devolución.png` |
| Q4 | Ticket promedio por segmento de cliente | `Ticket promedio por segmento de cliente.png` |
| Q4 | Recurrencia por segmento de cliente | `Recurrencia por segmento de cliente.png` |
| Q4 | Ticket promedio por dispositivo | `Ticket promedio por dispositivo.png` |
| Q4 | Recurrencia de compra por dispositivo | `Recurrencia de compra por dispositivo.png` |
| Q4 | Ticket promedio por método de pago | `Ticket promedio por método de pago.png` |
| Q4 | Recurrencia de compra por método de pago | `Recurrencia de compra por método de pago.png` |
| Indicador | Margen bruto promedio por pedido | `Indicador rentabilidad por pedido.png` |

### Indicador adicional

Como indicador complementario se calculó el **margen bruto promedio por pedido**, utilizando el margen bruto registrado en `fact_detalle_venta` y el total de pedidos de `fact_pedido`.

El análisis considera 2 500 pedidos, con un margen bruto total de ₡364 812 244,93 y un margen bruto promedio de **₡145 924,90 por pedido**.

> Nota: el margen bruto promedio por pedido corresponde a un indicador de rentabilidad bruta y no debe interpretarse como utilidad neta.

### Ejecución

El workflow de Persona 5 utiliza el esquema `dw` cargado previamente por el ETL. Las consultas se ejecutan mediante los nodos de consulta de KNIME y las salidas se visualizan mediante gráficos de barras y Table View.
