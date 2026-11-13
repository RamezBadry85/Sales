import 'package:flutter/material.dart';

import '../data/database/database_opener.dart';
import 'app_exception.dart';
import 'l10n/app_localizations.dart';

/// Converts exceptions into localized, user friendly messages.
String describeError(BuildContext context, Object error) {
  final l10n = context.l10n;
  if (error is AppException) {
    return switch (error.code) {
      // When the platform cannot host the local database at all, explain
      // that explicitly instead of a generic database error.
      AppErrorCode.database => DatabaseOpener.isPersistenceSupported
          ? l10n.t('error.database')
          : persistenceUnavailableMessage(context),
      AppErrorCode.notFound => l10n.t('error.notFound'),
      AppErrorCode.inUse => l10n.t('error.inUse'),
      AppErrorCode.required => l10n.t('error.required'),
      AppErrorCode.invalidEmail => l10n.t('error.invalidEmail'),
      AppErrorCode.invalidNumber => l10n.t('error.invalidNumber'),
      AppErrorCode.unknown => l10n.t('error.unknown'),
    };
  }
  return l10n.t('error.unknown');
}

/// Message shown when local persistence is not available for this platform.
String persistenceUnavailableMessage(BuildContext context) {
  final l10n = context.l10n;
  if (DatabaseOpener.isPersistenceSupported) {
    return l10n.t('error.database');
  }
  return l10n.isArabic
      ? 'حفظ البيانات المحلي غير متاح على هذه المنصة. يُنصح باستخدام إصدار '
          'Android أو Windows للحصول على قاعدة البيانات الدائمة.'
      : 'Local data storage is not available on this platform. Use the Android '
          'or Windows build for persistent storage.';
}
