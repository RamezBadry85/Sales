import 'package:flutter/foundation.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../core/app_exception.dart';

/// Wraps a database call so raw driver errors never reach the UI layer.
Future<T> guardDatabase<T>(
  Future<T> Function() action, {
  String? operation,
}) async {
  try {
    return await action();
  } on AppException {
    rethrow;
  } on DatabaseException catch (error, stackTrace) {
    debugPrint('Database error during ${operation ?? 'operation'}: $error\n$stackTrace');
    throw AppException(
      AppErrorCode.database,
      cause: error,
      debugDetail: '${operation ?? 'operation'}: $error',
    );
  } catch (error, stackTrace) {
    debugPrint('Unexpected error during ${operation ?? 'operation'}: $error\n$stackTrace');
    throw AppException(
      AppErrorCode.unknown,
      cause: error,
      debugDetail: '${operation ?? 'operation'}: $error',
    );
  }
}

/// Escape character used in `LIKE` clauses (matches [likePattern]).
///
/// A visible ASCII character is used instead of a backslash so the generated
/// SQL stays readable in logs.
const String likeEscape = '!';

/// Escapes a value for a SQL `LIKE` pattern and adds wildcards.
String likePattern(String raw) {
  final escaped = raw
      .replaceAll(likeEscape, '$likeEscape$likeEscape')
      .replaceAll('%', '$likeEscape%')
      .replaceAll('_', '${likeEscape}_');
  return '%$escaped%';
}

/// Builds a parenthesized `column LIKE ? ESCAPE '<char>'` clause for the
/// given columns. One bound parameter is expected per column.
String likeClause(List<String> columns) {
  final quotedEscape = "'$likeEscape'";
  final parts = columns
      .map((column) => '$column LIKE ? ESCAPE $quotedEscape')
      .join(' OR ');
  return '($parts)';
}

/// Replaces an empty/blank string with `null` for storage.
String? nullableText(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Current UTC timestamp in the canonical storage format.
String nowIso8601() => DateTime.now().toUtc().toIso8601String();
