# Arquitectura

El proyecto sigue una arquitectura feature + domain. Cada funcionalidad se
agrupa en una carpeta bajo `lib/features` y dentro de ella se separan las capas
`presentation`, `domain` y `data`.

## Capas

### domain

Contiene el nucleo del negocio y no depende de Flutter, de widgets ni de la base
de datos.

- `entities`: objetos del negocio como `Product`, `Category`, `Movement`,
  `MovementType` y `LocalProfile`.
- `services`: reglas puras como `StockCalculator` y `ProductValidator`.
- `repositories`: contratos abstractos que definen las operaciones esperadas.
- `usecases`: casos de uso que orquestan el dominio, por ejemplo
  `RegisterMovement`, `CreateProduct` y `GetInventorySummary`.

Las reglas de inventario viven aqui. La capa `domain` se puede probar sin
arrancar la interfaz ni la base de datos.

### data

Implementa los contratos del dominio y concentra el acceso al almacenamiento.

- `repositories`: implementaciones SQLite de los contratos.
- `mappers`: conversion entre filas de la base y entidades del dominio.

### presentation

Contiene las pantallas y la gestion de estado. La interfaz nunca escribe stock
directamente: siempre llama a un caso de uso del dominio.

- `screens`: pantallas de cada funcionalidad.
- `widgets`: componentes reutilizables propios de la funcionalidad.
- `providers`: estado con Riverpod.

## Gestion de estado

Se usa Riverpod en todo el proyecto, sin mezclar enfoques. Los proveedores se
definen de forma centralizada en `lib/core/di/providers.dart` para los
repositorios y casos de uso, y en cada feature para el estado de pantalla.

## Flujo de una operacion de inventario

1. La pantalla recoge los datos y llama al proveedor del caso de uso.
2. El caso de uso aplica las reglas del dominio (`StockCalculator`).
3. El repositorio abre una transaccion y, dentro de ella, actualiza el stock e
   inserta el movimiento.
4. Si cualquier paso falla, la transaccion se revierte por completo.
5. La pantalla refresca el estado y muestra el resultado.

## Persistencia

Se usa `sqflite` como base de datos local. La base se crea y migra en
`lib/core/database/app_database.dart`. El esquema se define en
`lib/core/database/database_schema.dart`. Los datos de demostracion se cargan
una sola vez y de forma idempotente desde `lib/core/database/demo_seed.dart`.

## Independencia de la red

Ninguna operacion principal requiere conexion. La aplicacion funciona completa
en modo sin conexion.
