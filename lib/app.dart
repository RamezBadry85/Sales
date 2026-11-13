import 'package:flutter/material.dart';

import 'app_state.dart';
import 'core/l10n/app_localizations.dart';
import 'core/theme.dart';
import 'ui/shell/app_shell.dart';

/// Root widget wiring localization, theming and the application shell.
class SalesApp extends StatelessWidget {
  const SalesApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state.settings,
      builder: (context, _) {
        final locale = state.settings.locale;
        return MaterialApp(
          title: 'Sales',
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          theme: AppTheme.light(locale),
          darkTheme: AppTheme.dark(locale),
          themeMode: state.settings.themeMode,
          builder: (context, child) {
            // Force the direction implied by the active language so Arabic is
            // always RTL and English always LTR, independently of the device.
            return Directionality(
              textDirection:
                  locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: AppShell(state: state),
        );
      },
    );
  }
}

/// Fallback UI shown when the application cannot bootstrap at all.
class BootstrapErrorApp extends StatelessWidget {
  const BootstrapErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    const locale = Locale('ar');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      theme: AppTheme.light(locale),
      home: Builder(
        builder: (context) {
          final l10n = context.l10n;
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.storage_outlined,
                      size: 44,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.t('error.database'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$error',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
