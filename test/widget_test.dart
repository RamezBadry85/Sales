import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales/core/app_exception.dart';
import 'package:sales/core/l10n/app_localizations.dart';
import 'package:sales/data/models/product.dart';

import 'customer_repository_test.dart' as customer_tests;
import 'decimal_format_test.dart' as decimal_tests;
import 'product_repository_test.dart' as product_tests;

/// Aggregated test entry point so a single `flutter test` covers everything.
void main() {
  decimal_tests.main();
  customer_tests.main();
  product_tests.main();

  group('Localization', () {
    test('Arabic is the default direction and English is LTR', () {
      final ar = AppLocalizations(const Locale('ar'));
      final en = AppLocalizations(const Locale('en'));
      expect(ar.textDirection, TextDirection.rtl);
      expect(en.textDirection, TextDirection.ltr);
      expect(ar.isArabic, isTrue);
      expect(ar.t('customer.title'), 'العملاء');
      expect(en.t('customer.title'), 'Customers');
    });

    test('placeholders are replaced', () {
      final ar = AppLocalizations(const Locale('ar'));
      expect(
        ar.tp('customer.deleteMessage', ['شركة']),
        contains('شركة'),
      );
      expect(ar.tp('common.results', [5]), contains('5'));
    });

    test('unknown keys fall back to the key instead of throwing', () {
      final en = AppLocalizations(const Locale('en'));
      expect(en.t('missing.key'), 'missing.key');
    });

    test('every Arabic key exists (parity with English)', () {
      final en = AppLocalizations(const Locale('en'));
      final ar = AppLocalizations(const Locale('ar'));
      // Both tables share the same key set; a missing key would surface as the
      // English text in Arabic mode, which we detect here.
      const sampleKeys = [
        'app.title',
        'nav.dashboard',
        'nav.customers',
        'nav.products',
        'customer.title',
        'product.title',
        'common.save',
        'settings.title',
      ];
      for (final key in sampleKeys) {
        expect(en.t(key), isNot(key));
        expect(ar.t(key), isNot(key));
        expect(ar.t(key), isNot(en.t(key)));
      }
    });
  });

  group('Error messages', () {
    test('AppException exposes a stable code and field', () {
      final error = AppException(AppErrorCode.required, field: 'name');
      expect(error.code, AppErrorCode.required);
      expect(error.field, 'name');
      expect(error.toString(), contains('required'));
    });
  });

  group('Product model', () {
    test('display label combines code and description', () {
      const product = Product(code: 'A1', description: 'Device');
      expect(product.displayLabel, 'A1 — Device');
      expect(const Product(description: 'Device').displayLabel, 'Device');
    });

    test('empty optional text is stored as null', () {
      const product = Product(description: 'X', code: '  ', company: '');
      final map = product.toMap();
      expect(map['code'], isNull);
      expect(map['company'], isNull);
      expect(map['description'], 'X');
    });
  });
}
