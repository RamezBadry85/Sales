import 'package:decimal/decimal.dart';

/// Deterministic decimal formatting and parsing helpers.
///
/// The application never stores monetary values as binary floating point.
/// Values are kept as [Decimal] in memory and as normalized strings in SQLite.
/// Formatting is implemented on top of the decimal string representation so
/// that no precision is lost while producing grouped, human readable output.
class DecimalFormat {
  const DecimalFormat._();

  /// Arabic-Indic and extended Arabic-Indic digits mapped to ASCII digits.
  static const Map<String, String> _digitMap = {
    '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
    '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
    '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4',
    '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9',
  };

  /// Normalizes a user supplied numeric string.
  ///
  /// Accepts Arabic digits, Arabic decimal separators, thousands separators
  /// and stray spaces. Returns `null` when the text cannot be a number.
  static String? normalizeNumberInput(String? raw) {
    if (raw == null) return null;
    var text = raw.trim();
    if (text.isEmpty) return null;

    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      final mapped = _digitMap[char];
      if (mapped != null) {
        buffer.write(mapped);
      } else if (char == '.' || char == ',' ||
          char == '\u066B' || char == '\u066C' ||
          char == ' ' || char == '\u00A0' || char == '\u202F') {
        // Arabic decimal separator -> '.', Arabic thousands separator -> ','
        if (char == '\u066B') {
          buffer.write('.');
        } else if (char == '\u066C' || char == ' ' || char == '\u00A0' || char == '\u202F') {
          // ignored separators
        } else {
          buffer.write(char);
        }
      } else if (char == '-' || char == '+') {
        buffer.write(char);
      } else if (rune >= 0x30 && rune <= 0x39) {
        buffer.write(char);
      }
    }

    var result = buffer.toString();
    if (result.isEmpty) return null;

    // Resolve the decimal separator: the last '.' or ',' is the decimal point
    // when the other one is clearly used as a grouping separator.
    final lastDot = result.lastIndexOf('.');
    final lastComma = result.lastIndexOf(',');
    if (lastDot >= 0 && lastComma >= 0) {
      if (lastComma > lastDot) {
        result = result.replaceAll('.', '').replaceAll(',', '.');
      } else {
        result = result.replaceAll(',', '');
      }
    } else if (lastComma >= 0) {
      final fractionLength = result.length - lastComma - 1;
      if (fractionLength == 3 && result.indexOf(',') == lastComma) {
        // 1,234 -> thousands separator
        result = result.replaceAll(',', '');
      } else {
        result = result.replaceAll(',', '.');
      }
    }

    if (result.startsWith('.')) result = '0$result';
    if (result.startsWith('-.')) result = '-0${result.substring(1)}';
    if (result.startsWith('+.')) result = '0${result.substring(1)}';

