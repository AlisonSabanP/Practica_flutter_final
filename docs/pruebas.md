# Pruebas realizadas

## Pruebas unitarias del dominio

Archivo: `test/domain/stock_calculator_test.dart`.

Se ejecutan sin base de datos ni interfaz. Cubren las reglas de inventario:

- Entrada: suma la cantidad al stock actual.
- Entrada: rechaza cantidad cero y cantidad negativa.
- Entrada: exige motivo no vacio.
- Salida: resta la cantidad cuando hay existencias suficientes.
- Salida: permite dejar el stock exactamente en cero.
- Salida: impide retirar mas unidades que las disponibles.
- Salida: rechaza cantidad cero.
- Ajuste: fija el stock contado sin importar el valor anterior.
- Ajuste: acepta ajuste a cero con justificacion.
- Ajuste: exige justificacion no vacia.
- Ajuste: rechaza cantidad contada negativa.
- Consistencia: rechaza un stock previo negativo.

Archivo: `test/domain/scan_code_normalizer_test.dart`.

Cubren la normalizacion de las lecturas de la camara:

- Recorta los espacios externos de la lectura.
- Extrae el ultimo segmento de una lectura con forma de URL.
- Toma el valor despues del signo igual.
- Descarta las lecturas vacias.
- Acepta codigos alfanumericos con guion, punto y guion bajo.
- Rechaza textos con espacios internos y lecturas demasiado largas.

Archivo: `test/domain/inventory_csv_builder_test.dart`.

Cubren la exportacion a CSV:

- Incluye el encabezado y una fila por producto.
- Calcula el valor del inventario como stock por precio de compra.
- Marca los productos desactivados como inactivos.
- Incluye el tipo, el motivo y el responsable en el historial.
- Usa punto y coma como separador.
- Escapa el separador, las comillas internas y los saltos de linea.

## Pruebas de integracion

Archivo: `test/integration/inventory_repository_test.dart`.

Se ejecutan sobre una base SQLite real (mediante `sqflite_common_ffi`).

Persistencia:

- El stock inicial se registra como movimiento de entrada.
- Los datos sobreviven al cierre y reapertura de la base.

Transaccionalidad:

- El movimiento y el stock se actualizan en una sola operacion.
- Una salida invalida no deja cambios en stock ni en movimientos.
- Un motivo vacio no deja cambios en stock ni en movimientos.

Reglas de negocio:

- El flujo completo del caso de aceptacion (entrada de 20, salida de 16, alerta
  de stock bajo, salida de 5 rechazada, ajuste a 3).
- Un ajuste sin justificacion es rechazado.
- No se permiten movimientos sin responsable.
- Un producto con movimientos no se elimina, solo se desactiva.
- Un producto sin movimientos si se puede eliminar.

Codigos:

- Deteccion de codigos duplicados.
- El mismo codigo esta disponible al editar el propio producto.
- El caso de uso de creacion rechaza un codigo repetido.

Historial y filtros:

- Filtra movimientos por producto, tipo y rango de fechas.

Perfil y datos de demostracion:

- Guarda y recupera el responsable por defecto.
- Carga 3 categorias y al menos 15 productos.
- La carga de datos es idempotente.

## Capturas de pantalla

Archivo: `test/golden/screenshots_test.dart`.

El entorno de compilacion no dispone de emulador con aceleracion por hardware.
Las capturas se generan con el motor de render de Flutter mediante pruebas
golden, que renderizan cada pantalla con los datos de demostracion.

Comando:

```bash
flutter test --update-goldens test/golden
```

Salida en `test/golden/screenshots`:

| Archivo | Pantalla |
|---------|----------|
| 00_navegacion.png | Navegacion principal |
| 01_inicio.png | Inicio |
| 02_productos.png | Listado de productos |
| 03_formulario_producto.png | Formulario de producto |
| 04_detalle_producto.png | Detalle con etiquetas |
| 05_reportes.png | Reportes e historial |
| 06_perfil.png | Perfil local |
| 07_escaner.png | Escaner |
| 08_movimiento.png | Movimiento de inventario |

## Resultado

```bash
flutter test
```

Todas las pruebas pasan. `flutter analyze` no reporta problemas.

Recuento actual: 30 pruebas de dominio y de integracion, mas 9 capturas de
pantalla. En total, 56 pruebas ejecutadas.
