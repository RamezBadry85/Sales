import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'app_state.dart';
import 'data/database/database_web.dart';

/// Application entry point.
///
/// Bootstrap failures (for example an unreadable database file) are rendered
/// instead of swallowed so the user never works against an in-memory store
/// believing the data will be saved.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // The web build uses SQLite compiled to WebAssembly; its assets are
    // configured once, before any database call.
    await configureWebDatabase();
  }

  try {
    final state = await AppState.bootstrap();
    runApp(SalesApp(state: state));
  } catch (error) {
    runApp(BootstrapErrorApp(error: error));
  }
}
