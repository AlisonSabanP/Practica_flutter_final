# Validaciones y manejo de errores

## Validaciones de formularios

Las reglas se definen en el dominio (`ProductValidator`) y el formulario solo
las presenta. Se aplican en todas las entradas.

### Producto

- Codigo: obligatorio, sin espacios, maximo 40 caracteres.
- Nombre: obligatorio, entre 2 y 80 caracteres.
- Precio de compra: obligatorio, numero positivo.
- Precio de venta: obligatorio, numero positivo.
- Stock minimo: obligatorio, entero mayor o igual que cero.
- Stock inicial: entero mayor o igual que cero. Opcional.
- Descripcion: opcional, maximo 300 caracteres.

### Movimiento

- Cantidad: obligatoria, entero. Para entrada y salida debe ser mayor que cero.
  Para ajuste puede ser cero porque representa el stock contado.
- Salida: no puede superar el stock disponible.
- Ajuste: la justificacion es obligatoria y no puede estar vacia.
- Motivo: obligatorio para entrada y salida.
- Responsable: obligatorio. Se toma del perfil local.

### Perfil

- Nombre del responsable: obligatorio, maximo 80 caracteres.
- Nombre de la tienda: opcional, maximo 80 caracteres.

## Excepciones del dominio

Definidas en `lib/core/errors/app_exception.dart`:

| Excepcion | Motivo |
|-----------|--------|
| ValidationException | Un dato no cumple una regla del dominio. |
| InsufficientStockException | La salida supera el stock disponible. |
| DuplicateCodeException | El codigo ya existe en otro producto. |
| ProductHasMovementsException | Se intenta eliminar un producto con movimientos. |
| StorageException | Falla el acceso al almacenamiento local. |

`describeError` traduce cualquier error a un mensaje claro para el usuario. Los
errores de almacenamiento y de permisos nunca se muestran como texto tecnico.

## Errores de camara y permisos

- Permiso denegado: mensaje con boton para reintentar la solicitud.
- Permiso bloqueado de forma permanente: mensaje con boton para abrir los
  ajustes del sistema.
- Camara no disponible: mensaje que sugiere la busqueda manual.
- El fallo del servicio de permisos no bloquea la pantalla: la busqueda manual
  queda disponible.

## Errores de almacenamiento

- Si falla la apertura de la base de datos, la pantalla muestra un estado de
  error con opcion de reintentar.
- Si falla la exportacion a CSV o la captura de la etiqueta, se muestra un
  mensaje y la operacion se puede repetir.

## Estados de la interfaz

Todas las listas contemplan tres estados:

- Carga: indicador con un mensaje breve.
- Error: mensaje claro y boton para reintentar.
- Vacio: mensaje que explica la situacion y ofrece la accion siguiente.

Las operaciones que modifican datos muestran una confirmacion al finalizar.
