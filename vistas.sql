-- ============================================================
-- VISTAS - PIZZERÍA DON PICCOLO
-- ============================================================
USE pizzeria_don_piccolo;

-- 1. Resumen de pedidos por cliente.
DROP VIEW IF EXISTS vista_resumen_pedidos_cliente;
CREATE VIEW vista_resumen_pedidos_cliente AS
SELECT
    c.id_cliente,
    c.nombre,
    COUNT(DISTINCT p.id_pedido) AS cantidad_pedidos,
    COALESCE(SUM(calcular_total_pedido(p.id_pedido)), 0) AS total_gastado
FROM clientes c
LEFT JOIN pedidos p ON p.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nombre;

-- 2. Desempeño de repartidores.
DROP VIEW IF EXISTS vista_desempeno_repartidores;
CREATE VIEW vista_desempeno_repartidores AS
SELECT
    r.id_repartidor,
    r.nombre,
    r.zona_asignada AS zona,
    COUNT(d.id_domicilio) AS numero_entregas,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, d.hora_salida, d.hora_entrega)), 2) AS tiempo_promedio_minutos
FROM repartidores r
LEFT JOIN domicilios d ON d.id_repartidor = r.id_repartidor
                         AND d.hora_entrega IS NOT NULL
GROUP BY r.id_repartidor, r.nombre, r.zona_asignada;

-- 3. Ingredientes por debajo del mínimo permitido.
DROP VIEW IF EXISTS vista_stock_bajo;
CREATE VIEW vista_stock_bajo AS
SELECT
    id_ingrediente,
    nombre,
    unidad_medida,
    stock,
    stock_minimo,
    (stock_minimo - stock) AS cantidad_faltante,
    disponible
FROM ingredientes
WHERE stock < stock_minimo;
