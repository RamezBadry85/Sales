import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../core/app_exception.dart';
import 'database_schema.dart';
import 'database_opener.dart';

/// Owns the SQLite connection used by the whole application.
///
/// The class is intentionally environment aware:
/// * Android / iOS use the platform `sqflite` implementation.
/// * Windows / Linux / macOS use `sqflite_common_ffi`.
/// * Web uses `sqflite_common_ffi_web` when its assets are available.
///
/// Only one connection is opened; repositories receive the shared instance.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  /// Builds an isolated instance for tests, using an in-memory database.
  ///
  /// Production code always uses [instance].
  factory AppDatabase.forTesting({
    required DatabaseFactory factory,
    String path = inMemoryDatabasePath,
  }) {
    return AppDatabase._().._testFactory = factory.._testPath = path;
  }

  Database? _database;
  DatabaseFactory? _testFactory;
  String? _testPath;
  Future<Database>? _opening;
  String? _path;

  bool get isOpen => _database?.isOpen ?? false;

  /// Filesystem (or virtual for web) path of the database file.
  String? get path => _path;

  /// Opened connection, throwing a localized [AppException] on failure.
  Future<Database> get database async {
    final existing = _database;
    if (existing != null && existing.isOpen) return existing;
    return open();
  }

  /// Opens the database, reusing an in-flight open operation if present.
  Future<Database> open() {
    final existing = _database;
    if (existing != null && existing.isOpen) return Future.value(existing);

    final inFlight = _opening;
    if (inFlight != null) return inFlight;

    final future = _openInternal();
    _opening = future;
    return future.whenComplete(() => _opening = null);
  }

  Future<Database> _openInternal() async {
    try {
      final factory = _testFactory ?? await DatabaseOpener.resolveFactory();
      if (_testPath != null) {
        _path = _testPath;
      } else {
        final directory = await DatabaseOpener.resolveDirectory();
        _path = p.join(directory, DatabaseOpener.databaseFileName);
      }

      final db = await factory.openDatabase(
        _path!,
        options: OpenDatabaseOptions(
          version: DatabaseSchema.version,
          onConfigure: _onConfigure,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onDowngrade: onDatabaseDowngradeDelete,
        ),
      );
      _database = db;
      return db;
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Failed to open database: $error\n$stackTrace');
      throw AppException(
        AppErrorCode.database,
        cause: error,
        debugDetail: 'open: $error',
      );
    }
  }

  Future<void> _onConfigure(Database db) async {
    // Foreign keys are enforced so master data referenced by quotations or
    // sales records cannot be silently removed.
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    for (final statement in DatabaseSchema.createStatements) {
      batch.execute(statement);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (var version = oldVersion + 1; version <= newVersion; version++) {
      final statements = DatabaseSchema.migrations[version];
      if (statements == null) continue;
      final batch = db.batch();
      for (final statement in statements) {
        batch.execute(statement);
      }
      await batch.commit(noResult: true);
    }
  }

  /// Closes the connection (used by tests and by backup/restore flows).
  Future<void> close() async {
    final db = _database;
    _database = null;
    if (db != null && db.isOpen) {
      await db.close();
    }
  }
}
