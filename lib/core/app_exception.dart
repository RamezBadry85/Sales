/// Application level exception types.
///
/// Every failure that can reach the user interface is expressed through
/// [AppException] so that the presentation layer can translate it into a
/// localized message without leaking database or platform details.
library;

/// Stable identifiers for user facing error conditions.
///
/// The value name is also used as a localization key suffix
/// (for example `error.database`), which keeps messages centralized.
enum AppErrorCode {
  unknown,
  database,
  notFound,
  inUse,
  required,
  invalidEmail,
  invalidNumber,
}

/// Exception carrying a translatable error code and an optional field name.
class AppException implements Exception {
  AppException(
    this.code, {
    this.field,
    this.cause,
    this.debugDetail,
  });

  final AppErrorCode code;

  /// Name of the form field that produced the error, when applicable.
  final String? field;

  /// Original exception, kept for diagnostics/logging.
  final Object? cause;

  /// Technical detail that is never shown to end users.
  final String? debugDetail;

  @override
  String toString() {
    final buffer = StringBuffer('AppException($code');
    if (field != null) buffer.write(', field: $field');
    if (debugDetail != null) buffer.write(', detail: $debugDetail');
    buffer.write(')');
    return buffer.toString();
  }
}
