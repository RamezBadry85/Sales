import 'package:sqflite_common/sqlite_api.dart';

import '../../core/app_exception.dart';

/// Non-IO platforms (the web build).
///
/// SQLite on the web requires the `sqflite_common_ffi_web` WebAssembly assets.
/// They are not bundled by default, so instead of pretending that data is
/// saved (and letting the user lose work), the application surfaces a clear,
/// localized error that the UI renders as an explanatory screen.
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
