-- ============================================================
-- PROYECTO: Sistema de Gestion de Pedidos y Domicilios
-- EMPRESA : Pizzeria Don Piccolo
-- ARCHIVO : database.sql
-- CONTENIDO: Creacion de la base de datos y de todas las
--            tablas, con sus llaves primarias (PK) y llaves
--            foraneas (FK) que las conectan entre si.
-- ============================================================

-- Si la base de datos ya existe la eliminamos primero. Util
-- mientras probamos el script varias veces. OJO: en un ambiente
-- real esto borraria todos los datos.
DROP DATABASE IF EXISTS pizzeria_don_piccolo;

-- Creamos la base de datos. utf8mb4 permite guardar tildes y "ñ".
CREATE DATABASE pizzeria_don_piccolo
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_spanish_ci;

-- Desde aqui, todo lo que creemos pertenece a esta base de datos.
USE pizzeria_don_piccolo;


-- ------------------------------------------------------------
-- TABLA: clientes
-- ------------------------------------------------------------
CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY, -- MySQL genera este numero solo
    nombre     VARCHAR(100) NOT NULL,
    telefono   VARCHAR(20)  NOT NULL,
    correo     VARCHAR(100),                   -- este si es opcional
    direccion  VARCHAR(200) NOT NULL
) ENGINE = InnoDB; -- InnoDB soporta llaves foraneas (FOREIGN KEY)


-- ------------------------------------------------------------
-- TABLA: pizzas
-- Catalogo general. El precio no va aqui porque cambia segun
-- el tamano (eso lo maneja pizza_precios).
-- ------------------------------------------------------------
CREATE TABLE pizzas (
    id_pizza INT AUTO_INCREMENT PRIMARY KEY,
    nombre   VARCHAR(100) NOT NULL,
    -- ENUM limita la columna a una lista fija de valores validos
    tipo ENUM('vegetariana', 'especial', 'clasica') NOT NULL
) ENGINE = InnoDB;


-- ------------------------------------------------------------
-- TABLA: pizza_precios
-- Una pizza puede tener varios precios segun el tamano.
-- ------------------------------------------------------------
CREATE TABLE pizza_precios (
    id_precio INT AUTO_INCREMENT PRIMARY KEY,
    id_pizza  INT NOT NULL,
    tamano    ENUM('pequena', 'mediana', 'grande') NOT NULL,
    precio    DECIMAL(10,2) NOT NULL,

    -- Conecta con pizzas: no se puede poner precio a una pizza
    -- que no existe en el catalogo.
    FOREIGN KEY (id_pizza) REFERENCES pizzas(id_pizza),

    -- Evita dos precios para la misma pizza en el mismo tamano.
    UNIQUE (id_pizza, tamano)
) ENGINE = InnoDB;


-- ------------------------------------------------------------
-- TABLA: ingredientes (control de inventario)
-- ------------------------------------------------------------
CREATE TABLE ingredientes (
    id_ingrediente INT AUTO_INCREMENT PRIMARY KEY,
    nombre         VARCHAR(100) NOT NULL,
    unidad_medida  VARCHAR(20)  NOT NULL,        -- ej: "gramos", "unidades"
    stock          DECIMAL(8,2) NOT NULL DEFAULT 0,
    stock_minimo   DECIMAL(8,2) NOT NULL DEFAULT 0, -- debajo de esto, hay que comprar mas
    costo_unitario DECIMAL(10,2) NOT NULL DEFAULT 0
) ENGINE = InnoDB;


-- ------------------------------------------------------------
-- TABLA: pizza_ingredientes (tabla puente)
-- Resuelve la relacion "muchos a muchos": una pizza usa varios
-- ingredientes, y un ingrediente se usa en varias pizzas.
-- ------------------------------------------------------------
CREATE TABLE pizza_ingredientes (
    id_pizza_ingrediente INT AUTO_INCREMENT PRIMARY KEY,
    id_pizza             INT NOT NULL,
    id_ingrediente       INT NOT NULL,
    cantidad_necesaria   DECIMAL(8,2) NOT NULL, -- cuanto gasta una pizza de ese ingrediente

    FOREIGN KEY (id_pizza) REFERENCES pizzas(id_pizza),
    FOREIGN KEY (id_ingrediente) REFERENCES ingredientes(id_ingrediente),
    UNIQUE (id_pizza, id_ingrediente) -- no repetir el mismo ingrediente en la misma pizza
) ENGINE = InnoDB;


