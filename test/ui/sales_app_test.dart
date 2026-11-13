import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales/app.dart';
import 'package:sales/core/l10n/app_localizations.dart';
import 'package:sales/core/settings_controller.dart';
import 'package:sales/data/models/customer.dart';
import 'package:sales/data/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/app_test_harness.dart';
import '../support/test_database.dart';

/// End to end UI tests for the Arabic-first shell, customer and product flows.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<SalesApp> buildApp(TestDatabase db, {String locale = 'ar'}) async {
    final settings = await SettingsController.load();
    await settings.setLocale(Locale(locale));
    final state = await testAppState(
      settings: settings,
      database: db.appDatabase,
    );
    return SalesApp(state: state);
  }

  testWidgets('starts in Arabic RTL with Arabic navigation labels',
      (tester) async {
    final db = await TestDatabase.create();
    addTearDown(db.close);

    await tester.pumpWidget(await buildApp(db));
    await tester.pumpAndSettle();

    final direction = Directionality.of(
      tester.element(find.byType(Scaffold).first),
    );
    expect(direction, TextDirection.rtl);
    expect(find.text('العملاء'), findsWidgets);
    expect(find.text('المنتجات'), findsWidgets);
    expect(find.text('لوحة التحكم'), findsWidgets);
  });

  testWidgets('switching language produces an English LTR layout',
      (tester) async {
    final db = await TestDatabase.create();
    addTearDown(db.close);

    await tester.pumpWidget(await buildApp(db, locale: 'en'));
    await tester.pumpAndSettle();

    final direction = Directionality.of(
      tester.element(find.byType(Scaffold).first),
    );
    expect(direction, TextDirection.ltr);
    expect(find.text('Customers'), findsWidgets);
    expect(find.text('Dashboard'), findsWidgets);
  });

  testWidgets('empty customer list shows an empty state, never fake rows',
      (tester) async {
    final db = await TestDatabase.create();
    addTearDown(db.close);

    await tester.pumpWidget(await buildApp(db));
    await tester.pumpAndSettle();

    await tester.tap(find.text('العملاء').last);
    await tester.pumpAndSettle();

    expect(find.text('لا يوجد عملاء بعد'), findsOneWidget);
    expect(find.text('إضافة عميل'), findsWidgets);
    // No data rows exist in a fresh database.
    expect(find.byType(DataRow), findsNothing);
  });

  testWidgets('customer created through the form is persisted and listed',
      (tester) async {
    final db = await TestDatabase.create();
    addTearDown(db.close);

    await tester.pumpWidget(await buildApp(db));
    await tester.pumpAndSettle();

    await tester.tap(find.text('العملاء').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'إضافة عميل').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'اسم العميل *'),
      'مستشفى الشفاء',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'رقم الهاتف'),
      '01000000000',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
    await tester.pumpAndSettle();

    expect(find.text('مستشفى الشفاء'), findsWidgets);

    // Verify persistence in the database itself, not just the widget tree.
    final stored = await testCustomers(db).all();
    expect(stored.length, 1);
    expect(stored.single.name, 'مستشفى الشفاء');
    expect(stored.single.phone, '01000000000');
  });

  testWidgets('validation blocks an empty customer name', (tester) async {
    final db = await TestDatabase.create();
    addTearDown(db.close);

    await tester.pumpWidget(await buildApp(db));
    await tester.pumpAndSettle();

    await tester.tap(find.text('العملاء').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'إضافة عميل').first);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
    await tester.pumpAndSettle();

    expect(find.text('أدخل الاسم.'), findsOneWidget);
    expect(await testCustomers(db).count(), 0);
  });

  testWidgets('product with a duplicated code is accepted', (tester) async {
    final db = await TestDatabase.create();
    addTearDown(db.close);
    final products = testProducts(db);
    await products.insert(
      const Product(code: 'DUP-1', description: 'First variant'),
    );

    await tester.pumpWidget(await buildApp(db));
    await tester.pumpAndSettle();

    await tester.tap(find.text('المنتجات').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'إضافة منتج').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'وصف المنتج *'),
      'Second variant',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'كود المنتج'), 'DUP-1');
    await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
    await tester.pumpAndSettle();

    final stored = await products.search(query: 'DUP-1');
    expect(stored.length, 2);
    expect(
      stored.map((p) => p.description).toSet(),
      {'First variant', 'Second variant'},
    );
  });

  testWidgets('deleting a customer requires confirmation', (tester) async {
    final db = await TestDatabase.create();
    addTearDown(db.close);
    final repo = testCustomers(db);
    final id = await repo.insert(const Customer(name: 'قابل للحذف'));

    await tester.pumpWidget(await buildApp(db));
    await tester.pumpAndSettle();

    await tester.tap(find.text('العملاء').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('حذف').first);
    await tester.pumpAndSettle();

    expect(find.text('حذف العميل؟'), findsOneWidget);
    // Cancel keeps the record.
    await tester.tap(find.widgetWithText(TextButton, 'إلغاء'));
    await tester.pumpAndSettle();
    expect(await repo.findById(id), isNotNull);

    await tester.tap(find.byTooltip('حذف').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'حذف'));
    await tester.pumpAndSettle();

    expect(await repo.findById(id), isNull);
  });

  testWidgets('search filters the customer list', (tester) async {
    final db = await TestDatabase.create();
    addTearDown(db.close);
    final repo = testCustomers(db);
    await repo.insert(const Customer(name: 'Alpha Hospital'));
    await repo.insert(const Customer(name: 'Beta Clinic'));

    await tester.pumpWidget(await buildApp(db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('العملاء').last);
    await tester.pumpAndSettle();

    expect(find.text('Alpha Hospital'), findsWidgets);
    expect(find.text('Beta Clinic'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, 'Beta');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Beta Clinic'), findsWidgets);
    expect(find.text('Alpha Hospital'), findsNothing);
  });

  testWidgets('unsupported module shows a clear placeholder without data',
      (tester) async {
    final db = await TestDatabase.create();
    addTearDown(db.close);

    await tester.pumpWidget(await buildApp(db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('عروض الأسعار').last);
    await tester.pumpAndSettle();

    expect(find.text('هذا القسم سيتم إضافته في مرحلة لاحقة.'), findsWidgets);
  });

  test('localization delegate supports Arabic and English only', () {
    const delegate = AppLocalizations.delegate;
    expect(delegate.isSupported(const Locale('ar')), isTrue);
    expect(delegate.isSupported(const Locale('en')), isTrue);
    expect(delegate.isSupported(const Locale('fr')), isFalse);
    expect(GlobalMaterialLocalizations.delegate, isNotNull);
  });
}
