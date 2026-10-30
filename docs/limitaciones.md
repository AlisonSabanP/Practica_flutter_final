# Limitaciones conocidas

- Alcance de un solo dispositivo, una tienda y una bodega. No hay
  sincronizacion entre dispositivos ni trabajo en red.
- El valor del inventario es una estimacion simple: existencias por precio de
  compra. No se aplican metodos contables como promedio ponderado o PEPS.
- Los movimientos confirmados no se editan ni se eliminan. Las correcciones se
  hacen con un nuevo movimiento de ajuste.
- Las cantidades se manejan como numeros enteros. No se admiten fracciones de
  unidad.
- La exportacion a CSV comparte un archivo temporal. No se guarda una copia
  permanente en una carpeta elegida por el usuario.
- La etiqueta de codigos se comparte como imagen. La impresion depende de la
  aplicacion de impresion disponible en el dispositivo.
- El escaneo requiere una camara. En el entorno de compilacion no se pudo probar
  con camara real; la logica de lectura se verifico con la busqueda manual y las
  capturas se generaron con pruebas golden.
- La fotografia del producto se toma de la galeria. No se captura directamente
  con la camara desde la aplicacion.
- La interfaz esta en espanol y los formatos de numero y fecha usan un locale
  fijo.
- La base de datos es local. Si se desinstala la aplicacion, los datos se
  pierden y se vuelven a cargar los datos de demostracion.
- El APK declara los permisos `INTERNET` y `ACCESS_NETWORK_STATE`. No los usa
  ninguna operacion de la aplicacion: los agrega una dependencia transitiva del
  lector de codigos (ML Kit, via `com.google.android.datatransport`). El modelo
  de lectura viaja dentro del APK, por lo que el escaneo funciona sin conexion.
- El escaneo no se pudo probar en un dispositivo fisico desde el entorno de
  compilacion. La lectura se valido con las pruebas del normalizador de codigos
  y la busqueda manual. La prueba en dispositivo queda pendiente.
