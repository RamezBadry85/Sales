import 'dart:async';

import 'package:sqflite_common/sqlite_api.dart';

import 'database_opener_stub.dart'
    if (dart.library.io) 'database_opener_io.dart' as platform;

/// Resolves the platform specific database factory and storage directory.
///
/// The IO implementation is used on Android, iOS, Windows, Linux and macOS.
/// A stub is compiled for platforms without `dart:io` so the project keeps
/// building everywhere; it reports a clear, localized error at runtime.
class DatabaseOpener {
  const DatabaseOpener._();

  static const String databaseFileName = 'sales.db';

  static Future<DatabaseFactory> resolveFactory() => platform.resolveFactory();

  static Future<String> resolveDirectory() => platform.resolveDirectory();

  /// Declares whether local persistence is available on this platform.
  static bool get isPersistenceSupported => platform.isPersistenceSupported;
}
