import 'package:intl/intl.dart';

/// Formatos de moneda y fecha usados en toda la interfaz.
///
/// Se fijan locale y patrones explicitos para que el formato no dependa de la
/// configuracion regional del dispositivo.
abstract final class Formatters {
  static final NumberFormat _currency =
      NumberFormat.currency(locale: 'es_ES', symbol: r'$', decimalDigits: 2);

  static final NumberFormat _integer = NumberFormat.decimalPattern('es_ES');

  static final DateFormat _shortDate = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTime = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _fullDateTime = DateFormat('dd/MM/yyyy HH:mm:ss');

  static String currency(num value) => _currency.format(value);

  static String integer(num value) => _integer.format(value);

  static String date(DateTime value) => _shortDate.format(value);

  static String dateTime(DateTime value) => _dateTime.format(value);

  static String fullDateTime(DateTime value) => _fullDateTime.format(value);

  static String stock(int current, int minimum) => '$current / min $minimum';

  static String signedQuantity(int delta) => delta >= 0 ? '+$delta' : '$delta';
}
