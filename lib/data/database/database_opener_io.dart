import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// IO platforms: Android/iOS via sqflite, desktop via the FFI implementation.
Future<DatabaseFactory> resolveFactory() async {
  if (Platform.isAndroid || Platform.isIOS) {
    return sqflite.databaseFactory;
  }
  sqfliteFfiInit();
  return databaseFactoryFfi;
}

/// Directory that stores `sales.db`.
///
/// Mobile uses the platform database directory; desktop uses the application
/// support directory so user data survives application updates.
Future<String> resolveDirectory() async {
  if (Platform.isAndroid || Platform.isIOS) {
    final base = await sqflite.getDatabasesPath();
    await Directory(base).create(recursive: true);
    return base;
  }
  final support = await getApplicationSupportDirectory();
  await support.create(recursive: true);
  return p.normalize(support.path);
}

const bool isPersistenceSupported = true;
