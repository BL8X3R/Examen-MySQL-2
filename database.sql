-- ============================================================
-- PIZZERÍA DON PICCOLO - CREACIÓN DE BASE DE DATOS Y DATOS
-- Compatible con MySQL 8.0+
-- ============================================================

DROP DATABASE IF EXISTS pizzeria_don_piccolo;
CREATE DATABASE pizzeria_don_piccolo;
USE pizzeria_don_piccolo;

-- -------------------------
-- 1. CLIENTES
-- -------------------------
CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    direccion VARCHAR(200) NOT NULL,
    correo VARCHAR(120) UNIQUE,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- -------------------------
-- 2. PIZZAS
-- -------------------------
CREATE TABLE pizzas (
    id_pizza INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    tamano ENUM('pequena','mediana','grande') NOT NULL,
    precio_base DECIMAL(10,2) NOT NULL,
    tipo ENUM('vegetariana','especial','clasica') NOT NULL,
    disponible BOOLEAN NOT NULL DEFAULT TRUE,
    CHECK (precio_base >= 0)
);

-- -------------------------
-- 3. INGREDIENTES
-- -------------------------
CREATE TABLE ingredientes (
    id_ingrediente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    unidad_medida VARCHAR(20) NOT NULL,
    stock DECIMAL(10,2) NOT NULL DEFAULT 0,
    stock_minimo DECIMAL(10,2) NOT NULL DEFAULT 0,
    costo_unitario DECIMAL(10,2) NOT NULL,
    disponible BOOLEAN NOT NULL DEFAULT TRUE,
    CHECK (stock >= 0),
    CHECK (stock_minimo >= 0),
    CHECK (costo_unitario >= 0)
);

-- -------------------------
-- 4. RELACIÓN PIZZA-INGREDIENTE (N:M)
-- -------------------------
CREATE TABLE pizza_ingredientes (
    id_pizza INT NOT NULL,
    id_ingrediente INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id_pizza, id_ingrediente),
    FOREIGN KEY (id_pizza) REFERENCES pizzas(id_pizza),
    FOREIGN KEY (id_ingrediente) REFERENCES ingredientes(id_ingrediente),
    CHECK (cantidad > 0)
);

-- -------------------------
-- 5. REPARTIDORES
-- -------------------------
CREATE TABLE repartidores (
    id_repartidor INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    zona_asignada VARCHAR(100) NOT NULL,
    estado ENUM('disponible','no disponible') NOT NULL DEFAULT 'disponible'
);

-- -------------------------
-- 6. PEDIDOS
-- -------------------------
CREATE TABLE pedidos (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    metodo_pago ENUM('efectivo','tarjeta','app') NOT NULL,
    estado ENUM('pendiente','en preparacion','entregado','cancelado') NOT NULL DEFAULT 'pendiente',
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

-- -------------------------
-- 7. DETALLE DE PEDIDO
-- Guarda las pizzas y cantidades de cada pedido.
-- El precio_unitario conserva el precio al momento de comprar.
-- -------------------------
CREATE TABLE detalle_pedido (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL,
    id_pizza INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido),
    FOREIGN KEY (id_pizza) REFERENCES pizzas(id_pizza),
    CHECK (cantidad > 0),
    CHECK (precio_unitario >= 0)
);

-- -------------------------
-- 8. DOMICILIOS
-- Un pedido puede tener como máximo un domicilio.
-- -------------------------
CREATE TABLE domicilios (
    id_domicilio INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL UNIQUE,
    id_repartidor INT NOT NULL,
    hora_salida DATETIME NULL,
    hora_entrega DATETIME NULL,
    distancia_km DECIMAL(6,2) NOT NULL,
    costo_envio DECIMAL(10,2) NOT NULL,
    zona VARCHAR(100) NOT NULL,
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido),
    FOREIGN KEY (id_repartidor) REFERENCES repartidores(id_repartidor),
    CHECK (distancia_km >= 0),
    CHECK (costo_envio >= 0)
);

-- -------------------------
-- 9. PAGOS
-- -------------------------
CREATE TABLE pagos (
    id_pago INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL UNIQUE,
    fecha_pago DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    monto DECIMAL(10,2) NOT NULL,
    estado ENUM('pendiente','pagado','rechazado') NOT NULL DEFAULT 'pendiente',
    referencia VARCHAR(100) NULL,
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido),
    CHECK (monto >= 0)
);

-- -------------------------
-- 10. HISTORIAL DE PRECIOS
-- -------------------------
CREATE TABLE historial_precios (
    id_historial INT AUTO_INCREMENT PRIMARY KEY,
    id_pizza INT NOT NULL,
    precio_anterior DECIMAL(10,2) NOT NULL,
    precio_nuevo DECIMAL(10,2) NOT NULL,
    fecha_cambio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_pizza) REFERENCES pizzas(id_pizza)
);

-- ============================================================
-- DATOS DE PRUEBA
-- ============================================================

INSERT INTO clientes (nombre, telefono, direccion, correo) VALUES
('Ana Gómez','3001112233','Cra 10 # 12-20','ana@gmail.com'),
('Carlos Pérez','3012223344','Calle 8 # 15-10','carlos@gmail.com'),
('María Rodríguez','3023334455','Cra 5 # 20-11','maria@gmail.com'),
('Juan Torres','3034445566','Calle 12 # 9-30','juan@gmail.com'),
('Laura Martínez','3045556677','Cra 14 # 18-05','laura@gmail.com'),
('Sofía Ramírez','3056667788','Calle 6 # 11-22','sofia@gmail.com');

