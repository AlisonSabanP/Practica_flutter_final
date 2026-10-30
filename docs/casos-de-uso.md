# Casos de uso

Los casos de uso viven en la capa `domain` de cada funcionalidad y se exponen a
la interfaz mediante Riverpod.

## Productos

### CreateProduct
Crea un producto. Valida el codigo unico, los campos obligatorios y los precios
positivos. Si se indica un stock inicial mayor que cero, registra un movimiento
de entrada dentro de la misma transaccion. Firma:

```
CreateProduct.call(Product product, {int initialStock = 0, String responsible = ''})
```

### UpdateProduct
Actualiza los datos de un producto existente. Verifica que el codigo siga
siendo unico sin contar el propio producto. No modifica el stock.

### SetProductActive
Activa o desactiva un producto. La desactivacion es la via para retirar un
producto con movimientos sin borrar su historial.

### DeleteProduct
Elimina fisicamente un producto solo cuando no tiene movimientos. Si tiene
movimientos, lanza `ProductHasMovementsException`.

### GetProducts
Lista productos aplicando el termino de busqueda y el filtro de existencias
bajas. Regla de seleccion pura.

### GetProductByCode
Busca un producto por su codigo unico. Es la operacion que usa el escaner.

## Inventario

### RegisterMovement
Registra un movimiento y actualiza el stock en una sola operacion atomica.

```
RegisterMovement.call({
  required Product product,
  required MovementType type,
  required int quantity,
  required String reason,
  required String responsible,
})
```

- Valida que el responsable no este vacio.
- Delega el calculo y las reglas a `StockCalculator`.
- Persiste el movimiento y el nuevo stock dentro de una transaccion.

### GetInventorySummary
Calcula el resumen: productos activos, unidades totales, valor del inventario,
alertas de stock bajo y productos agotados.

### GetLowStockProducts
Devuelve los productos con existencias iguales o inferiores al minimo.

### GetMovements
Devuelve el historial filtrado por producto, tipo y rango de fechas.

### GetMovementsForProduct
Devuelve los movimientos de un producto, con un limite opcional.

## Escaner

### ScanCodeNormalizer
Normaliza el texto leido: recorta espacios, unifica mayusculas y descarta
lecturas vacias o demasiado largas. El codigo normalizado se busca con
`GetProductByCode`.

## Reportes

### InventoryCsvBuilder
Construye el CSV del inventario y del historial. Aplica comillas y escapes
cuando un campo contiene comas, comillas o saltos de linea.

### ReportExportService
Escribe el CSV en un archivo temporal y lo comparte con la hoja de
comparticion del sistema para su impresion o envio.

## Perfil

### LoadProfile y SaveProfile
Leen y guardan el nombre del responsable y el nombre de la tienda. El nombre
del responsable se usa por defecto en cada movimiento.
