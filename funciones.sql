-- ============================================================
-- FUNCIONES - PIZZERÍA DON PICCOLO
-- ============================================================
USE pizzeria_don_piccolo;

DROP FUNCTION IF EXISTS calcular_total_pedido;
DELIMITER $$
CREATE FUNCTION calcular_total_pedido(p_id_pedido INT)
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
    DECLARE v_subtotal DECIMAL(12,2) DEFAULT 0;
    DECLARE v_envio DECIMAL(12,2) DEFAULT 0;
    DECLARE v_iva DECIMAL(12,2) DEFAULT 0;

    SELECT COALESCE(SUM(cantidad * precio_unitario), 0)
      INTO v_subtotal
      FROM detalle_pedido
     WHERE id_pedido = p_id_pedido;

    SELECT COALESCE(costo_envio, 0)
      INTO v_envio
      FROM domicilios
     WHERE id_pedido = p_id_pedido;

    -- IVA del 19% aplicado al subtotal de pizzas + domicilio.
    SET v_iva = (v_subtotal + v_envio) * 0.19;

    RETURN ROUND(v_subtotal + v_envio + v_iva, 2);
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS calcular_ganancia_neta_diaria;
DELIMITER $$
CREATE FUNCTION calcular_ganancia_neta_diaria(p_fecha DATE)
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
    DECLARE v_ventas DECIMAL(12,2) DEFAULT 0;
    DECLARE v_costos DECIMAL(12,2) DEFAULT 0;

    SELECT COALESCE(SUM(calcular_total_pedido(p.id_pedido)), 0)
      INTO v_ventas
      FROM pedidos p
     WHERE DATE(p.fecha_hora) = p_fecha
       AND p.estado <> 'cancelado';

    SELECT COALESCE(SUM(dp.cantidad * pi.cantidad * i.costo_unitario), 0)
      INTO v_costos
      FROM pedidos p
      JOIN detalle_pedido dp ON dp.id_pedido = p.id_pedido
      JOIN pizza_ingredientes pi ON pi.id_pizza = dp.id_pizza
      JOIN ingredientes i ON i.id_ingrediente = pi.id_ingrediente
     WHERE DATE(p.fecha_hora) = p_fecha
       AND p.estado <> 'cancelado';

    RETURN ROUND(v_ventas - v_costos, 2);
END$$
DELIMITER ;

-- Esta consulta auxiliar muestra el cálculo de una fecha de ejemplo:
-- SELECT calcular_ganancia_neta_diaria('2026-09-01');

-- Completar los pagos de prueba usando la función.
INSERT INTO pagos (id_pedido, monto, estado, referencia)
SELECT p.id_pedido, calcular_total_pedido(p.id_pedido), 'pagado', CONCAT('DEMO-', p.id_pedido)
FROM pedidos p;
