import 'package:sales/app_state.dart';
import 'package:sales/core/settings_controller.dart';
import 'package:sales/data/database/app_database.dart';
import 'package:sales/data/repositories/customer_store.dart';
import 'package:sales/data/repositories/product_store.dart';

import 'fake_stores.dart';

/// Builds an [AppState] backed by in-memory stores.
///
/// SQLite work cannot complete inside the `testWidgets` fake async zone, so the
/// UI tests exercise the widget layer against stores that complete
/// synchronously. Persistence itself is covered by the repository tests, which
/// run against a real SQLite database.
Future<AppState> testAppState({
  required SettingsController settings,
  required AppDatabase database,
  CustomerStore? customers,
  ProductStore? products,
}) async {
  return AppState(
    settings: settings,
    database: database,
    customers: customers ?? InMemoryCustomerStore(),
    products: products ?? InMemoryProductStore(),
    databasePath: database.path,
  );
}

/// Variant of [testAppState] that also supplies the (unused for persistence)
/// database handle and explicit stores.
Future<AppState> testAppStateFor({
  required SettingsController settings,
  required CustomerStore customers,
  required ProductStore products,
  required AppDatabase database,
}) async {
  return AppState(
    settings: settings,
    database: database,
    customers: customers,
    products: products,
    databasePath: database.path,
  );
}
