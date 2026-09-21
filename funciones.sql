-- ============================================================
-- ARCHIVO: funciones.sql
-- Funciones (devuelven un valor) y procedimiento (ejecuta una
-- accion) del sistema.
-- ============================================================

USE pizzeria_don_piccolo;

-- Cambiamos el delimitador de ";" a "$$" porque el codigo de
-- adentro ya usa ";" para separar sus propias instrucciones, y
-- no queremos que MySQL corte el bloque antes de tiempo.
DELIMITER $$


-- ------------------------------------------------------------
-- FUNCION: calcular_total_pedido
-- Recibe el id de un pedido y devuelve lo que hay que cobrar:
-- (suma de pizzas + costo de envio) + 19% de IVA.
-- ------------------------------------------------------------
CREATE FUNCTION calcular_total_pedido(p_id_pedido INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC     -- con la misma entrada, siempre da el mismo resultado
READS SQL DATA    -- avisa que solo lee datos, no los modifica
BEGIN
    DECLARE v_subtotal_pizzas DECIMAL(10,2);
    DECLARE v_costo_envio     DECIMAL(10,2);
    DECLARE v_total           DECIMAL(10,2);

    -- Suma el subtotal de todas las pizzas de ese pedido
    SELECT IFNULL(SUM(subtotal), 0) INTO v_subtotal_pizzas
    FROM detalle_pedido
    WHERE id_pedido = p_id_pedido;

    -- Busca el costo de envio de ese pedido
    SELECT IFNULL(costo_envio, 0) INTO v_costo_envio
    FROM domicilios
    WHERE id_pedido = p_id_pedido;

    -- (pizzas + envio) mas 19% de IVA
    SET v_total = (v_subtotal_pizzas + v_costo_envio) * 1.19;

    RETURN v_total;
END$$


-- ------------------------------------------------------------
-- FUNCION: ganancia_neta_diaria
-- Recibe una fecha y devuelve: ventas del dia - costo de los
-- ingredientes usados ese dia. Solo cuenta pedidos entregados.
-- ------------------------------------------------------------
CREATE FUNCTION ganancia_neta_diaria(p_fecha DATE)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_ventas   DECIMAL(10,2);
    DECLARE v_costos   DECIMAL(10,2);
    DECLARE v_ganancia DECIMAL(10,2);

    -- Total vendido ese dia (pedidos ya entregados)
    SELECT IFNULL(SUM(total), 0) INTO v_ventas
    FROM pedidos
    WHERE DATE(fecha_hora) = p_fecha
      AND estado = 'entregado';

    -- Costo de los ingredientes gastados: por cada pizza vendida
    -- busca su receta (pizza_ingredientes) y multiplica la
    -- cantidad usada por el costo unitario de cada ingrediente.
    SELECT IFNULL(SUM(dp.cantidad * pi.cantidad_necesaria * i.costo_unitario), 0)
    INTO v_costos
    FROM detalle_pedido dp
    INNER JOIN pedidos p             ON dp.id_pedido = p.id_pedido
    INNER JOIN pizza_precios pp      ON dp.id_precio = pp.id_precio
    INNER JOIN pizza_ingredientes pi ON pp.id_pizza = pi.id_pizza
    INNER JOIN ingredientes i        ON pi.id_ingrediente = i.id_ingrediente
    WHERE DATE(p.fecha_hora) = p_fecha
      AND p.estado = 'entregado';

    SET v_ganancia = v_ventas - v_costos;

    RETURN v_ganancia;
END$$


-- ------------------------------------------------------------
-- PROCEDIMIENTO: registrar_entrega
-- Se llama cuando el repartidor entrega el pedido. Registra la
-- hora de entrega y cambia el estado del pedido a "entregado".
-- ------------------------------------------------------------
CREATE PROCEDURE registrar_entrega(
    IN p_id_domicilio INT,      -- que domicilio se esta entregando
    IN p_hora_entrega DATETIME  -- a que hora se entrego
)
BEGIN
    DECLARE v_id_pedido INT; -- a que pedido pertenece este domicilio

    -- 1) Guarda la hora de entrega en domicilios
    UPDATE domicilios
    SET hora_entrega = p_hora_entrega
    WHERE id_domicilio = p_id_domicilio;

    -- 2) Busca a que pedido pertenece ese domicilio
    SELECT id_pedido INTO v_id_pedido
    FROM domicilios
    WHERE id_domicilio = p_id_domicilio;

    -- 3) Cambia el estado del pedido a "entregado"
    UPDATE pedidos
    SET estado = 'entregado'
    WHERE id_pedido = v_id_pedido;
END$$

-- Regresamos el delimitador a ";" como estaba al inicio.
DELIMITER ;
