# Generacion y lectura de codigos

## Codigo unico

Cada producto tiene un campo `code` unico. Ese texto es el contenido tanto del
codigo de barras como del QR. La unicidad se valida antes de guardar mediante
`ProductRepository.isCodeAvailable`, que permite excluir el propio producto al
editar.

## Generacion

La etiqueta se construye en `lib/features/products/presentation/widgets/product_label.dart`.

- Codigo de barras: se genera en formato Code 128 a partir del codigo unico con
  el paquete `barcode_widget`.
- QR: contiene unicamente el codigo unico del producto. No incluye cantidades ni
  existencias porque cambian con cada movimiento.
- La etiqueta muestra el nombre del producto, el codigo y ambas
  representaciones.

## Exportacion e impresion

`LabelExportService` captura la etiqueta mediante un `RepaintBoundary` y genera
una imagen PNG. La imagen se comparte con la hoja del sistema para imprimirla o
enviarla.

## Lectura

La lectura se realiza con la camara mediante el paquete `mobile_scanner`.

- Se aceptan codigos de barras y QR.
- El texto leido se normaliza con `ScanCodeNormalizer` antes de buscar.
- Si el producto existe, se muestran sus datos, sus existencias y el acceso a
  registrar entrada, salida o ajuste.
- Si el producto no existe, se muestra el mensaje de codigo no registrado.

## Busqueda manual

Cuando la camara no esta disponible, la pantalla del escaner ofrece busqueda
manual por codigo o por nombre. La busqueda por nombre solo resuelve el producto
cuando hay una coincidencia unica.

## Permisos y errores de camara

- Si el permiso de camara esta pendiente, se solicita al abrir la pantalla.
- Si el permiso se deniega, se muestra un mensaje y se ofrece reintentar.
- Si el permiso se bloquea de forma permanente, se ofrece abrir los ajustes del
  sistema.
- Si la camara no esta disponible, la busqueda manual sigue funcionando.

## Prueba en dispositivo fisico

El escaneo se debe probar en un dispositivo con camara. Para el flujo de
aceptacion se pueden escanear tanto el codigo de barras como el QR del mismo
producto; ambos devuelven el mismo codigo unico.
