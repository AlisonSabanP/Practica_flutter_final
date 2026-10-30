# Estructura de carpetas

```
lib/
  main.dart                     arranque de la aplicacion
  app/
    app_routes.dart             nombres de rutas
    shell_screen.dart           navegacion inferior principal
    home_screen.dart            panel de inicio
  core/
    database/
      database_schema.dart      definicion de tablas e indices
      app_database.dart         apertura, version y migraciones
      demo_seed.dart            datos de demostracion
    di/
      providers.dart            proveedores de repositorios y casos de uso
    errors/
      app_exception.dart        excepciones del dominio y su traduccion
    theme/
      app_theme.dart            tema, colores y espaciados
    utils/
      formatters.dart           formato de numeros y fechas (locale fijo)
    widgets/
      app_cards.dart            tarjetas, etiquetas de estado y encabezados
      state_views.dart          estados de carga, error y lista vacia
  features/
    products/
      domain/
        entities/product.dart
        services/product_validator.dart
        repositories/product_repository.dart
        usecases/product_usecases.dart
      data/
        mappers/product_mapper.dart
        repositories/sqlite_product_repository.dart
      presentation/
        providers/product_providers.dart
        screens/products_screen.dart
        screens/product_form_screen.dart
        screens/product_detail_screen.dart
        services/label_export_service.dart
        widgets/product_tile.dart
        widgets/product_label.dart
    inventory/
      domain/
        entities/movement.dart
        entities/movement_type.dart
        services/stock_calculator.dart
        repositories/inventory_repository.dart
        usecases/register_movement.dart
        usecases/inventory_queries.dart
      data/repositories/sqlite_inventory_repository.dart
      presentation/
        providers/inventory_providers.dart
        screens/movement_screen.dart
        widgets/movement_tile.dart
    scanner/
      domain/services/scan_code_normalizer.dart
      presentation/
        providers/scanner_providers.dart
        screens/scanner_screen.dart
    reports/
      domain/services/inventory_csv_builder.dart
      data/report_export_service.dart
      presentation/screens/reports_screen.dart
    settings/
      domain/entities/local_profile.dart
      domain/repositories/profile_repository.dart
      data/repositories/sqlite_profile_repository.dart
      presentation/
        providers/profile_providers.dart
        screens/profile_screen.dart

test/
  domain/            pruebas unitarias de las reglas de inventario
  integration/       pruebas sobre una base SQLite real
  golden/            generacion de capturas de pantalla

docs/                documentacion tecnica y manual de usuario
```
