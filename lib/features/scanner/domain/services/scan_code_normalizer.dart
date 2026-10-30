/// Normaliza el texto leido por la camara antes de buscarlo en la base.
///
/// Un codigo QR puede contener una URL o un texto con espacios. Como el QR se
/// genera con el codigo unico del producto, aqui se extrae el ultimo segmento
/// valido para tolerar lecturas con prefijos.
abstract final class ScanCodeNormalizer {
  static String normalize(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return value;

    if (value.contains('://')) {
      final uri = Uri.tryParse(value);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        value = uri.pathSegments.last;
      }
    }

    if (value.contains('=')) {
      final candidate = value.split('=').last;
      if (candidate.isNotEmpty) value = candidate;
    }

    return value.trim();
  }

  /// Valida que el texto tenga forma de codigo de producto. Evita guardar
  /// lecturas basura de la camara.
  static bool looksLikeProductCode(String value) {
    final normalized = normalize(value);
    if (normalized.isEmpty) return false;
    if (normalized.length > 40) return false;
    return RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(normalized);
  }
}
