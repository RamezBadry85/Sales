import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales/core/decimal_format.dart';

void main() {
  group('DecimalFormat.tryParse', () {
    test('parses plain integers and decimals', () {
      expect(DecimalFormat.tryParse('1234'), Decimal.fromInt(1234));
      expect(DecimalFormat.tryParse('12.50'), Decimal.parse('12.5'));
      expect(DecimalFormat.tryParse(' 7 '), Decimal.fromInt(7));
    });

    test('parses Arabic-Indic digits and separator', () {
      expect(DecimalFormat.tryParse('١٢٣'), Decimal.fromInt(123));
      expect(DecimalFormat.tryParse('١٢٫٥'), Decimal.parse('12.5'));
      expect(DecimalFormat.tryParse('۴۲'), Decimal.fromInt(42));
    });

    test('handles grouping separators', () {
      expect(DecimalFormat.tryParse('1,234'), Decimal.fromInt(1234));
      expect(DecimalFormat.tryParse('1,234.75'), Decimal.parse('1234.75'));
      expect(DecimalFormat.tryParse('1.234,75'), Decimal.parse('1234.75'));
    });

    test('returns null for invalid input', () {
      expect(DecimalFormat.tryParse(''), isNull);
      expect(DecimalFormat.tryParse(null), isNull);
      expect(DecimalFormat.tryParse('abc'), isNull);
      expect(DecimalFormat.tryParse('.'), isNull);
      expect(DecimalFormat.tryParse(','), isNull);
      expect(DecimalFormat.tryParse('-'), isNull);
      expect(DecimalFormat.tryParse('--1'), isNull);
      expect(DecimalFormat.tryParse('1.2.3'), isNull);
    });
  });

  group('DecimalFormat.format', () {
    test('groups thousands', () {
      expect(DecimalFormat.format(Decimal.fromInt(1234567)), '1,234,567');
    });

    test('respects fraction bounds', () {
      expect(DecimalFormat.format(Decimal.parse('1234.5')), '1,234.5');
      expect(
        DecimalFormat.format(Decimal.parse('1234.5'), minFractionDigits: 2),
        '1,234.50',
      );
      expect(
        DecimalFormat.format(Decimal.parse('2.345'), maxFractionDigits: 2),
        '2.35',
      );
    });

    test('rounds half up across integer boundaries', () {
      expect(
        DecimalFormat.format(Decimal.parse('9.995'), maxFractionDigits: 2),
        '10',
      );
      expect(
        DecimalFormat.format(
          Decimal.parse('9.995'),
          maxFractionDigits: 2,
          minFractionDigits: 2,
        ),
        '10.00',
      );
      expect(
        DecimalFormat.format(
          Decimal.parse('99.999'),
          maxFractionDigits: 2,
          minFractionDigits: 2,
        ),
        '100.00',
      );
      expect(
        DecimalFormat.format(
          Decimal.parse('1234.567'),
          maxFractionDigits: 2,
          minFractionDigits: 2,
        ),
        '1,234.57',
      );
    });

    test('rounds half away from zero for negatives', () {
      expect(
        DecimalFormat.format(Decimal.parse('-2.345'), maxFractionDigits: 2),
        '-2.35',
      );
    });

    test('handles very small and very large values', () {
      expect(DecimalFormat.format(Decimal.parse('0.001')), '0');
      expect(
        DecimalFormat.format(Decimal.parse('0.001'), maxFractionDigits: 3),
        '0.001',
      );
      expect(
        DecimalFormat.format(Decimal.parse('123456789.12'), minFractionDigits: 2),
        '123,456,789.12',
      );
    });

    test('handles negative and zero values', () {
      expect(DecimalFormat.format(Decimal.parse('-1234.50')), '-1,234.5');
      expect(DecimalFormat.format(Decimal.zero), '0');
      expect(DecimalFormat.format(null), '');
      expect(DecimalFormat.format(null, nullText: '—'), '—');
    });
  });

  group('DecimalFormat storage round trip', () {
    test('trims trailing zeros but keeps precision', () {
      expect(DecimalFormat.toStorage(Decimal.parse('12.50')), '12.5');
      expect(DecimalFormat.toStorage(Decimal.parse('100.00')), '100');
      expect(DecimalFormat.toStorage(Decimal.parse('0.001')), '0.001');
      expect(DecimalFormat.toStorage(Decimal.zero), '0');
    });

    test('reads values back without loss', () {
      const values = ['0', '0.5', '12.34', '1234567.891', '-42'];
      for (final raw in values) {
        final decimal = Decimal.parse(raw);
        final stored = DecimalFormat.toStorage(decimal)!;
        expect(DecimalFormat.fromStorage(stored), decimal, reason: raw);
      }
    });
  });
}
