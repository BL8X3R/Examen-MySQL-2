-- ============================================================
-- ARCHIVO: vistas.sql
-- Una vista es una "consulta guardada" que se comporta como si
-- fuera una tabla. Sirve para no repetir el mismo JOIN largo
-- cada vez que se necesita ese reporte.
-- ============================================================

USE pizzeria_don_piccolo;

-- ------------------------------------------------------------
-- VISTA 1: vista_resumen_pedidos_cliente
-- Por cada cliente: cuantos pedidos ha hecho y cuanto ha gastado.
-- ------------------------------------------------------------
CREATE VIEW vista_resumen_pedidos_cliente AS
SELECT
    c.id_cliente,
    c.nombre AS nombre_cliente,
    COUNT(p.id_pedido)       AS cantidad_pedidos,
    IFNULL(SUM(p.total), 0)  AS total_gastado
FROM clientes c
LEFT JOIN pedidos p ON c.id_cliente = p.id_cliente -- LEFT JOIN: no perder clientes sin pedidos
GROUP BY c.id_cliente, c.nombre;


-- ------------------------------------------------------------
-- VISTA 2: vista_desempeno_repartidores
-- Por cada repartidor: cuantas entregas hizo, su tiempo
-- promedio de entrega (en minutos) y su zona.
-- ------------------------------------------------------------
CREATE VIEW vista_desempeno_repartidores AS
SELECT
    r.id_repartidor,
    r.nombre AS nombre_repartidor,
    r.zona,
    COUNT(d.id_domicilio) AS cantidad_entregas,
    -- TIMESTAMPDIFF calcula minutos entre salida y entrega;
    -- AVG saca el promedio de todos esos tiempos.
    AVG(TIMESTAMPDIFF(MINUTE, d.hora_salida, d.hora_entrega)) AS tiempo_promedio_minutos
FROM repartidores r
LEFT JOIN domicilios d
       ON r.id_repartidor = d.id_repartidor
      AND d.hora_entrega IS NOT NULL -- solo domicilios ya entregados
GROUP BY r.id_repartidor, r.nombre, r.zona;


-- ------------------------------------------------------------
-- VISTA 3: vista_stock_bajo
-- Ingredientes cuyo stock actual esta en o por debajo del
-- minimo permitido (sirve para saber que reabastecer).
-- ------------------------------------------------------------
CREATE VIEW vista_stock_bajo AS
SELECT
    id_ingrediente,
    nombre,
    stock,
    stock_minimo
FROM ingredientes
WHERE stock <= stock_minimo;
