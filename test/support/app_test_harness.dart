import 'package:sales/app_state.dart';
import 'package:sales/core/settings_controller.dart';
import 'package:sales/data/database/app_database.dart';
import 'package:sales/data/repositories/customer_repository.dart';
import 'package:sales/data/repositories/product_repository.dart';

import 'test_database.dart';

/// Builds an [AppState] bound to an isolated test database.
Future<AppState> testAppState({
  required SettingsController settings,
  required AppDatabase database,
}) async {
  return AppState(
    settings: settings,
    database: database,
    customers: CustomerRepository(database: database),
    products: ProductRepository(database: database),
    databasePath: database.path,
  );
}

CustomerRepository testCustomers(TestDatabase db) =>
    CustomerRepository(database: db.appDatabase);

ProductRepository testProducts(TestDatabase db) =>
    ProductRepository(database: db.appDatabase);
