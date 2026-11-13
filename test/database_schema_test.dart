import 'package:flutter_test/flutter_test.dart';
import 'package:sales/core/app_exception.dart';
import 'package:sales/data/database/database_schema.dart';
import 'package:sales/data/models/customer.dart';
import 'package:sales/data/repositories/customer_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/test_database.dart';

/// Verifies the persistence layer itself: schema, migrations and constraints.
void main() {
  setUpAll(sqfliteFfiInit);

  late TestDatabase db;

  setUp(() async {
    db = await TestDatabase.create();
  });

  tearDown(() async {
    await db.close();
  });

  test('database reports the declared schema version', () async {
    final raw = await db.appDatabase.database;
    final version = await raw.getVersion();
    expect(version, DatabaseSchema.version);
  });

  test('all master data and forward-looking tables exist', () async {
    final raw = await db.appDatabase.database;
    final rows = await raw.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final tables = rows.map((row) => row['name'] as String).toSet();

    expect(tables, containsAll(<String>[
      DatabaseSchema.customersTable,
      DatabaseSchema.productsTable,
      DatabaseSchema.quotationsTable,
      DatabaseSchema.quotationItemsTable,
      DatabaseSchema.salesRecordsTable,
    ]));
  });

  test('indexes for search and reporting exist', () async {
    final raw = await db.appDatabase.database;
    final rows = await raw.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_%'",
    );
    final indexes = rows.map((row) => row['name'] as String).toSet();
    expect(indexes, contains('idx_customers_name'));
    expect(indexes, contains('idx_products_code'));
    expect(indexes, contains('idx_products_company'));
    expect(indexes, contains('idx_quotations_customer'));
    expect(indexes, contains('idx_sales_date'));
  });

  test('foreign keys are enforced', () async {
    final raw = await db.appDatabase.database;
    final enabled = await raw.rawQuery('PRAGMA foreign_keys');
    expect(enabled.first.values.first, 1);

    // Inserting a quotation for a non-existent customer must fail.
    final now = DateTime.now().toUtc().toIso8601String();
    await expectLater(
      raw.insert('quotations', {
        'quotation_number': 'Q-1',
        'quotation_date': now,
        'customer_id': 999,
        'created_at': now,
        'updated_at': now,
      }),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('quotation items cascade-delete with their quotation', () async {
    final raw = await db.appDatabase.database;
    final now = DateTime.now().toUtc().toIso8601String();
    final quotationId = await raw.insert('quotations', {
      'quotation_number': 'Q-2',
      'quotation_date': now,
      'created_at': now,
      'updated_at': now,
    });
    await raw.insert('quotation_items', {
      'quotation_id': quotationId,
      'description': 'Line',
      'created_at': now,
      'updated_at': now,
    });

    await raw.delete(
      'quotations',
      where: 'id = ?',
      whereArgs: [quotationId],
    );

    final remaining = await raw.query('quotation_items');
    expect(remaining, isEmpty);
  });

  test('a customer referenced by a quotation cannot be deleted', () async {
    final repository = CustomerRepository(database: db.appDatabase);
    final customerId = await repository.insert(const Customer(name: 'Linked'));

    final raw = await db.appDatabase.database;
    final now = DateTime.now().toUtc().toIso8601String();
    await raw.insert('quotations', {
      'quotation_number': 'Q-3',
      'quotation_date': now,
      'customer_id': customerId,
      'created_at': now,
      'updated_at': now,
    });

    expect(
      () => repository.delete(customerId),
      throwsA(
        isA<AppException>().having((e) => e.code, 'code', AppErrorCode.inUse),
      ),
    );
    expect(await repository.findById(customerId), isNotNull);
  });

  test('a customer referenced by a sales record cannot be deleted', () async {
    final repository = CustomerRepository(database: db.appDatabase);
    final customerId = await repository.insert(const Customer(name: 'Buyer'));

    final raw = await db.appDatabase.database;
    final now = DateTime.now().toUtc().toIso8601String();
    await raw.insert('sales_records', {
      'customer_id': customerId,
      'year': 2026,
      'month': 1,
      'created_at': now,
      'updated_at': now,
    });

    expect(
      () => repository.delete(customerId),
      throwsA(
        isA<AppException>().having((e) => e.code, 'code', AppErrorCode.inUse),
      ),
    );
  });

  test('migration map only targets versions above the current one', () {
    for (final version in DatabaseSchema.migrations.keys) {
      expect(version, greaterThan(1));
      expect(DatabaseSchema.migrations[version], isNotEmpty);
    }
    // Every migration step must be reachable from the declared version.
    for (final version in DatabaseSchema.migrations.keys) {
      expect(version, lessThanOrEqualTo(DatabaseSchema.version));
    }
  });

  test('decimal amounts are stored as text, never as floating point', () async {
    final raw = await db.appDatabase.database;
    final columns = await raw.rawQuery('PRAGMA table_info(products)');
    final price = columns.firstWhere((c) => c['name'] == 'default_price');
    expect(price['type'], 'TEXT');
  });
}
