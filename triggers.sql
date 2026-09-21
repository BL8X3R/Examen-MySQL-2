-- ============================================================
-- TRIGGERS Y PROCEDIMIENTOS - PIZZERÍA DON PICCOLO
-- ============================================================
USE pizzeria_don_piccolo;

-- ------------------------------------------------------------
-- 1. Evita vender una pizza si algún ingrediente no alcanza.
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_validar_stock;
DELIMITER $$
CREATE TRIGGER trg_validar_stock
BEFORE INSERT ON detalle_pedido
FOR EACH ROW
BEGIN
    DECLARE v_faltantes INT DEFAULT 0;

    SELECT COUNT(*)
      INTO v_faltantes
      FROM pizza_ingredientes pi
      JOIN ingredientes i ON i.id_ingrediente = pi.id_ingrediente
     WHERE pi.id_pizza = NEW.id_pizza
       AND i.stock < (pi.cantidad * NEW.cantidad);

    IF v_faltantes > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No hay suficiente stock para preparar esta pizza.';
    END IF;
END$$
DELIMITER ;

-- ------------------------------------------------------------
-- 2. Descuenta ingredientes automáticamente al registrar una
--    pizza dentro de un pedido.
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_descontar_stock;
DELIMITER $$
CREATE TRIGGER trg_descontar_stock
AFTER INSERT ON detalle_pedido
FOR EACH ROW
BEGIN
    UPDATE ingredientes i
    JOIN pizza_ingredientes pi ON pi.id_ingrediente = i.id_ingrediente
       SET i.stock = i.stock - (pi.cantidad * NEW.cantidad)
     WHERE pi.id_pizza = NEW.id_pizza;
END$$
DELIMITER ;

-- ------------------------------------------------------------
-- 3. Guarda el precio anterior y el nuevo cuando cambia una
--    pizza.
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_historial_precio;
DELIMITER $$
CREATE TRIGGER trg_historial_precio
AFTER UPDATE ON pizzas
FOR EACH ROW
BEGIN
    IF OLD.precio_base <> NEW.precio_base THEN
        INSERT INTO historial_precios
            (id_pizza, precio_anterior, precio_nuevo)
        VALUES
            (NEW.id_pizza, OLD.precio_base, NEW.precio_base);
    END IF;
END$$
DELIMITER ;

-- ------------------------------------------------------------
-- 4. Procedimiento para registrar una entrega.
--    Cambia domicilio, pedido y estado del repartidor.
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS registrar_entrega;
DELIMITER $$
CREATE PROCEDURE registrar_entrega(
    IN p_id_domicilio INT,
    IN p_hora_entrega DATETIME
)
BEGIN
    DECLARE v_pedido INT;
    DECLARE v_repartidor INT;

    SELECT id_pedido, id_repartidor
      INTO v_pedido, v_repartidor
      FROM domicilios
     WHERE id_domicilio = p_id_domicilio;

    UPDATE domicilios
       SET hora_entrega = p_hora_entrega
     WHERE id_domicilio = p_id_domicilio;

    UPDATE pedidos
       SET estado = 'entregado'
     WHERE id_pedido = v_pedido;

    UPDATE repartidores
       SET estado = 'disponible'
     WHERE id_repartidor = v_repartidor;
END$$
DELIMITER ;

-- ------------------------------------------------------------
-- 5. Si se registra hora de entrega directamente en domicilios,
--    el pedido pasa a entregado y el repartidor queda disponible.
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_entrega_domicilio;
DELIMITER $$
CREATE TRIGGER trg_entrega_domicilio
AFTER UPDATE ON domicilios
FOR EACH ROW
BEGIN
    IF OLD.hora_entrega IS NULL AND NEW.hora_entrega IS NOT NULL THEN
        UPDATE pedidos
           SET estado = 'entregado'
         WHERE id_pedido = NEW.id_pedido;

        UPDATE repartidores
           SET estado = 'disponible'
         WHERE id_repartidor = NEW.id_repartidor;
    END IF;
END$$
DELIMITER ;

-- ------------------------------------------------------------
-- 6. Cuando se asigna un domicilio a un repartidor, se marca
--    como no disponible mientras realiza la entrega.
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_repartidor_asignado;
DELIMITER $$
CREATE TRIGGER trg_repartidor_asignado
AFTER INSERT ON domicilios
FOR EACH ROW
BEGIN
    UPDATE repartidores
       SET estado = 'no disponible'
     WHERE id_repartidor = NEW.id_repartidor;
END$$
DELIMITER ;
