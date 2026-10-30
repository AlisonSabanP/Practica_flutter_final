# Modelo de datos

Base de datos local SQLite. El esquema se define en
`lib/core/database/database_schema.dart`.

## Tabla `categories`

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| id | INTEGER PRIMARY KEY AUTOINCREMENT | Identificador de la categoria. |
| name | TEXT NOT NULL UNIQUE | Nombre de la categoria. |

## Tabla `products`

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| id | INTEGER PRIMARY KEY AUTOINCREMENT | Identificador del producto. |
| code | TEXT NOT NULL UNIQUE | Codigo unico. Contenido del codigo de barras y del QR. |
| name | TEXT NOT NULL | Nombre del producto. |
| description | TEXT NOT NULL DEFAULT '' | Descripcion opcional. |
| category_id | INTEGER | Referencia a `categories.id`. Nulo si no tiene categoria. |
| purchase_price | REAL NOT NULL | Precio de compra. |
| sale_price | REAL NOT NULL | Precio de venta. |
| current_stock | INTEGER NOT NULL DEFAULT 0 | Existencias actuales. |
| minimum_stock | INTEGER NOT NULL DEFAULT 0 | Umbral de alerta de stock bajo. |
| photo_path | TEXT | Ruta local de la fotografia. Opcional. |
| active | INTEGER NOT NULL DEFAULT 1 | 1 activo, 0 desactivado. |
| created_at | INTEGER | Marca de tiempo de creacion. |
| updated_at | INTEGER | Marca de tiempo de la ultima modificacion. |

Relacion: `products.category_id` apunta a `categories.id`. Al eliminar una
categoria, la referencia del producto queda sin categoria.

## Tabla `movements`

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| id | INTEGER PRIMARY KEY AUTOINCREMENT | Identificador del movimiento. |
| product_id | INTEGER NOT NULL | Referencia a `products.id`. |
| type | TEXT NOT NULL | `entrada`, `salida` o `ajuste`. |
| quantity | INTEGER NOT NULL | Cantidad del movimiento. En un ajuste es el stock contado. |
| previous_stock | INTEGER NOT NULL | Stock antes del movimiento. |
| resulting_stock | INTEGER NOT NULL | Stock despues del movimiento. |
| reason | TEXT NOT NULL | Motivo. En un ajuste es la justificacion obligatoria. |
| responsible | TEXT NOT NULL | Nombre del responsable. |
| created_at | INTEGER NOT NULL | Fecha y hora del movimiento. |

Relacion: `movements.product_id` apunta a `products.id`. Un movimiento no se
edita ni se elimina; los errores se corrigen con un nuevo movimiento.

## Tabla `profile`

Almacen de clave y valor para la configuracion local.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| key | TEXT PRIMARY KEY | Nombre del ajuste. |
| value | TEXT NOT NULL | Valor del ajuste. |

Claves usadas:

- `responsible_name`: nombre del responsable por defecto.
- `store_name`: nombre de la tienda o bodega.
- `demo_seed_version`: version de los datos de demostracion cargados.

## Entidades del dominio

Las entidades no dependen de la base de datos. Los mappers convierten entre
filas y entidades.

- `Category`: id, name.
- `Product`: id, code, name, description, categoryId, categoryName,
  purchasePrice, salePrice, currentStock, minimumStock, photoPath, active.
- `Movement`: id, productId, productName, type, quantity, previousStock,
  resultingStock, reason, responsible, dateTime.
- `LocalProfile`: responsibleName, storeName, initialized.

## Reglas de integridad

- `products.code` es unico.
- `movements.product_id` siempre apunta a un producto existente.
- Las existencias iniciales de un producto se registran como un movimiento de
  entrada, nunca como valor directo en la tabla.
- Un producto con movimientos no se elimina fisicamente; solo se desactiva.
