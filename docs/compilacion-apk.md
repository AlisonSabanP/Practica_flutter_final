# Compilacion del APK

## Requisitos

- Flutter 3.47 o superior.
- Android SDK 36 con las herramientas de compilacion.
- Java 17.
- Android NDK 28.2.13676358 (el proyecto lo fija en `android/app/build.gradle.kts`).

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

## Problemas conocidos al compilar

### El NDK no se instala

Sintoma:

```
Package ndk not found.
Package 28.2.13676358 not found.
> Android sdkmanager did not install NDK 28.2.13676358
```

Causa: el NDK 28 lo exige `path_provider_android`, que compila codigo nativo con
`jni`. Si el NDK no esta instalado, la compilacion falla.

Solucion 1, instalar el NDK:

```
sdkmanager --install "ndk;28.2.13676358"
```

En Windows, si `sdkmanager` no esta en el PATH, se llama por ruta completa:

```
%LOCALAPPDATA%\Android\sdk\cmdline-tools\latest\bin\sdkmanager.bat --install "ndk;28.2.13676358"
```

Solucion 2, instalar el NDK a mano si `sdkmanager` falla:

1. Descargar el paquete oficial:

   ```
   https://dl.google.com/android/repository/android-ndk-r28c-windows.zip
   ```

2. Descomprimirlo en la carpeta de NDK del SDK. La carpeta debe quedar con el
   nombre de la version:

   ```
   %LOCALAPPDATA%\Android\sdk\ndk\28.2.13676358
   ```

3. Aceptar las licencias:

   ```
   flutter doctor --android-licenses
   ```

Con el NDK instalado, `flutter run` y `flutter build apk --release` vuelven a
funcionar.

## Resultado

El proyecto compila sin errores en Android. El APK generado se puede instalar en
cualquier dispositivo Android 7.0 o superior.

Compilacion verificada:

```
Running Gradle task 'assembleRelease'...  193.5s
Built build/app/outputs/flutter-apk/app-release.apk (70.8MB)
```

Datos del APK entregado:

```
package: com.inventario.app
versionName: 1.0.0
application-label: INVENTARIO
targetSdkVersion: 36
```

El archivo final esta en `dist/inventario-1.0.0.apk`, con su suma de verificacion
en `dist/inventario-1.0.0.apk.sha256`.
