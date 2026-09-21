# Pizzería Don Piccolo — Sistema de Gestión de Pedidos y Domicilios

## 1. Descripción del proyecto

Base de datos en MySQL para controlar las operaciones de la Pizzería Don Piccolo:
clientes, pizzas, ingredientes, pedidos, repartidores, domicilios y pagos.
Todos los pedidos del sistema son a domicilio.

## 2. Estructura del proyecto

```
/pizzeria-don-piccolo/
 ├── database.sql   -> Base de datos y tablas (con PK y FK)
 ├── funciones.sql  -> 2 funciones + 1 procedimiento almacenado
 ├── triggers.sql   -> 3 triggers
 ├── vistas.sql     -> 3 vistas de reportes
 ├── consultas.sql  -> 7 consultas de ejemplo
 └── README.md      -> este archivo
```

## 3. Tablas y relaciones

| Tabla | Para qué sirve |
|---|---|
| `clientes` | Datos de las personas que piden pizza |
| `pizzas` | Catálogo general (nombre, tipo) |
| `pizza_precios` | Precio de cada pizza según su tamaño (pequeña/mediana/grande) |
| `ingredientes` | Inventario: stock actual, mínimo permitido y costo |
| `pizza_ingredientes` | Receta: qué ingredientes y en qué cantidad lleva cada pizza |
| `pedidos` | El pedido de un cliente (estado, fecha, total) |
| `detalle_pedido` | Qué pizzas específicas incluye cada pedido |
| `pagos` | Pago de cada pedido (relación 1 a 1) |
| `repartidores` | Nombre, zona y disponibilidad |
| `domicilios` | Entrega de cada pedido (relación 1 a 1): horas, distancia, costo |
| `historial_precios` | Se llena sola (por trigger) cuando cambia el precio de una pizza |

**Relaciones clave:**
- `clientes` 1 → N `pedidos`
- `pedidos` N ↔ N `pizza_precios` (a través de `detalle_pedido`)
- `pizzas` N ↔ N `ingredientes` (a través de `pizza_ingredientes`)
- `pedidos` 1 → 1 `pagos` y `pedidos` 1 → 1 `domicilios`
- `repartidores` 1 → N `domicilios`

## 4. Funciones, procedimiento y triggers

- **`calcular_total_pedido(id_pedido)`**: suma las pizzas + envío y le agrega el 19% de IVA.
- **`ganancia_neta_diaria(fecha)`**: ventas del día menos el costo de los ingredientes usados.
- **`registrar_entrega(id_domicilio, hora)`**: registra la hora de entrega y pasa el pedido a "entregado".
- **`trg_actualizar_stock`**: descuenta ingredientes del inventario al registrar una pizza en un pedido.
- **`trg_historial_precios`**: guarda en `historial_precios` cada cambio de precio.
- **`trg_repartidor_disponible`**: libera al repartidor cuando se registra la hora de entrega.

## 5. Ejemplos de uso

```sql
-- Actualizar el total de un pedido usando la función
UPDATE pedidos
SET total = calcular_total_pedido(1)
WHERE id_pedido = 1;

-- Ver la ganancia neta de un día específico
SELECT ganancia_neta_diaria('2025-01-15');

-- Registrar la entrega de un domicilio (dispara el trigger de repartidor disponible)
CALL registrar_entrega(1, NOW());
```

## 6. Instrucciones para ejecutar el script

1. Abre tu cliente de MySQL (Workbench, consola, DBeaver, etc.).
2. Ejecuta los archivos **en este orden** (importante, porque cada uno depende del anterior):
   1. `database.sql`
   2. `funciones.sql`
   3. `triggers.sql`
   4. `vistas.sql`
   5. `consultas.sql` (opcional, solo para probar)

**Desde la terminal:**
```bash
mysql -u root -p < database.sql
mysql -u root -p < funciones.sql
mysql -u root -p < triggers.sql
mysql -u root -p < vistas.sql
mysql -u root -p pizzeria_don_piccolo < consultas.sql
```

3. Antes de probar `consultas.sql`, inserta algunos datos de ejemplo en las tablas
   (clientes, pizzas, pizza_precios, ingredientes, etc.) para que las consultas
   devuelvan resultados.