-- ------------------------------------------------------------
-- TABLA: pedidos
-- ------------------------------------------------------------
CREATE TABLE pedidos (
    id_pedido  INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    -- Si no se manda fecha, MySQL pone la fecha/hora actual sola.
    fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('pendiente', 'en_preparacion', 'entregado', 'cancelado')
           NOT NULL DEFAULT 'pendiente',
    -- Se deja en 0 al crear el pedido; se actualiza despues con
    -- la funcion calcular_total_pedido() (ver funciones.sql).
    total DECIMAL(10,2) NOT NULL DEFAULT 0,

    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
) ENGINE = InnoDB;


-- ------------------------------------------------------------
-- TABLA: detalle_pedido (tabla puente)
-- Que pizzas (con tamano y precio) tiene cada pedido.
-- ------------------------------------------------------------
CREATE TABLE detalle_pedido (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido  INT NOT NULL,
    id_precio  INT NOT NULL,          -- que pizza+tamano se pidio
    cantidad   INT NOT NULL DEFAULT 1,
    -- Se guarda el subtotal (cantidad * precio de ese momento)
    -- para no perder el dato si el precio cambia despues.
    subtotal   DECIMAL(10,2) NOT NULL,

    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido),
    FOREIGN KEY (id_precio) REFERENCES pizza_precios(id_precio)
) ENGINE = InnoDB;


-- ------------------------------------------------------------
-- TABLA: pagos (relacion 1 a 1 con pedidos)
-- ------------------------------------------------------------
CREATE TABLE pagos (
    id_pago     INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido   INT NOT NULL,
    metodo_pago ENUM('efectivo', 'tarjeta', 'app') NOT NULL,
    monto       DECIMAL(10,2) NOT NULL,
    fecha_pago  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido),
    UNIQUE (id_pedido) -- esto obliga a que sea 1 a 1: un pedido, un pago
) ENGINE = InnoDB;


-- ------------------------------------------------------------
-- TABLA: repartidores
-- ------------------------------------------------------------
CREATE TABLE repartidores (
    id_repartidor INT AUTO_INCREMENT PRIMARY KEY,
    nombre        VARCHAR(100) NOT NULL,
    zona          VARCHAR(100) NOT NULL,
    estado        ENUM('disponible', 'no_disponible') NOT NULL DEFAULT 'disponible'
) ENGINE = InnoDB;


-- ------------------------------------------------------------
-- TABLA: domicilios (relacion 1 a 1 con pedidos, ya que todos
-- los pedidos son a domicilio)
-- ------------------------------------------------------------
CREATE TABLE domicilios (
    id_domicilio  INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido     INT NOT NULL,
    id_repartidor INT NOT NULL,
    hora_salida   DATETIME,
    hora_entrega  DATETIME,      -- se llena cuando se completa la entrega
    distancia_km  DECIMAL(6,2),
    costo_envio   DECIMAL(10,2),

    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido),
    FOREIGN KEY (id_repartidor) REFERENCES repartidores(id_repartidor),
    UNIQUE (id_pedido)
) ENGINE = InnoDB;


-- ------------------------------------------------------------
-- TABLA: historial_precios
-- Nadie inserta aqui a mano: la llena el trigger
-- trg_historial_precios (ver triggers.sql) cuando cambia un
-- precio en pizza_precios.
-- ------------------------------------------------------------
CREATE TABLE historial_precios (
    id_historial    INT AUTO_INCREMENT PRIMARY KEY,
    id_precio       INT NOT NULL,
    precio_anterior DECIMAL(10,2) NOT NULL,
    precio_nuevo    DECIMAL(10,2) NOT NULL,
    fecha_cambio    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (id_precio) REFERENCES pizza_precios(id_precio)
) ENGINE = InnoDB;

-- ============================================================
-- FIN de database.sql
-- Orden recomendado: funciones.sql -> triggers.sql -> vistas.sql
-- -> consultas.sql (ver README.md)
-- ============================================================
