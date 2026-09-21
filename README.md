# 🍕 Pizzería Don Piccolo - Sistema de Gestión de Pedidos y Domicilios

Proyecto de base de datos relacional desarrollado en **MySQL 8.0+** para controlar clientes, pizzas, ingredientes, pedidos, pagos, repartidores y domicilios.

## 1. ¿Qué problema resuelve?

La pizzería actualmente registra los pedidos de forma manual. Esto puede producir errores, pérdida de información y retrasos.

La base de datos organiza todo el proceso:

**Cliente → Pedido → Detalle del pedido → Pizza → Ingredientes**

Y, cuando existe domicilio:

**Pedido → Domicilio → Repartidor → Entrega → Pago**

---

## 2. Estructura de archivos

```text
pizzeria-don-piccolo/
├── database.sql
├── funciones.sql
├── triggers.sql
├── vistas.sql
├── consultas.sql
└── README.md
```

### ¿Para qué sirve cada archivo?

- `database.sql`: crea la base de datos, las tablas, relaciones y datos de prueba.
- `funciones.sql`: contiene las funciones para calcular totales y ganancias.
- `triggers.sql`: contiene los triggers y el procedimiento de entrega.
- `vistas.sql`: contiene las vistas utilizadas para reportes.
- `consultas.sql`: contiene las consultas solicitadas en el ejercicio.
- `README.md`: explica el proyecto y cómo ejecutarlo.

---

## 3. Tablas principales

### `clientes`
Guarda los datos de las personas que realizan pedidos.

Campos importantes:
- `id_cliente`: identificador único.
- `nombre`: nombre del cliente.
- `telefono`: teléfono.
- `direccion`: dirección para el domicilio.
- `correo`: correo electrónico.

### `pizzas`
Guarda las pizzas disponibles.

Campos importantes:
- `id_pizza`: identificador.
- `nombre`: nombre de la pizza.
- `tamano`: pequeña, mediana o grande.
- `precio_base`: precio de venta.
- `tipo`: vegetariana, especial o clásica.

### `ingredientes`
Controla el inventario.

- `stock`: cantidad disponible.
- `stock_minimo`: cantidad mínima deseada.
- `costo_unitario`: costo del ingrediente para calcular la ganancia.

### `pizza_ingredientes`
Es una tabla intermedia porque una pizza tiene varios ingredientes y un ingrediente puede pertenecer a varias pizzas.

Esto representa una relación **muchos a muchos (N:M)**.

### `pedidos`
Representa la compra realizada por un cliente.

Contiene fecha, método de pago y estado.

### `detalle_pedido`
Indica qué pizzas contiene cada pedido y cuántas unidades se solicitaron.

También guarda `precio_unitario`, para conservar el precio que tenía la pizza cuando se realizó la compra.

### `repartidores`
Registra quién realiza los domicilios, su zona y disponibilidad.

### `domicilios`
Relaciona un pedido con un repartidor y guarda salida, entrega, distancia, zona y costo del envío.

### `pagos`
Registra el valor pagado, fecha, estado y referencia del pago.

### `historial_precios`
Guarda automáticamente los cambios de precio de las pizzas.

---

## 4. Relaciones principales

```text
clientes 1 ─────── N pedidos
pedidos  1 ─────── N detalle_pedido
pizzas   1 ─────── N detalle_pedido
pizzas   N ─────── N ingredientes
pedidos  1 ─────── 1 domicilios
repartidores 1 ─── N domicilios
pedidos  1 ─────── 1 pagos
pizzas   1 ─────── N historial_precios
```

La relación N:M entre pizzas e ingredientes se resuelve mediante `pizza_ingredientes`.

---

## 5. ¿Cómo se calcula el total?

La función `calcular_total_pedido()` hace tres pasos:

1. Suma el precio de las pizzas:

```text
cantidad × precio_unitario
```

2. Agrega el costo del domicilio.

3. Calcula un IVA del 19% sobre pizzas + envío.

Finalmente devuelve:

```text
subtotal + envío + IVA
```

Ejemplo:

```sql
SELECT calcular_total_pedido(1);
```

---

## 6. ¿Cómo se calcula la ganancia?

La función `calcular_ganancia_neta_diaria()` toma una fecha y calcula:

```text
ventas del día - costo de ingredientes utilizados
```

Ejemplo:

```sql
SELECT calcular_ganancia_neta_diaria('2026-09-01');
```

> Nota: para este ejercicio las ventas incluyen el total calculado por la función, incluyendo envío e IVA. En un sistema contable real, el tratamiento del IVA y otros costos debería definirse según las reglas contables aplicables.

---

## 7. Triggers explicados de forma sencilla

### Trigger de stock
Cuando se agrega una pizza a `detalle_pedido`, el sistema revisa primero si hay ingredientes suficientes.

Si hay stock, después descuenta automáticamente los ingredientes utilizados.

Ejemplo conceptual:

```text
Pedido de 2 pizzas
        ↓
Buscar ingredientes de la pizza
        ↓
Multiplicar cantidad de ingredientes × 2
        ↓
Restar del stock
```

