import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales/core/app_exception.dart';
import 'package:sales/data/models/product.dart';
import 'package:sales/data/repositories/product_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/test_database.dart';

void main() {
  late TestDatabase db;
  late ProductRepository repository;

  setUpAll(_initFfi);

  setUp(() async {
    db = await TestDatabase.create();
    repository = ProductRepository(database: db.appDatabase);
  });

  tearDown(() async {
    await db.close();
  });

  test('starts empty (no seeded demo data)', () async {
    expect(await repository.count(), 0);
    expect(await repository.all(), isEmpty);
  });

  test('stores every product field and the exact decimal price', () async {
    final id = await repository.insert(
      Product(
        category: 'أجهزة',
        company: 'Siemens',
        code: 'A-100',
        description: 'جهاز أشعة محمول',
        unit: 'قطعة',
        defaultPrice: Decimal.parse('1250.75'),
        notes: 'ملاحظة',
      ),
    );

    final loaded = await repository.findById(id);
    expect(loaded, isNotNull);
    expect(loaded!.category, 'أجهزة');
    expect(loaded.company, 'Siemens');
    expect(loaded.code, 'A-100');
    expect(loaded.description, 'جهاز أشعة محمول');
    expect(loaded.unit, 'قطعة');
    expect(loaded.defaultPrice, Decimal.parse('1250.75'));
    expect(loaded.notes, 'ملاحظة');
  });

  test('allows duplicate product codes (business rule)', () async {
    final first = await repository.insert(
      const Product(code: 'SAME-1', description: 'Specification A'),
    );
    final second = await repository.insert(
      const Product(code: 'SAME-1', description: 'Specification B'),
    );

    expect(first, isNot(second));
    final all = await repository.all();
    expect(all.length, 2);
    expect(
      all.where((p) => p.code == 'SAME-1').map((p) => p.description).toSet(),
      {'Specification A', 'Specification B'},
    );
  });

  test('rejects a product without a description', () async {
    expect(
      () => repository.insert(const Product(description: '  ')),
      throwsA(
        isA<AppException>().having((e) => e.code, 'code', AppErrorCode.required),
      ),
    );
  });

  test('rejects a negative price', () async {
    expect(
      () => repository.insert(
        Product(description: 'X', defaultPrice: Decimal.parse('-1')),
      ),
      throwsA(
        isA<AppException>()
            .having((e) => e.code, 'code', AppErrorCode.invalidNumber),
      ),
    );
  });

  test('search covers code, description, company, category, unit, notes',
      () async {
    await repository.insert(
      const Product(
        code: 'ZX9',
        description: 'Ultrasound probe',
        company: 'GE',
        category: 'Imaging',
        unit: 'box',
        notes: 'fragile',
      ),
    );
    await repository.insert(const Product(description: 'Plain product'));

    for (final query in ['zx9', 'ultrasound', 'ge', 'imaging', 'box', 'fragile']) {
      expect(
        (await repository.search(query: query)).length,
        1,
        reason: 'query $query',
      );
    }
    expect((await repository.search()).length, 2);
  });

  test('filters by category and company', () async {
    await repository.insert(
      const Product(
        description: 'A',
        category: 'Cat1',
        company: 'Comp1',
      ),
    );
    await repository.insert(
      const Product(
        description: 'B',
        category: 'Cat2',
        company: 'Comp1',
      ),
    );
    await repository.insert(
      const Product(
        description: 'C',
        category: 'Cat1',
        company: 'Comp2',
      ),
    );

    expect((await repository.search(category: 'Cat1')).length, 2);
    expect((await repository.search(company: 'Comp1')).length, 2);
    expect(
      (await repository.search(category: 'Cat1', company: 'Comp2')).length,
      1,
    );
  });

  test('returns distinct filter values sorted alphabetically', () async {
    await repository.insert(
      const Product(description: 'A', category: 'Beta', company: 'Zeta'),
    );
    await repository.insert(
      const Product(description: 'B', category: 'Alpha', company: 'Yankee'),
    );
    await repository.insert(const Product(description: 'C'));

    expect(await repository.distinctValues('category'), ['Alpha', 'Beta']);
    expect(await repository.distinctValues('company'), ['Yankee', 'Zeta']);
    expect(await repository.distinctValues('unit'), isEmpty);
  });

  test('sorts by description, code, price and recency', () async {
    await repository.insert(
      Product(code: 'C2', description: 'Beta', defaultPrice: Decimal.fromInt(30)),
    );
    await repository.insert(
      Product(code: 'C1', description: 'Alpha', defaultPrice: Decimal.fromInt(10)),
    );
    await repository.insert(
      Product(code: 'C3', description: 'Gamma', defaultPrice: Decimal.fromInt(20)),
    );

    expect(
      (await repository.search(sort: ProductSort.descriptionAsc))
          .map((p) => p.description),
      ['Alpha', 'Beta', 'Gamma'],
    );
    expect(
      (await repository.search(sort: ProductSort.codeAsc)).map((p) => p.code),
      ['C1', 'C2', 'C3'],
    );
    expect(
      (await repository.search(sort: ProductSort.priceAsc))
          .map((p) => p.description),
      ['Alpha', 'Gamma', 'Beta'],
    );
    expect(
      (await repository.search(sort: ProductSort.newest)).first.description,
      'Gamma',
    );
  });

  test('updates and deletes a product', () async {
    final id = await repository.insert(
      const Product(code: 'X', description: 'Before'),
    );
    final loaded = await repository.findById(id);
    await repository.update(
      loaded!.copyWith(description: 'After', code: 'Y'),
    );

    final updated = await repository.findById(id);
    expect(updated!.description, 'After');
    expect(updated.code, 'Y');

    await repository.delete(id);
    expect(await repository.findById(id), isNull);
  });

  test('a product used by a quotation item cannot be deleted', () async {
    final productId = await repository.insert(
      const Product(description: 'Used product'),
    );

    // Simulate a quotation that references the product.
    final raw = await db.appDatabase.database;
    final now = DateTime.now().toUtc().toIso8601String();
    await raw.insert('quotations', {
      'quotation_number': 'Q-1',
      'quotation_date': now,
      'created_at': now,
      'updated_at': now,
    });
    await raw.insert('quotation_items', {
      'quotation_id': 1,
      'product_id': productId,
      'description': 'Used product',
      'created_at': now,
      'updated_at': now,
    });

    expect(
      () => repository.delete(productId),
      throwsA(isA<AppException>().having((e) => e.code, 'code', AppErrorCode.inUse)),
    );
  });

  test('price is stored as text without binary floating point loss', () async {
    await repository.insert(
      Product(
        description: 'Precise',
        defaultPrice: Decimal.parse('0.1') + Decimal.parse('0.2'),
      ),
    );
    final rows = await repository.all();
    expect(rows.single.defaultPrice, Decimal.parse('0.3'));
  });
}

/// Ensures the FFI factory is initialized for the test isolate.
void _initFfi() {
  sqfliteFfiInit();
}
