# Compilacion del APK

## Requisitos

- Flutter 3.47 o superior.
- Android SDK 36 con las herramientas de compilacion.
- Java 17.
- Android NDK 27.0.12077973 (el proyecto lo fija en `android/app/build.gradle.kts`).

## Configuracion de Android

- `android:label="INVENTARIO"` en `android/app/src/main/AndroidManifest.xml`.
- `applicationId = "com.inventario.app"`.
- `minSdk = 24` (Android 7.0).
- Permisos declarados: `CAMERA`, `READ_MEDIA_IMAGES` y `READ_EXTERNAL_STORAGE`
  (esta ultima solo hasta Android 12).

## Comandos

Instalar dependencias:

```bash
flutter pub get
```

Compilar el APK de liberacion:

```bash
flutter build apk --release
```

El archivo se genera en:

```
build/app/outputs/flutter-apk/app-release.apk
```

Compilar variantes por arquitectura (menor tamano):

```bash
flutter build apk --release --split-per-abi
```

Instalar en un dispositivo conectado:

```bash
flutter install --release
```

## Firma

La configuracion de ejemplo firma con las claves de depuracion para que
`flutter run --release` funcione sin configuracion adicional. Para publicar en
una tienda se debe crear una clave de liberacion y configurarla en
`android/app/build.gradle.kts`.

## Resultado

El proyecto compila sin errores en Android. El APK generado se puede instalar en
cualquier dispositivo Android 7.0 o superior.
