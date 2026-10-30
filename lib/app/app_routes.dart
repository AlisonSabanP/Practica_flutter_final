import 'package:flutter/material.dart';

/// Rutas nombradas de la aplicacion. Se centralizan para evitar cadenas
/// sueltas repartidas por las pantallas.
abstract final class AppRoutes {
  static const String home = '/';
  static const String products = '/productos';
  static const String productForm = '/productos/formulario';
  static const String productDetail = '/productos/detalle';
  static const String scanner = '/escaner';
  static const String reports = '/reportes';
  static const String profile = '/perfil';

  static Route<void> material(Widget page) {
    return MaterialPageRoute<void>(builder: (_) => page);
  }
}
