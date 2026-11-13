import 'package:flutter/foundation.dart';

/// Web-only database bootstrap.
///
/// The SQLite WebAssembly build needs its worker and wasm assets to be located
/// relatively to the deployed application. Because the project does not ship
/// those assets by default (they add ~1.5 MB to the web bundle), this function
/// is intentionally a no-op: the browser build reports a clear message when the
/// user tries to store data instead of silently losing it.
///
/// To enable web persistence:
/// 1. `dart run sqflite_common_ffi_web:setup`
/// 2. add `sqflite_common_ffi_web` to `pubspec.yaml` dependencies
/// 3. call `databaseFactoryFfiWeb` here to configure the factory.
Future<void> configureWebDatabase() async {
  if (kDebugMode) {
    debugPrint(
      'Web build: local SQLite persistence is not enabled. '
      'Run `dart run sqflite_common_ffi_web:setup` to bundle the wasm assets.',
    );
  }
}
