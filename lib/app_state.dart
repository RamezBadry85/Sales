import 'package:flutter/foundation.dart';

import 'core/settings_controller.dart';
import 'data/database/app_database.dart';
import 'data/repositories/customer_repository.dart';
import 'data/repositories/product_repository.dart';

/// Composition root: owns the long lived services used by the UI.
class AppState {
  AppState({
    required this.settings,
    required this.database,
    required this.customers,
    required this.products,
    this.databasePath,
  });

  final SettingsController settings;
  final AppDatabase database;
  final CustomerRepository customers;
  final ProductRepository products;

  /// Human readable location of the SQLite file, when available.
  final String? databasePath;

  static Future<AppState> bootstrap() async {
    final settings = await SettingsController.load();
    final database = AppDatabase.instance;

    String? path;
    try {
      await database.open();
      path = database.path;
    } catch (error) {
      // The UI shows a retry screen; the failure is not hidden here so that
      // the user knows their data cannot be stored.
      debugPrint('Database unavailable at startup: $error');
    }

    return AppState(
      settings: settings,
      database: database,
      customers: CustomerRepository(database: database),
      products: ProductRepository(database: database),
      databasePath: path,
    );
  }
}
