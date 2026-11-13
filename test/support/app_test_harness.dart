import 'package:sales/app_state.dart';
import 'package:sales/core/settings_controller.dart';
import 'package:sales/data/database/app_database.dart';
import 'package:sales/data/repositories/customer_store.dart';
import 'package:sales/data/repositories/product_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fake_stores.dart';

/// Builds an [AppState] backed by in-memory stores.
///
/// SQLite work cannot complete inside the `testWidgets` fake async zone, so the
/// UI tests exercise the widget layer against stores that complete
/// synchronously. Persistence itself is covered by the repository tests, which
/// run against a real SQLite database.
Future<AppState> testAppState({
  required SettingsController settings,
  AppDatabase? database,
  CustomerStore? customers,
  ProductStore? products,
}) async {
  final handle = database ?? unopenedTestDatabase();
  return AppState(
    settings: settings,
    database: handle,
    customers: customers ?? InMemoryCustomerStore(),
    products: products ?? InMemoryProductStore(),
    databasePath: handle.path,
  );
}

/// Variant of [testAppState] that supplies explicit stores.
Future<AppState> testAppStateFor({
  required SettingsController settings,
  required CustomerStore customers,
  required ProductStore products,
  AppDatabase? database,
}) async {
  final handle = database ?? unopenedTestDatabase();
  return AppState(
    settings: settings,
    database: handle,
    customers: customers,
    products: products,
    databasePath: handle.path,
  );
}

/// Database handle for widget tests.
///
/// Opening a real SQLite connection performs asynchronous platform work that
/// never completes inside the `testWidgets` fake async zone, and the widget
/// layer never touches the connection directly (it goes through the store
/// contracts). An unopened handle is therefore sufficient and keeps the tests
/// deterministic. Real persistence is covered by the repository tests.
AppDatabase unopenedTestDatabase() {
  sqfliteFfiInit();
  return AppDatabase.forTesting(
    factory: databaseFactoryFfi,
    path: inMemoryDatabasePath,
  );
}
