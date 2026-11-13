import 'package:flutter/material.dart';

import 'app.dart';
import 'app_state.dart';

/// Application entry point.
///
/// Bootstrap failures (for example an unreadable database file) are rendered
/// instead of swallowed so the user never works against an in-memory store
/// believing the data will be saved.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final state = await AppState.bootstrap();
    runApp(SalesApp(state: state));
  } catch (error) {
    runApp(BootstrapErrorApp(error: error));
  }
}
