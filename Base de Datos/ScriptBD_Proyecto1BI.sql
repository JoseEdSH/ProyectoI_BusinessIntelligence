-- ============================================================
-- Base de datos transaccional - Plataforma de E-commerce
-- Proyecto 01 - TI6900 Inteligencia de Negocios
-- Tema 2: Plataforma de comercio electrónico
-- Persona 1: Análisis del negocio y fuente de datos de origen
-- ============================================================

-- Orden de creación respeta las dependencias de llaves foráneas:
-- catálogos primero, luego transaccionales.

-- ---------- TABLAS DE CATÁLOGO (sin dependencias) ----------

CREATE TABLE Cliente (
    id_cliente         SERIAL PRIMARY KEY,
    nombre_cliente     VARCHAR(100) NOT NULL,
    correo_electronico VARCHAR(150),
    tipo_cliente       VARCHAR(20),   -- Nuevo / Recurrente / VIP
    fecha_registro     DATE
);

CREATE TABLE Categoria (
    id_categoria     SERIAL PRIMARY KEY,
    nombre_categoria VARCHAR(50) NOT NULL
);

CREATE TABLE Marca (
    id_marca     SERIAL PRIMARY KEY,
    nombre_marca VARCHAR(50) NOT NULL
);

CREATE TABLE Campania (
    id_campania     SERIAL PRIMARY KEY,
    nombre_campania VARCHAR(100) NOT NULL,
    tipo_descuento  VARCHAR(20),   -- Porcentaje / Monto fijo
    valor_descuento NUMERIC(10,2),
    fecha_inicio    DATE,
    fecha_fin       DATE
);

CREATE TABLE OperadorLogistico (
    id_operador     SERIAL PRIMARY KEY,
    nombre_operador VARCHAR(100) NOT NULL
);

-- ---------- TABLAS DEPENDIENTES DE CATÁLOGOS ----------

CREATE TABLE Producto (
    id_producto     SERIAL PRIMARY KEY,
    nombre_producto VARCHAR(150) NOT NULL,
    id_categoria    INT NOT NULL REFERENCES Categoria(id_categoria),
    id_marca        INT NOT NULL REFERENCES Marca(id_marca),
    precio_unitario NUMERIC(10,2) NOT NULL,
    costo_unitario  NUMERIC(10,2) 
);

-- ---------- TABLAS TRANSACCIONALES ----------

CREATE TABLE Pedido (
    id_pedido       SERIAL PRIMARY KEY,
    id_cliente      INT NOT NULL REFERENCES Cliente(id_cliente),
    id_campania     INT REFERENCES Campania(id_campania),  -- nullable: no todo pedido tiene campaña
    fecha_pedido    DATE NOT NULL,
    canal_dispositivo VARCHAR(30),  -- Web / App móvil / App escritorio
    metodo_pago     VARCHAR(30),
    estado_pedido   VARCHAR(20),    -- Completado / Cancelado / Devuelto
    monto_total     NUMERIC(10,2)
);

CREATE TABLE DetallePedido (
    id_detalle            SERIAL PRIMARY KEY,
    id_pedido              INT NOT NULL REFERENCES Pedido(id_pedido),
    id_producto            INT NOT NULL REFERENCES Producto(id_producto),
    cantidad                INT NOT NULL,
    precio_venta_unitario  NUMERIC(10,2) NOT NULL,
    subtotal                NUMERIC(10,2) NOT NULL
);

CREATE TABLE Envio (
    id_envio            SERIAL PRIMARY KEY,
    id_pedido           INT NOT NULL UNIQUE REFERENCES Pedido(id_pedido),  -- 1 a 1 con Pedido
    id_operador         INT NOT NULL REFERENCES OperadorLogistico(id_operador),
    region              VARCHAR(50),
    tipo_envio          VARCHAR(20),   -- Estándar / Express
    fecha_prevista      DATE,
    fecha_entrega_real  DATE
);

CREATE TABLE DevolucionCancelacion (
    id_evento       SERIAL PRIMARY KEY,
    id_detalle      INT NOT NULL REFERENCES DetallePedido(id_detalle),
    tipo_evento     VARCHAR(20),   -- Cancelación / Devolución
    motivo          VARCHAR(150),
    fecha_evento    DATE,
    monto_reembolso NUMERIC(10,2)
);
