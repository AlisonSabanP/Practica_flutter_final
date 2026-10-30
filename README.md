# INVENTARIO

Aplicacion movil de gestion de inventario para una tienda y una bodega, sin
conexion a internet. Construida con Flutter y Dart.

- Repositorio: `inventario`
- Nombre visible de la aplicacion: **INVENTARIO**
- Nombre del paquete Dart: `inventario`
- `applicationId` de Android: `com.inventario.app`

## Requisitos

- Flutter 3.47 o superior (canal stable).
- Dart 3.13 o superior.
- Android SDK 36 y Java 17 para compilar el APK.
- Un dispositivo o emulador Android 7.0 (API 24) o superior para ejecutar.

## Clonar el repositorio

```bash
git clone https://github.com/<usuario>/inventario.git
cd inventario
```

## Instalar dependencias

```bash
flutter pub get
```

## Ejecutar la aplicacion

Con un dispositivo o emulador conectado:

```bash
flutter run
```

Para verificar la lista de dispositivos disponibles:

```bash
flutter devices
```

## Compilar el APK

APK de depuracion:

```bash
flutter build apk --debug
```

APK de liberacion:

```bash
flutter build apk --release
```

El archivo se genera en `build/app/outputs/flutter-apk/app-release.apk` y se
instala en el dispositivo con:

```bash
flutter install --release
```

El APK de la version 1.0.0 entregada esta en `dist/inventario-1.0.0.apk`, con su
suma de verificacion en `dist/inventario-1.0.0.apk.sha256`. El binario no se
versiona porque se puede regenerar con el comando anterior.

## Pruebas

```bash
flutter test
```

- `test/domain` contiene las pruebas unitarias de las reglas de inventario.
- `test/integration` ejecuta las pruebas sobre una base SQLite real.
- `test/golden` genera las capturas de pantalla de cada pantalla.

Para regenerar las capturas de pantalla:

```bash
flutter test --update-goldens test/golden
```

Las imagenes quedan en `test/golden/screenshots`.

## Analisis estatico

```bash
flutter analyze
```

## Funcionalidades principales

- Gestion de productos con validaciones y desactivacion sin borrado fisico.
- Codigo de barras Code 128 y QR por producto, con etiqueta exportable.
- Lectura de codigos de barras y QR con la camara y busqueda manual.
- Movimientos de entrada, salida y ajuste con historial persistente.
- Alertas de stock igual o inferior al minimo.
- Exportacion del inventario y del historial a CSV.
- Perfil local con el nombre del responsable.
- Datos de demostracion con 3 categorias y 16 productos.

## Documentacion

- [Arquitectura](docs/arquitectura.md)
- [Estructura de carpetas](docs/estructura.md)
- [Modelo de datos](docs/modelo-de-datos.md)
- [Casos de uso](docs/casos-de-uso.md)
- [Codigos de barras y QR](docs/codigos.md)
- [Validaciones y manejo de errores](docs/validaciones-y-errores.md)
- [Pruebas](docs/pruebas.md)
- [Evidencia de pruebas](docs/evidencia-pruebas.md)
- [Compilacion del APK](docs/compilacion-apk.md)
- [Limitaciones conocidas](docs/limitaciones.md)
- [Manual de usuario (PDF)](docs/manual-de-usuario.pdf)

## Estructura resumida

```
lib/
  app/                 arranque y navegacion principal
  core/                base de datos, tema, utilidades y widgets comunes
  features/
    products/          productos, categorias y etiquetas
    inventory/         movimientos y existencias
    scanner/           lectura de codigos
    reports/           consultas, exportacion y valor del inventario
    settings/          perfil local
```
