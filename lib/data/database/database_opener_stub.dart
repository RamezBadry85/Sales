import 'package:sqflite_common/sqlite_api.dart';

import '../../core/app_exception.dart';

/// Non-IO platforms (for example the web build).
///
/// SQLite needs `sqflite_common_ffi_web` SQLite WASM assets, which are not
/// bundled by default. Instead of silently pretending that data is saved, the
/// application surfaces a clear error so users do not lose work.
Future<DatabaseFactory> resolveFactory() async {
  throw AppException(
    AppErrorCode.database,
    debugDetail: 'SQLite persistence is not available on this platform',
  );
}

Future<String> resolveDirectory() async {
  throw AppException(
    AppErrorCode.database,
    debugDetail: 'SQLite persistence is not available on this platform',
  );
}

const bool isPersistenceSupported = false;