### Trigger de historial de precios
Si una pizza cambia de precio, el sistema guarda:

- precio anterior
- precio nuevo
- fecha del cambio

Así se puede consultar la historia de precios.

### Trigger de entrega
Cuando `hora_entrega` pasa de `NULL` a una hora real:

- el pedido queda `entregado`;
- el repartidor vuelve a estar `disponible`.

---

## 8. Procedimiento de entrega

También existe el procedimiento:

```sql
CALL registrar_entrega(1, '2026-09-21 12:30:00');
```

Este procedimiento actualiza tres cosas:

1. La hora de entrega del domicilio.
2. El estado del pedido a `entregado`.
3. El estado del repartidor a `disponible`.

---

## 9. Vistas

### `vista_resumen_pedidos_cliente`
Muestra:

- cliente
- cantidad de pedidos
- total gastado

### `vista_desempeno_repartidores`
Muestra:

- repartidor
- zona
- número de entregas
- tiempo promedio de entrega

### `vista_stock_bajo`
Muestra ingredientes cuyo stock está por debajo del mínimo establecido.

---

## 10. Consultas solicitadas

En `consultas.sql` se encuentran ejemplos de:

- `BETWEEN`: pedidos entre dos fechas.
- `GROUP BY` + `COUNT`: pizzas más vendidas.
- `JOIN`: pedidos por repartidor.
- `AVG`: promedio de entrega por zona.
- `HAVING`: clientes que gastaron más de un monto.
- `LIKE`: búsqueda parcial de pizzas.
- Subconsulta: clientes frecuentes con más de 5 pedidos en el mes.
- Uso de funciones.
- Consulta de vistas.

---

## 11. ¿Cómo ejecutar el proyecto?

Se recomienda usar **MySQL Workbench**.

### Paso 1
Abrir MySQL Workbench y crear una conexión al servidor MySQL.

### Paso 2
Abrir `database.sql` y ejecutarlo completo.

Este archivo crea la base y las tablas.

### Paso 3
Abrir `funciones.sql` y ejecutarlo.

Aquí se crean las funciones y se insertan los pagos de prueba.

### Paso 4
Abrir `triggers.sql` y ejecutarlo.

Aquí se crean los triggers y el procedimiento.

### Paso 5
Abrir `vistas.sql` y ejecutarlo.

### Paso 6
Abrir `consultas.sql` y ejecutar las consultas que se quieran probar.

### Orden recomendado

```text
1. database.sql
2. funciones.sql
3. triggers.sql
4. vistas.sql
5. consultas.sql
```

---

## 12. Ejemplos rápidos para probar

### Ver todos los clientes

```sql
SELECT * FROM clientes;
```

### Ver las pizzas

```sql
SELECT * FROM pizzas;
```

### Ver pedidos

```sql
SELECT * FROM pedidos;
```

### Ver clientes frecuentes

```sql
SELECT
    c.nombre
FROM clientes c
WHERE c.id_cliente IN (
    SELECT p.id_cliente
    FROM pedidos p
    WHERE p.estado <> 'cancelado'
    GROUP BY p.id_cliente, YEAR(p.fecha_hora), MONTH(p.fecha_hora)
    HAVING COUNT(*) > 5
);
```

### Ver ingredientes con stock bajo

```sql
SELECT * FROM vista_stock_bajo;
```

---

## 13. Conceptos importantes para explicar al profesor

### ¿Qué es una llave primaria?
Es el campo que identifica de manera única cada registro de una tabla.

Ejemplo:

```sql
id_cliente INT AUTO_INCREMENT PRIMARY KEY
```

### ¿Qué es una llave foránea?
Es un campo que conecta una tabla con otra.

Ejemplo:

```sql
FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
```

Esto significa que un pedido pertenece a un cliente existente.

### ¿Qué es un JOIN?
Permite combinar información de varias tablas relacionadas.

### ¿Qué es un TRIGGER?
Es una acción automática que MySQL ejecuta cuando ocurre un evento, como un `INSERT` o un `UPDATE`.

### ¿Qué es una FUNCTION?
Es una función que recibe datos, realiza un cálculo y devuelve un resultado.

### ¿Qué es una VIEW?
Es una consulta guardada que funciona como una tabla virtual y facilita obtener reportes.

### ¿Qué es una subconsulta?
Es una consulta dentro de otra consulta. En este proyecto se usa para encontrar clientes que hicieron más de cinco pedidos en un mismo mes.

---

## 14. Resumen del funcionamiento

```text
CLIENTE
   ↓
PEDIDO
   ↓
DETALLE DEL PEDIDO
   ↓
PIZZAS ←→ INGREDIENTES
   ↓
DOMICILIO
   ↓
REPARTIDOR
   ↓
ENTREGA
   ↓
PAGO
```

El sistema permite controlar el proceso completo de venta, desde que el cliente realiza el pedido hasta que recibe la pizza y se registra el pago.

---

## 15. Tecnologías

- MySQL 8.0+
- SQL
- MySQL Workbench (recomendado para ejecutar y probar el proyecto)

**Proyecto académico - Pizzería Don Piccolo.**
