import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sales/core/app_exception.dart';
import 'package:sales/data/models/customer.dart';
import 'package:sales/data/repositories/customer_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/test_database.dart';

void main() {
  late TestDatabase db;
  late CustomerRepository repository;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    db = await TestDatabase.create();
    repository = CustomerRepository(database: db.appDatabase);
  });

  tearDown(() async {
    await db.close();
  });

  test('starts empty (no seeded demo data)', () async {
    expect(await repository.count(), 0);
    expect(await repository.all(), isEmpty);
  });

  test('inserts and reads a customer back with all fields', () async {
    final id = await repository.insert(
      const Customer(
        name: 'شركة النور',
        accountName: 'مستشفى النور',
        contactPerson: 'أحمد علي',
        phone: '01001234567',
        email: 'a@example.com',
        address: 'القاهرة',
        notes: 'عميل مهم',
      ),
    );

    final loaded = await repository.findById(id);
    expect(loaded, isNotNull);
    expect(loaded!.name, 'شركة النور');
    expect(loaded.accountName, 'مستشفى النور');
    expect(loaded.contactPerson, 'أحمد علي');
    expect(loaded.phone, '01001234567');
    expect(loaded.email, 'a@example.com');
    expect(loaded.address, 'القاهرة');
    expect(loaded.notes, 'عميل مهم');
    expect(loaded.createdAt, isNotNull);
    expect(loaded.displayAccountName, 'مستشفى النور');
  });

  test('blank optional fields are stored as null', () async {
    final id = await repository.insert(
      const Customer(name: 'Test', phone: '   ', email: ''),
    );
    final loaded = await repository.findById(id);
    expect(loaded!.phone, isNull);
    expect(loaded.email, isNull);
  });

  test('updates an existing customer', () async {
    final id = await repository.insert(const Customer(name: 'Old name'));
    final loaded = await repository.findById(id);
    await repository.update(loaded!.copyWith(name: 'New name', phone: '123'));

    final updated = await repository.findById(id);
    expect(updated!.name, 'New name');
    expect(updated.phone, '123');
  });

  test('rejects a customer without a name', () async {
    expect(
      () => repository.insert(const Customer(name: '   ')),
      throwsA(
        isA<AppException>()
            .having((e) => e.code, 'code', AppErrorCode.required),
      ),
    );
  });

  test('rejects an invalid email', () async {
    expect(
      () => repository.insert(const Customer(name: 'X', email: 'not-an-email')),
      throwsA(
        isA<AppException>()
            .having((e) => e.code, 'code', AppErrorCode.invalidEmail),
      ),
    );
  });

  test('search matches name, account, contact, phone and email', () async {
    await repository.insert(
      const Customer(
        name: 'Alpha',
        accountName: 'Beta Hospital',
        contactPerson: 'Gamal',
        phone: '555111',
        email: 'gamma@test.com',
      ),
    );
    await repository.insert(const Customer(name: 'Delta'));

    expect((await repository.search(query: 'alpha')).length, 1);
    expect((await repository.search(query: 'beta')).length, 1);
    expect((await repository.search(query: 'gamal')).length, 1);
    expect((await repository.search(query: '555')).length, 1);
    expect((await repository.search(query: 'gamma')).length, 1);
    expect((await repository.search(query: 'nothing')).length, 0);
    expect((await repository.search()).length, 2);
  });

  test('search treats LIKE wildcards literally', () async {
    await repository.insert(const Customer(name: '100% Care'));
    await repository.insert(const Customer(name: 'Plain'));
    final results = await repository.search(query: '100%');
    expect(results.length, 1);
    expect(results.first.name, '100% Care');
    expect((await repository.search(query: '%')).length, 1);
  });

  test('sorts by name and by creation date', () async {
    await repository.insert(const Customer(name: 'Zeta'));
    await repository.insert(const Customer(name: 'Alpha'));
    await repository.insert(const Customer(name: 'Mid'));

    final byName = await repository.search(sort: CustomerSort.nameAsc);
    expect(byName.map((c) => c.name), ['Alpha', 'Mid', 'Zeta']);

    final newest = await repository.search(sort: CustomerSort.newest);
    expect(newest.first.name, 'Mid');

    final oldest = await repository.search(sort: CustomerSort.oldest);
    expect(oldest.first.name, 'Zeta');
  });

  test('deletes a customer', () async {
    final id = await repository.insert(const Customer(name: 'Temp'));
    await repository.delete(id);
    expect(await repository.findById(id), isNull);
    expect(await repository.count(), 0);
  });

  test('deleting a missing customer raises notFound', () async {
    expect(
      () => repository.delete(999),
      throwsA(
        isA<AppException>().having((e) => e.code, 'code', AppErrorCode.notFound),
      ),
    );
  });

  test('data survives closing and reopening the database file', () async {
    // A file based database is used so persistence across connections is
    // actually verified instead of relying on in-memory state.
    final path = p.join(
      Directory.systemTemp.createTempSync('sales_test').path,
      'sales_persistence_test.db',
    );

    final first = await openFileDatabase(path);
    final firstRepo = CustomerRepository(database: first);
    await firstRepo.insert(const Customer(name: 'Persisted customer'));
    await first.close();

    final second = await openFileDatabase(path);
    final secondRepo = CustomerRepository(database: second);
    final stored = await secondRepo.all();
    expect(stored.length, 1);
    expect(stored.first.name, 'Persisted customer');
    await second.close();
  });
}
