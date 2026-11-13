import 'package:sales/data/database/app_database.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// In-memory database used by repository and widget tests.
///
/// It reuses the production [AppDatabase] so schema creation, migrations and
/// foreign key configuration are exercised exactly as in the app.
class TestDatabase {
  TestDatabase._(this.appDatabase);

  final AppDatabase appDatabase;

  static Future<TestDatabase> create() async {
    sqfliteFfiInit();
    final appDatabase = AppDatabase.forTesting(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    await appDatabase.open();
    return TestDatabase._(appDatabase);
  }

  Future<void> close() => appDatabase.close();
}

/// Opens a file backed database so persistence across restarts can be tested.
Future<AppDatabase> openFileDatabase(String path) async {
  sqfliteFfiInit();
  final appDatabase = AppDatabase.forTesting(
    factory: databaseFactoryFfi,
    path: path,
  );
  await appDatabase.open();
  return appDatabase;
}
