import 'package:flutter/material.dart';

/// Central design tokens and theme construction.
class AppTheme {
  const AppTheme._();

  static const Color primary = Color(0xFF0F5C8C);
  static const Color primaryDark = Color(0xFF0A3F63);
  static const Color accent = Color(0xFF2E9E7E);
  static const Color danger = Color(0xFFB3403A);
  static const Color surfaceTint = Color(0xFFF4F6F9);

  /// Fonts that ship with the platform and render Arabic well.
  static const List<String> arabicFontFallback = <String>[
    'Segoe UI',
    'Dubai',
    'Tahoma',
    'Noto Naskh Arabic',
    'Cairo',
    'sans-serif',
  ];

  static ThemeData light(Locale locale) => _build(Brightness.light, locale);

  static ThemeData dark(Locale locale) => _build(Brightness.dark, locale);

  static ThemeData _build(Brightness brightness, Locale locale) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? const Color(0xFF63B3E8) : primary,
      secondary: isDark ? const Color(0xFF66C7A8) : accent,
      error: isDark ? const Color(0xFFF2A6A2) : danger,
      surface: isDark ? const Color(0xFF151B21) : Colors.white,
    );

    final baseTextTheme = ThemeData(brightness: brightness).textTheme;
    final textTheme = baseTextTheme.apply(
      fontFamily: locale.languageCode == 'ar' ? arabicFontFallback.first : null,
      fontFamilyFallback: locale.languageCode == 'ar' ? arabicFontFallback : null,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF0E1317) : const Color(0xFFF6F7FA),
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: isDark ? const Color(0xFF151B21) : Colors.white,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? const Color(0xFF1A2229) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isDark ? const Color(0xFF26313A) : const Color(0xFFE3E7EE),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1A2229) : Colors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: _border(isDark, const Color(0xFFD5DBE5)),
        enabledBorder: _border(isDark, const Color(0xFFD5DBE5)),
        focusedBorder: _border(isDark, scheme.primary, width: 1.6),
        errorBorder: _border(isDark, scheme.error),
        focusedErrorBorder: _border(isDark, scheme.error, width: 1.6),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF26313A) : const Color(0xFFE6EAF0),
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
        ),
        dataTextStyle: textTheme.bodyMedium,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF1A2229) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static OutlineInputBorder _border(
    bool isDark,
    Color color, {
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// Layout breakpoints shared by the shell and the pages.
class AppBreakpoints {
  const AppBreakpoints._();

  /// Width below which the compact (mobile) layout is used.
  static const double compact = 780;

  /// Width at which side-by-side master/detail layouts become comfortable.
  static const double wide = 1150;
}
