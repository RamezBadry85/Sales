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

import '../support/fake_stores.dart';
import '../support/test_database.dart';

/// End-to-end UI tests for the Arabic-first shell, customers and products.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
  });

  // The UI tests run on a wide desktop-like surface so the sidebar layout is
  // exercised, then the compact layout is verified separately.
  Future<void> useDesktopSurface(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<
      ({
        InMemoryCustomerStore customers,
        InMemoryProductStore products,
      })> buildApp(
    WidgetTester tester, {
    String locale = 'ar',
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final settings = await SettingsController.load();
    await settings.setLocale(Locale(locale));
    final customers = InMemoryCustomerStore();
    final products = InMemoryProductStore();
    final db = await TestDatabase.create();
    addTearDown(db.close);
    final state = await testAppStateFor(
      settings: settings,
      customers: customers,
      products: products,
      database: db.appDatabase,
    );
    await tester.pumpWidget(SalesApp(state: state));
    await tester.pumpAndSettle();
    return (customers: customers, products: products);
  }

  testWidgets('renders Arabic RTL navigation in a fresh database',
      (tester) async {
    await useDesktopSurface(tester);
    await buildApp(tester);

    final direction = Directionality.of(tester.element(find.byType(Scaffold).first));
    expect(direction, TextDirection.rtl);
    expect(find.text('لوحة التحكم'), findsWidgets);
    expect(find.text('العملاء'), findsWidgets);
    expect(find.text('المنتجات'), findsWidgets);
    // No demo statistics: the dashboard shows real zeros.
    expect(find.text('0'), findsNWidgets(2));
    expect(find.text('قاعدة البيانات فارغة. ابدأ بإضافة العملاء والمنتجات.'),
        findsOneWidget);
  });

  testWidgets('renders English LTR when the language is English',
      (tester) async {
    await useDesktopSurface(tester);
    await buildApp(tester, locale: 'en');

    final direction = Directionality.of(tester.element(find.byType(Scaffold).first));
    expect(direction, TextDirection.ltr);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Customers'), findsWidgets);
  });

  testWidgets('customer list shows an empty state instead of fake rows',
      (tester) async {
    await useDesktopSurface(tester);
    await buildApp(tester);

    await tester.tap(find.text('العملاء').first);
    await tester.pumpAndSettle();

    expect(find.text('لا يوجد عملاء بعد'), findsOneWidget);
    expect(find.text('أضف أول عميل للبدء في إنشاء عروض الأسعار.'), findsOneWidget);
    expect(find.byType(DataTable), findsNothing);
  });

  testWidgets('creates a customer through the form and lists it',
      (tester) async {
    await useDesktopSurface(tester);
    final stores = await buildApp(tester);

    await tester.tap(find.text('العملاء').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'إضافة عميل').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'اسم العميل *'),
      'مستشفى الشفاء',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'اسم الحساب'),
      'حساب الشفاء',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'رقم الهاتف'),
      '01000000000',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
    await tester.pumpAndSettle();

    expect(find.text('مستشفى الشفاء'), findsWidgets);
    expect(find.text('حساب الشفاء'), findsWidgets);

    final stored = await stores.customers.all();
    expect(stored.length, 1);
    expect(stored.single.name, 'مستشفى الشفاء');
    expect(stored.single.accountName, 'حساب الشفاء');
    expect(stored.single.phone, '01000000000');
  });

  testWidgets('blocks saving a customer without a name', (tester) async {
    await useDesktopSurface(tester);
    final stores = await buildApp(tester);

    await tester.tap(find.text('العملاء').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'إضافة عميل').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
    await tester.pumpAndSettle();

    expect(find.text('أدخل الاسم.'), findsOneWidget);
    expect(await stores.customers.count(), 0);
  });

  testWidgets('rejects an invalid email', (tester) async {
    await useDesktopSurface(tester);
    final stores = await buildApp(tester);

    await tester.tap(find.text('العملاء').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'إضافة عميل').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'اسم العميل *'), 'X');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'البريد الإلكتروني'),
      'bad-email',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
    await tester.pumpAndSettle();

    expect(find.text('أدخل بريداً إلكترونياً صحيحاً.'), findsOneWidget);
    expect(await stores.customers.count(), 0);
  });

  testWidgets('deleting a customer requires confirmation', (tester) async {
    await useDesktopSurface(tester);
    final stores = await buildApp(tester);
    await stores.customers.insert(const Customer(name: 'قابل للحذف'));

    await tester.tap(find.text('العملاء').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('حذف').first);
    await tester.pumpAndSettle();
    expect(find.text('حذف العميل؟'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'إلغاء'));
    await tester.pumpAndSettle();
    expect(await stores.customers.count(), 1);

    await tester.tap(find.byTooltip('حذف').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'حذف'));
    await tester.pumpAndSettle();

    expect(await stores.customers.count(), 0);
    expect(find.text('تم حذف العميل.'), findsWidgets);
  });

  testWidgets('search filters customers', (tester) async {
    await useDesktopSurface(tester);
    final stores = await buildApp(tester);
    await stores.customers.insert(const Customer(name: 'Alpha Hospital'));
    await stores.customers.insert(const Customer(name: 'Beta Clinic'));

    await tester.tap(find.text('العملاء').first);
    await tester.pumpAndSettle();
    expect(find.text('Alpha Hospital'), findsWidgets);
    expect(find.text('Beta Clinic'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, 'Beta');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(find.text('Beta Clinic'), findsWidgets);
    expect(find.text('Alpha Hospital'), findsNothing);
  });

  testWidgets('products with duplicate codes are both preserved',
      (tester) async {
    await useDesktopSurface(tester);
    final stores = await buildApp(tester);
    await stores.products.insert(
      const Product(code: 'DUP-1', description: 'First variant'),
    );

    await tester.tap(find.text('المنتجات').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'إضافة منتج').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'وصف المنتج *'),
      'Second variant',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'كود المنتج'),
      'DUP-1',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
    await tester.pumpAndSettle();

    final stored = await stores.products.search(query: 'DUP-1');
    expect(stored.length, 2);
    expect(
      stored.map((p) => p.description).toSet(),
      {'First variant', 'Second variant'},
    );
  });

  testWidgets('store form saves a price with Arabic digits', (tester) async {
    await useDesktopSurface(tester);
    final stores = await buildApp(tester);

    await tester.tap(find.text('المنتجات').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'إضافة منتج').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'وصف المنتج *'),
      'جهاز',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'السعر الافتراضي'),
      '١٢٥٠٫٧٥',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
    await tester.pumpAndSettle();

    final stored = await stores.products.all();
    expect(stored.single.defaultPrice.toString(), '1250.75');
  });

  testWidgets('modules from later phases show an explicit placeholder',
      (tester) async {
    await useDesktopSurface(tester);
    await buildApp(tester);

    await tester.tap(find.text('عروض الأسعار').first);
    await tester.pumpAndSettle();
    expect(find.text('هذا القسم سيتم إضافته في مرحلة لاحقة.'), findsWidgets);
  });

  testWidgets('compact layout uses bottom navigation and a drawer',
      (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await buildApp(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
  });

  test('localization delegate supports Arabic and English only', () {
    const delegate = AppLocalizations.delegate;
    expect(delegate.isSupported(const Locale('ar')), isTrue);
    expect(delegate.isSupported(const Locale('en')), isTrue);
    expect(delegate.isSupported(const Locale('fr')), isFalse);
    expect(GlobalMaterialLocalizations.delegate, isNotNull);
  });
}
