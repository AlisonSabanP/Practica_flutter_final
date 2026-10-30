import 'package:flutter_test/flutter_test.dart';
import 'package:inventario/features/scanner/domain/services/scan_code_normalizer.dart';

void main() {
  group('ScanCodeNormalizer.normalize', () {
    test('recorta espacios externos', () {
      expect(ScanCodeNormalizer.normalize('  ABR-001  '), 'ABR-001');
    });

    test('extrae el ultimo segmento de una URL', () {
      expect(
        ScanCodeNormalizer.normalize('https://tienda.local/p/ABR-002'),
        'ABR-002',
      );
    });

    test('toma el valor despues del signo igual', () {
      expect(ScanCodeNormalizer.normalize('codigo=ABR-003'), 'ABR-003');
    });

    test('devuelve vacio si la lectura esta vacia', () {
      expect(ScanCodeNormalizer.normalize('   '), '');
    });
  });

  group('ScanCodeNormalizer.looksLikeProductCode', () {
    test('acepta un codigo alfanumerico con guion', () {
      expect(ScanCodeNormalizer.looksLikeProductCode('ABR-001'), isTrue);
    });

    test('acepta un codigo con punto y guion bajo', () {
      expect(ScanCodeNormalizer.looksLikeProductCode('BEB_001.A'), isTrue);
    });

    test('rechaza una lectura vacia', () {
      expect(ScanCodeNormalizer.looksLikeProductCode(''), isFalse);
    });

    test('rechaza un texto con espacios internos', () {
      expect(ScanCodeNormalizer.looksLikeProductCode('ARROZ 1 KG'), isFalse);
    });

    test('rechaza un texto demasiado largo', () {
      expect(ScanCodeNormalizer.looksLikeProductCode('A' * 41), isFalse);
    });
  });
}
