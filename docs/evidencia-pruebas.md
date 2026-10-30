# Evidencia de pruebas de las reglas de inventario

Comando ejecutado:

```bash
flutter test
```

Resultado:

```
00:11 +56: All tests passed!
```

Recuento: 30 pruebas de dominio y de integracion, y 9 capturas de pantalla. En
total, 56 pruebas ejecutadas.

## Reglas verificadas

### Cantidades mayores que cero

- `StockCalculator entrada rechaza cantidad cero`.
- `StockCalculator entrada rechaza cantidad negativa`.
- `StockCalculator salida rechaza cantidad cero`.

### Salidas superiores al stock disponible

- `StockCalculator salida impide retirar mas unidades que las disponibles`.
- `una salida invalida no deja cambios en stock ni en movimientos`.
- Dentro del flujo de aceptacion, la salida de 5 unidades con 4 disponibles
  lanza `InsufficientStockException`.

### Movimiento y stock en una sola operacion

- `registra el movimiento y actualiza el stock en una sola operacion`.
- `una salida invalida no deja cambios en stock ni en movimientos`.
- `un motivo vacio no deja cambios en stock ni en movimientos`.

### Ajuste con justificacion obligatoria

- `StockCalculator ajuste exige justificacion no vacia`.
- `un ajuste sin justificacion es rechazado por el caso de uso`.
- Dentro del flujo de aceptacion, el ajuste a 3 unidades guarda el stock
  anterior (4) y el resultante (3).

### Producto con movimientos no se elimina

- `un producto con movimientos no se elimina, solo se desactiva`.
- `un producto sin movimientos si se puede eliminar`.

### Existencias iniciales como movimiento de entrada

- `el stock inicial se registra como movimiento de entrada`.

### Persistencia

- `los datos sobreviven al cierre y reapertura de la base`.

### Responsable obligatorio

- `no permite registrar movimientos sin responsable`.

### Codigos unicos

- `detecta codigos duplicados`.
- `el mismo codigo esta disponible al editar el propio producto`.
- `el caso de uso de creacion rechaza un codigo repetido`.

## Flujo de aceptacion

La prueba `registra la cadena completa del flujo de aceptacion` cubre los pasos
del dominio:

1. Producto con stock minimo de 5 unidades.
2. Entrada de 20 unidades. Stock resultante: 20.
3. Salida de 16 unidades. Stock resultante: 4.
4. El producto aparece en la lista de stock bajo.
5. Salida de 5 unidades rechazada con `InsufficientStockException`.
6. Ajuste a 3 unidades con justificacion. Stock resultante: 3.

Los pasos de interfaz (etiqueta de codigos, escaneo y exportacion a CSV) se
comprobaron con las capturas de pantalla y con las pruebas de la capa de
exportacion.
