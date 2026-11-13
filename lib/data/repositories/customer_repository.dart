import 'package:sqflite_common/sqlite_api.dart';

import '../../core/app_exception.dart';
import '../database/app_database.dart';
import '../database/database_schema.dart';
import '../models/customer.dart';
import 'repository_utils.dart';

/// Sort options offered by the customer list.
enum CustomerSort {
  nameAsc,
  newest,
  oldest;

  String get column => switch (this) {
        CustomerSort.nameAsc => 'name COLLATE NOCASE ASC',
        CustomerSort.newest => 'created_at DESC',
        CustomerSort.oldest => 'created_at ASC',
      };
}

/// Persistence for customer master data.
class CustomerRepository {
  CustomerRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  static const String _table = DatabaseSchema.customersTable;

  Future<List<Customer>> search({
    String query = '',
    CustomerSort sort = CustomerSort.nameAsc,
  }) {
    return guardDatabase(
      () async {
        final db = await _database.database;
        final trimmed = query.trim();
        final where = <String>[];
        final args = <Object?>[];

        if (trimmed.isNotEmpty) {
          final pattern = likePattern(trimmed);
          where.add('('
              'name LIKE ? ESCAPE "\\" OR '
              'account_name LIKE ? ESCAPE "\\" OR '
              'contact_person LIKE ? ESCAPE "\\" OR '
              'phone LIKE ? ESCAPE "\\" OR '
              'email LIKE ? ESCAPE "\\" OR '
              'address LIKE ? ESCAPE "\\"'
              ')');
          args.addAll(List<Object?>.filled(6, pattern));
        }

        final rows = await db.query(
          _table,
          where: where.isEmpty ? null : where.join(' AND '),
          whereArgs: args.isEmpty ? null : args,
          orderBy: sort.column,
        );
        return rows.map(Customer.fromMap).toList(growable: false);
      },
      operation: 'customers.search',
    );
  }

  Future<List<Customer>> all() => search();

  Future<Customer?> findById(int id) {
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
        return Customer.fromMap(rows.first);
      },
      operation: 'customers.findById',
    );
  }

  Future<int> count() {
    return guardDatabase(
      () async {
        final db = await _database.database;
        final result = await db.rawQuery('SELECT COUNT(*) AS c FROM $_table');
        return Sqflite.firstIntValue(result) ?? 0;
      },
      operation: 'customers.count',
    );
  }

  /// Inserts a new customer and returns the assigned identifier.
  Future<int> insert(Customer customer) {
    return guardDatabase(
      () async {
        _validate(customer);
        final db = await _database.database;
        final now = nowIso8601();
        final map = customer.toMap()
          ..['created_at'] = now
          ..['updated_at'] = now;
        return db.insert(_table, map);
      },
      operation: 'customers.insert',
    );
  }

  Future<void> update(Customer customer) {
    return guardDatabase(
      () async {
        final id = customer.id;
        if (id == null) {
          throw AppException(AppErrorCode.notFound, debugDetail: 'missing id');
        }
        _validate(customer);
        final db = await _database.database;
        final map = customer.toMap()..['updated_at'] = nowIso8601();
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
      operation: 'customers.update',
    );
  }

  /// Deletes a customer. Refuses when quotations or sales reference it.
  Future<void> delete(int id) {
    return guardDatabase(
      () async {
        final db = await _database.database;
        final references = await _referenceCount(db, id);
        if (references > 0) {
          throw AppException(
            AppErrorCode.inUse,
            debugDetail: 'customer $id referenced by $references records',
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
      operation: 'customers.delete',
    );
  }

  Future<int> _referenceCount(Database db, int id) async {
    final quotationCount = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${DatabaseSchema.quotationsTable} WHERE customer_id = ?',
            <Object?>[id],
          ),
        ) ??
        0;
    final salesCount = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${DatabaseSchema.salesRecordsTable} WHERE customer_id = ?',
            <Object?>[id],
          ),
        ) ??
        0;
    return quotationCount + salesCount;
  }

  void _validate(Customer customer) {
    if (customer.name.trim().isEmpty) {
      throw AppException(AppErrorCode.required, field: 'name');
    }
    final email = customer.email?.trim();
    if (email != null && email.isNotEmpty) {
      final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
      if (!valid) {
        throw AppException(AppErrorCode.invalidEmail, field: 'email');
      }
    }
  }
}