    if (!RegExp(r'^[+-]?\d*\.?\d*$').hasMatch(result)) return null;
    if (result == '.' || result == '-' || result == '+' || result == '-' '.') {
      return null;
    }
    return result;
  }

  /// Parses a user supplied number, returning `null` for empty/invalid input.
  static Decimal? tryParse(String? raw) {
    final normalized = normalizeNumberInput(raw);
    if (normalized == null) return null;
    try {
      return Decimal.parse(normalized);
    } catch (_) {
      return null;
    }
  }

  /// Parses a stored value coming from the database.
  static Decimal? fromStorage(Object? value) {
    if (value == null) return null;
    if (value is Decimal) return value;
    if (value is int) return Decimal.fromInt(value);
    if (value is num) return Decimal.parse(value.toString());
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return tryParse(text);
  }

  /// Converts a decimal to the canonical storage representation.
  static String? toStorage(Decimal? value) {
    if (value == null) return null;
    final text = value.toString();
    if (text.endsWith('.0') && !text.contains('e')) {
      final trimmed = _trimTrailingZeros(text);
      return trimmed.isEmpty ? '0' : trimmed;
    }
    return _trimTrailingZeros(text);
  }

  static String _trimTrailingZeros(String text) {
    if (!text.contains('.')) return text;
    var result = text;
    while (result.contains('.') && result.endsWith('0')) {
      result = result.substring(0, result.length - 1);
    }
    if (result.endsWith('.')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  /// Formats a decimal with grouped thousands and fixed fraction bounds.
  static String format(
    Decimal? value, {
    int minFractionDigits = 0,
    int maxFractionDigits = 2,
    bool grouping = true,
    String? nullText,
  }) {
    if (value == null) return nullText ?? '';
    final rounded = _roundTo(value, maxFractionDigits);
    var text = rounded.toString();
    if (text.startsWith('-')) {
      return '-${format(-rounded, minFractionDigits: minFractionDigits, maxFractionDigits: maxFractionDigits, grouping: grouping)}';
    }
    if (text.contains('e') || text.contains('E')) {
      // Extremely large/small exponents are not expected for business data;
      // fall back to a plain representation.
      text = rounded.toDouble().toStringAsFixed(maxFractionDigits);
    }

    var integerPart = text;
    var fractionPart = '';
    final dot = text.indexOf('.');
    if (dot >= 0) {
      integerPart = text.substring(0, dot);
      fractionPart = text.substring(dot + 1);
    }
    if (fractionPart.length > maxFractionDigits) {
      fractionPart = fractionPart.substring(0, maxFractionDigits);
    }
    while (fractionPart.length > minFractionDigits && fractionPart.endsWith('0')) {
      fractionPart = fractionPart.substring(0, fractionPart.length - 1);
    }
    if (fractionPart.length < minFractionDigits) {
      fractionPart = fractionPart.padRight(minFractionDigits, '0');
    }
    if (integerPart.isEmpty) integerPart = '0';

    final grouped = grouping ? _groupDigits(integerPart) : integerPart;
    return fractionPart.isEmpty ? grouped : '$grouped.$fractionPart';
  }

  static String _groupDigits(String digits) {
    if (digits.length <= 3) return digits;
    final buffer = StringBuffer();
    final firstGroup = digits.length % 3;
    var index = 0;
    if (firstGroup > 0) {
      buffer.write(digits.substring(0, firstGroup));
      index = firstGroup;
      if (index < digits.length) buffer.write(',');
    }
    while (index < digits.length) {
      buffer.write(digits.substring(index, index + 3));
      index += 3;
      if (index < digits.length) buffer.write(',');
    }
    return buffer.toString();
  }

  /// Half-up rounding on the string representation (no floating point).
  static Decimal _roundTo(Decimal value, int fractionDigits) {
    if (fractionDigits < 0) return value;
    final text = value.toString();
    final dot = text.indexOf('.');
    if (dot < 0) return value;
    final fraction = text.substring(dot + 1);
    if (fraction.length <= fractionDigits) return value;

    final keep = fraction.substring(0, fractionDigits);
    final nextDigit = int.parse(fraction[fractionDigits]);
    var candidate = keep;
    var carry = nextDigit >= 5;
    if (carry) {
      // Increment the kept fraction as an integer.
      final keepInt = candidate.isEmpty ? BigInt.zero : BigInt.parse(candidate);
      final incremented = keepInt + BigInt.one;
      final padded = incremented.toString().padLeft(fractionDigits, '0');
      if (padded.length > fractionDigits) {
        // Overflow into the integer part (e.g. 9.99 -> 10.00).
        final intPart = text.substring(0, dot);
        final negative = intPart.startsWith('-');
        final unsigned = negative ? intPart.substring(1) : intPart;
        final incrementedInt = (BigInt.parse(unsigned) + BigInt.one).toString();
        final sign = negative ? '-' : '';
        candidate = padded.substring(padded.length - fractionDigits);
        final result = fractionDigits == 0
            ? '$sign$incrementedInt'
            : '$sign$incrementedInt.$candidate';
        return Decimal.parse(result);
      }
      candidate = padded;
    }
    final intPart = text.substring(0, dot);
    final result = fractionDigits == 0 ? intPart : '$intPart.$candidate';
    return Decimal.parse(result);
  }
}
