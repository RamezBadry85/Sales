import 'package:sqflite/sqflite.dart';

import 'package:decimal/decimal.dart';

import '../../core/app_exception.dart';
import '../../core/decimal_format.dart';
import '../database/app_database.dart';
import '../database/database_schema.dart';
import '../models/product.dart';
import 'repository_utils.dart';

/// Sort options offered by the product list.
enum ProductSort {
  newest,
  codeAsc,
  descriptionAsc,
  priceAsc;

  String get column => switch (this) {
        ProductSort.newest => 'created_at DESC',
        ProductSort.codeAsc => 'code COLLATE NOCASE ASC, description COLLATE NOCASE ASC',
        ProductSort.descriptionAsc => 'description COLLATE NOCASE ASC',
        ProductSort.priceAsc =>
          'CAST(default_price AS REAL) ASC, description COLLATE NOCASE ASC',
      };
}

/// Persistence for the product catalogue.
///
/// Product codes are deliberately **not** unique: the workbook contains
/// several specifications sharing one code, and all descriptions are preserved.
class ProductRepository {
  ProductRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  static const String _table = DatabaseSchema.productsTable;

  Future<List<Product>> search({
    String query = '',
    String? category,
    String? company,
    ProductSort sort = ProductSort.descriptionAsc,
  }) {
    return guardDatabase(
      () async {
        final db = await _database.database;
        final where = <String>[];
        final args = <Object?>[];

        final trimmed = query.trim();
        if (trimmed.isNotEmpty) {
          final pattern = likePattern(trimmed);
          where.add('('
              'code LIKE ? ESCAPE "\\" OR '
              'description LIKE ? ESCAPE "\\" OR '
              'company LIKE ? ESCAPE "\\" OR '
              'category LIKE ? ESCAPE "\\" OR '
              'unit LIKE ? ESCAPE "\\" OR '
              'notes LIKE ? ESCAPE "\\"'
              ')');
          args.addAll(List<Object?>.filled(6, pattern));
        }
        if (category != null && category.isNotEmpty) {
          where.add('category = ?');
          args.add(category);
        }
        if (company != null && company.isNotEmpty) {
          where.add('company = ?');
          args.add(company);
        }

        final rows = await db.query(
          _table,
          where: where.isEmpty ? null : where.join(' AND '),
          whereArgs: args.isEmpty ? null : args,
          orderBy: sort.column,
        );
        return rows.map(Product.fromMap).toList(growable: false);
      },
      operation: 'products.search',
    );
  }

  Future<List<Product>> all() => search();

  Future<Product?> findById(int id) {
    return guardDatabase(
      () async {
        final db = await _database.database;
        final rows = await db.query(
          _table,
          where: 'id = ?',
          whereArgs: <Object?>[id],
          limit: 1,
        );
        if (rows.isEmpty) return null;
        return Product.fromMap(rows.first);
      },
      operation: 'products.findById',
    );
  }

  Future<int> count() {
    return guardDatabase(
      () async {
        final db = await _database.database;
        final result = await db.rawQuery('SELECT COUNT(*) AS c FROM $_table');
        return Sqflite.firstIntValue(result) ?? 0;
      },
      operation: 'products.count',
    );
  }

  /// Distinct values used to build category and company filters.
  Future<List<String>> distinctValues(String column) {
    return guardDatabase(
      () async {
        if (column != 'category' && column != 'company' && column != 'unit') {
          throw ArgumentError.value(column, 'column', 'unsupported column');
        }
        final db = await _database.database;
        final rows = await db.rawQuery(
          'SELECT DISTINCT $column AS value FROM $_table '
          'WHERE $column IS NOT NULL AND TRIM($column) <> "" '
          'ORDER BY $column COLLATE NOCASE ASC',
        );
        return rows
            .map((row) => row['value'] as String)
            .where((value) => value.trim().isNotEmpty)
            .toList(growable: false);
      },
      operation: 'products.distinctValues',
    );
  }

  Future<int> insert(Product product) {
    return guardDatabase(
      () async {
        _validate(product);
        final db = await _database.database;
        final now = nowIso8601();
        final map = product.toMap()
          ..['created_at'] = now
          ..['updated_at'] = now;
        return db.insert(_table, map);
      },
      operation: 'products.insert',
    );
  }

  Future<void> update(Product product) {
    return guardDatabase(
      () async {
        final id = product.id;
        if (id == null) {
          throw AppException(AppErrorCode.notFound, debugDetail: 'missing id');
        }
        _validate(product);
        final db = await _database.database;
        final map = product.toMap()..['updated_at'] = nowIso8601();
        final affected = await db.update(
          _table,
          map,
          where: 'id = ?',
          whereArgs: <Object?>[id],
        );
        if (affected == 0) {
          throw AppException(AppErrorCode.notFound, debugDetail: 'id $id');
        }
      },
      operation: 'products.update',
    );
  }

  Future<void> delete(int id) {
    return guardDatabase(
      () async {
        final db = await _database.database;
        final quotationItems = Sqflite.firstIntValue(
              await db.rawQuery(
                'SELECT COUNT(*) FROM ${DatabaseSchema.quotationItemsTable} WHERE product_id = ?',
                <Object?>[id],
              ),
            ) ??
            0;
        if (quotationItems > 0) {
          throw AppException(
            AppErrorCode.inUse,
            debugDetail: 'product $id referenced by $quotationItems items',
          );
        }
        final affected = await db.delete(
          _table,
          where: 'id = ?',
          whereArgs: <Object?>[id],
        );
        if (affected == 0) {
          throw AppException(AppErrorCode.notFound, debugDetail: 'id $id');
        }
      },
      operation: 'products.delete',
    );
  }

  void _validate(Product product) {
    if (product.description.trim().isEmpty) {
      throw AppException(AppErrorCode.required, field: 'description');
    }
    final price = product.defaultPrice;
    if (price != null && price < Decimal.zero) {
      throw AppException(AppErrorCode.invalidNumber, field: 'default_price');
    }
    // Guard against accidental precision loss when a value cannot be stored.
    if (price != null && DecimalFormat.toStorage(price) == null) {
      throw AppException(AppErrorCode.invalidNumber, field: 'default_price');
    }
  }
}
