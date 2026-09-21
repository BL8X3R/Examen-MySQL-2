-- ============================================================
-- ARCHIVO: triggers.sql
-- Un trigger es codigo que se ejecuta SOLO cuando pasa algo
-- especifico en una tabla (INSERT o UPDATE), sin que nadie lo
-- tenga que llamar a mano.
-- ============================================================

USE pizzeria_don_piccolo;

DELIMITER $$


-- ------------------------------------------------------------
-- TRIGGER 1: trg_actualizar_stock
-- Se activa DESPUES de insertar en detalle_pedido (alguien pide
-- una pizza). Descuenta del stock de ingredientes lo que se
-- gasta en preparar esa pizza, segun su receta.
-- ------------------------------------------------------------
CREATE TRIGGER trg_actualizar_stock
AFTER INSERT ON detalle_pedido
FOR EACH ROW
BEGIN
    -- UPDATE con JOIN: por cada ingrediente que necesita la
    -- pizza pedida (NEW.id_precio dice cual pizza y tamano fue),
    -- le restamos stock segun la receta (cantidad_necesaria)
    -- multiplicada por cuantas pizzas se pidieron (NEW.cantidad).
    UPDATE ingredientes i
    INNER JOIN pizza_ingredientes pi ON i.id_ingrediente = pi.id_ingrediente
    INNER JOIN pizza_precios pp ON pi.id_pizza = pp.id_pizza
    SET i.stock = i.stock - (pi.cantidad_necesaria * NEW.cantidad)
    WHERE pp.id_precio = NEW.id_precio;
END$$


-- ------------------------------------------------------------
-- TRIGGER 2: trg_historial_precios
-- Se activa DESPUES de actualizar un precio en pizza_precios.
-- Si el precio realmente cambio, guarda el cambio en
-- historial_precios (auditoria).
-- ------------------------------------------------------------
CREATE TRIGGER trg_historial_precios
AFTER UPDATE ON pizza_precios
FOR EACH ROW
BEGIN
    -- Solo registramos si el precio nuevo es distinto al viejo
    IF OLD.precio <> NEW.precio THEN
        INSERT INTO historial_precios (id_precio, precio_anterior, precio_nuevo, fecha_cambio)
        VALUES (NEW.id_precio, OLD.precio, NEW.precio, NOW());
    END IF;
END$$


-- ------------------------------------------------------------
-- TRIGGER 3: trg_repartidor_disponible
-- Se activa DESPUES de actualizar un domicilio. Cuando se
-- registra la hora_entrega (antes estaba vacia, ahora tiene
-- valor), el repartidor vuelve a quedar "disponible".
-- ------------------------------------------------------------
CREATE TRIGGER trg_repartidor_disponible
AFTER UPDATE ON domicilios
FOR EACH ROW
BEGIN
    -- OLD.hora_entrega IS NULL: antes no estaba entregado
    -- NEW.hora_entrega IS NOT NULL: ahora ya se registro
    IF OLD.hora_entrega IS NULL AND NEW.hora_entrega IS NOT NULL THEN
        UPDATE repartidores
        SET estado = 'disponible'
        WHERE id_repartidor = NEW.id_repartidor;
    END IF;
END$$

DELIMITER ;
