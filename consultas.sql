-- ============================================================
-- CONSULTAS SQL REQUERIDAS - PIZZERÍA DON PICCOLO
-- ============================================================
USE pizzeria_don_piccolo;

-- 1. Clientes con pedidos entre dos fechas (BETWEEN).
SELECT
    c.nombre,
    c.telefono,
    p.id_pedido,
    p.fecha_hora,
    p.estado
FROM clientes c
JOIN pedidos p ON p.id_cliente = c.id_cliente
WHERE p.fecha_hora BETWEEN '2026-09-01 00:00:00' AND '2026-09-30 23:59:59'
ORDER BY p.fecha_hora;

-- 2. Pizzas más vendidas (GROUP BY + COUNT).
SELECT
    p.nombre,
    SUM(dp.cantidad) AS unidades_vendidas
FROM pizzas p
JOIN detalle_pedido dp ON dp.id_pizza = p.id_pizza
JOIN pedidos pe ON pe.id_pedido = dp.id_pedido
WHERE pe.estado <> 'cancelado'
GROUP BY p.id_pizza, p.nombre
ORDER BY unidades_vendidas DESC;

-- 3. Pedidos por repartidor (JOIN).
SELECT
    r.nombre AS repartidor,
    r.zona_asignada,
    d.id_domicilio,
    d.id_pedido,
    d.hora_salida,
    d.hora_entrega
FROM repartidores r
JOIN domicilios d ON d.id_repartidor = r.id_repartidor
ORDER BY r.nombre, d.hora_salida;

-- 4. Promedio de entrega por zona (AVG + JOIN).
SELECT
    d.zona,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, d.hora_salida, d.hora_entrega)), 2) AS promedio_minutos
FROM domicilios d
JOIN pedidos p ON p.id_pedido = d.id_pedido
WHERE d.hora_salida IS NOT NULL
  AND d.hora_entrega IS NOT NULL
GROUP BY d.zona
ORDER BY promedio_minutos;

-- 5. Clientes que gastaron más de un monto (HAVING).
-- Cambia 100000 por el monto que quieras analizar.
SELECT
    c.id_cliente,
    c.nombre,
    ROUND(SUM(calcular_total_pedido(p.id_pedido)), 2) AS total_gastado
FROM clientes c
JOIN pedidos p ON p.id_cliente = c.id_cliente
WHERE p.estado <> 'cancelado'
GROUP BY c.id_cliente, c.nombre
HAVING total_gastado > 100000
ORDER BY total_gastado DESC;

-- 6. Búsqueda parcial del nombre de pizza (LIKE).
-- Busca pizzas que contengan la palabra 'queso'.
SELECT id_pizza, nombre, tamano, precio_base, tipo
FROM pizzas
WHERE nombre LIKE '%queso%';

-- 7. Clientes frecuentes: más de 5 pedidos en el mismo mes.
-- Subconsulta + GROUP BY + HAVING.
SELECT
    c.id_cliente,
    c.nombre
FROM clientes c
WHERE c.id_cliente IN (
    SELECT p.id_cliente
    FROM pedidos p
    WHERE p.estado <> 'cancelado'
    GROUP BY p.id_cliente, YEAR(p.fecha_hora), MONTH(p.fecha_hora)
    HAVING COUNT(*) > 5
);

-- 8. Consultar el total de un pedido usando la función.
SELECT
    id_pedido,
    calcular_total_pedido(id_pedido) AS total_con_iva_y_envio
FROM pedidos
ORDER BY id_pedido;

-- 9. Ganancia neta de un día.
SELECT calcular_ganancia_neta_diaria('2026-09-01') AS ganancia_neta;

-- 10. Ver las tres vistas creadas.
SELECT * FROM vista_resumen_pedidos_cliente;
SELECT * FROM vista_desempeno_repartidores;
SELECT * FROM vista_stock_bajo;

-- 11. Ver historial de cambios de precios.
SELECT * FROM historial_precios ORDER BY fecha_cambio DESC;

-- 12. Ejemplo para probar el trigger de historial:
-- UPDATE pizzas SET precio_base = 30000 WHERE id_pizza = 1;
-- SELECT * FROM historial_precios WHERE id_pizza = 1;

-- 13. Ejemplo para probar el procedimiento de entrega:
-- CALL registrar_entrega(1, '2026-09-21 12:30:00');
-- SELECT * FROM pedidos WHERE id_pedido = 1;
-- SELECT * FROM repartidores WHERE id_repartidor = 1;