INSERT INTO pizzas (nombre, tamano, precio_base, tipo) VALUES
('Margarita','mediana',28000,'clasica'),
('Pepperoni','mediana',32000,'clasica'),
('Vegetariana','grande',36000,'vegetariana'),
('Pollo BBQ','grande',42000,'especial'),
('Hawaiana','mediana',34000,'especial'),
('Cuatro Quesos','grande',44000,'especial');

INSERT INTO ingredientes (nombre, unidad_medida, stock, stock_minimo, costo_unitario) VALUES
('Masa','unidad',100,20,4000),
('Salsa de tomate','ml',10000,2000,8),
('Queso mozzarella','g',20000,5000,25),
('Pepperoni','g',8000,1500,35),
('Tomate','g',8000,1500,12),
('Champiñones','g',6000,1000,20),
('Pimentón','g',6000,1000,15),
('Pollo','g',10000,2000,28),
('Salsa BBQ','ml',5000,1000,18),
('Piña','g',5000,1000,14),
('Jamón','g',7000,1200,30),
('Queso azul','g',4000,800,45);

INSERT INTO pizza_ingredientes (id_pizza,id_ingrediente,cantidad) VALUES
(1,1,1),(1,2,80),(1,3,180),(1,5,80),
(2,1,1),(2,2,80),(2,3,180),(2,4,100),
(3,1,1),(3,2,100),(3,3,200),(3,5,80),(3,6,70),(3,7,60),
(4,1,1),(4,2,100),(4,3,200),(4,8,180),(4,9,40),
(5,1,1),(5,2,80),(5,3,180),(5,10,100),(5,11,100),
(6,1,1),(6,2,100),(6,3,180),(6,12,70);

INSERT INTO repartidores (nombre,zona_asignada,estado) VALUES
('Pedro López','Centro','disponible'),
('Andrés Silva','Norte','disponible'),
('Camilo Díaz','Sur','disponible'),
('Mateo Rojas','Occidente','disponible');

-- Pedidos de Ana: 6 en septiembre para demostrar cliente frecuente.
INSERT INTO pedidos (id_cliente,fecha_hora,metodo_pago,estado) VALUES
(1,'2026-09-01 12:10:00','app','entregado'),
(1,'2026-09-03 18:20:00','tarjeta','entregado'),
(1,'2026-09-06 19:10:00','efectivo','entregado'),
(1,'2026-09-10 13:30:00','app','entregado'),
(1,'2026-09-15 20:00:00','tarjeta','entregado'),
(1,'2026-09-20 19:30:00','app','entregado'),
(2,'2026-09-02 14:00:00','efectivo','entregado'),
(3,'2026-09-05 18:45:00','tarjeta','entregado'),
(4,'2026-09-08 19:00:00','app','entregado'),
(5,'2026-09-12 12:30:00','efectivo','entregado'),
(6,'2026-09-18 19:20:00','tarjeta','entregado'),
(2,'2026-09-19 20:15:00','app','entregado');

INSERT INTO detalle_pedido (id_pedido,id_pizza,cantidad,precio_unitario) VALUES
(1,1,1,28000),(2,2,1,32000),(3,3,1,36000),(4,4,1,42000),(5,5,1,34000),(6,6,1,44000),
(7,2,2,32000),(8,3,1,36000),(9,4,2,42000),(10,5,1,34000),(11,2,1,32000),(12,1,2,28000);

INSERT INTO domicilios (id_pedido,id_repartidor,hora_salida,hora_entrega,distancia_km,costo_envio,zona) VALUES
(1,1,'2026-09-01 12:30:00','2026-09-01 12:55:00',2.5,5000,'Centro'),
(2,2,'2026-09-03 18:40:00','2026-09-03 19:10:00',4.0,7000,'Norte'),
(3,3,'2026-09-06 19:30:00','2026-09-06 20:00:00',3.5,6000,'Sur'),
(4,1,'2026-09-10 13:50:00','2026-09-10 14:15:00',2.0,5000,'Centro'),
(5,4,'2026-09-15 20:20:00','2026-09-15 20:55:00',5.0,8000,'Occidente'),
(6,2,'2026-09-20 19:50:00','2026-09-20 20:20:00',4.5,7000,'Norte'),
(7,3,'2026-09-02 14:20:00','2026-09-02 14:45:00',3.0,6000,'Sur'),
(8,1,'2026-09-05 19:00:00','2026-09-05 19:25:00',2.2,5000,'Centro'),
(9,4,'2026-09-08 19:20:00','2026-09-08 20:00:00',5.5,9000,'Occidente'),
(10,3,'2026-09-12 12:50:00','2026-09-12 13:15:00',3.2,6000,'Sur'),
(11,2,'2026-09-18 19:40:00','2026-09-18 20:05:00',4.2,7000,'Norte'),
(12,1,'2026-09-19 20:35:00','2026-09-19 21:00:00',2.4,5000,'Centro');

-- Los pagos de prueba se calculan después de crear la función.
