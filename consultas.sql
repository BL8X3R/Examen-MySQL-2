-- ============================================================
-- ARCHIVO: consultas.sql
-- Consultas SQL que pide el negocio, usando JOIN, subconsultas,
-- agregaciones y otros operadores.
-- ============================================================

USE pizzeria_don_piccolo;

-- ------------------------------------------------------------
-- 1) Clientes con pedidos entre dos fechas (BETWEEN)
-- Cambia las fechas por el rango que quieras consultar.
-- ------------------------------------------------------------
SELECT
    c.nombre AS cliente,
    p.id_pedido,
    p.fecha_hora
FROM pedidos p
INNER JOIN clientes c ON p.id_cliente = c.id_cliente
WHERE p.fecha_hora BETWEEN '2025-01-01 00:00:00' AND '2025-01-31 23:59:59';


-- ------------------------------------------------------------
-- 2) Pizzas mas vendidas (GROUP BY y COUNT)
-- ------------------------------------------------------------
SELECT
    pz.nombre AS pizza,
    COUNT(dp.id_detalle) AS veces_vendida
FROM detalle_pedido dp
INNER JOIN pizza_precios pp ON dp.id_precio = pp.id_precio
INNER JOIN pizzas pz        ON pp.id_pizza = pz.id_pizza
GROUP BY pz.id_pizza, pz.nombre
ORDER BY veces_vendida DESC;


-- ------------------------------------------------------------
-- 3) Pedidos por repartidor (JOIN)
-- ------------------------------------------------------------
SELECT
    r.nombre AS repartidor,
    d.id_domicilio,
    d.id_pedido
FROM domicilios d
INNER JOIN repartidores r ON d.id_repartidor = r.id_repartidor
ORDER BY r.nombre;


-- ------------------------------------------------------------
-- 4) Promedio de tiempo de entrega por zona (AVG y JOIN)
-- ------------------------------------------------------------
SELECT
    r.zona,
    AVG(TIMESTAMPDIFF(MINUTE, d.hora_salida, d.hora_entrega)) AS promedio_minutos
FROM domicilios d
INNER JOIN repartidores r ON d.id_repartidor = r.id_repartidor
WHERE d.hora_entrega IS NOT NULL
GROUP BY r.zona;


-- ------------------------------------------------------------
-- 5) Clientes que gastaron mas de un monto (HAVING)
-- HAVING filtra DESPUES de agrupar (a diferencia de WHERE, que
-- filtra antes de agrupar).
-- ------------------------------------------------------------
SELECT
    c.nombre AS cliente,
    SUM(p.total) AS total_gastado
FROM clientes c
INNER JOIN pedidos p ON c.id_cliente = p.id_cliente
GROUP BY c.id_cliente, c.nombre
HAVING SUM(p.total) > 100000; -- cambia este monto segun lo que necesites


-- ------------------------------------------------------------
-- 6) Busqueda por coincidencia parcial de nombre de pizza (LIKE)
-- El simbolo % significa "cualquier cosa antes o despues".
-- ------------------------------------------------------------
SELECT *
FROM pizzas
WHERE nombre LIKE '%pepperoni%';


-- ------------------------------------------------------------
-- 7) Clientes frecuentes: mas de 5 pedidos en el mes actual
-- (subconsulta)
-- La subconsulta de adentro calcula primero los ids de los
-- clientes frecuentes; la de afuera trae sus datos completos.
-- ------------------------------------------------------------
SELECT *
FROM clientes
WHERE id_cliente IN (
    SELECT id_cliente
    FROM pedidos
    WHERE MONTH(fecha_hora) = MONTH(CURDATE())
      AND YEAR(fecha_hora) = YEAR(CURDATE())
    GROUP BY id_cliente
    HAVING COUNT(id_pedido) > 5
);
