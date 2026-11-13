import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Localization delegate for the application.
///
/// Translations are kept in code (instead of generated ARB files) so that the
/// project builds without code generation steps and stays easy to audit.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('ar'));
  }

  bool get isArabic => locale.languageCode == 'ar';

  String get languageCode => locale.languageCode;

  /// Directionality implied by the language.
  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  String t(String key) {
    final table = isArabic ? _ar : _en;
    final value = table[key];
    if (value != null) return value;
    // Fallback to English, then to the key itself so missing translations are
    // visible during development instead of crashing.
    return _en[key] ?? key;
  }

  /// Translation with simple positional placeholders ({0}, {1}, ...).
  String tp(String key, List<Object?> args) {
    var text = t(key);
    for (var i = 0; i < args.length; i++) {
      text = text.replaceAll('{$i}', '${args[i]}');
    }
    return text;
  }

  /// All translation keys, exposed for parity tests and tooling.
  @visibleForTesting
  static Set<String> get englishKeys => _en.keys.toSet();

  @visibleForTesting
  static Set<String> get arabicKeys => _ar.keys.toSet();

  static const Map<String, String> _en = {
    'app.title': 'Sales',
    'app.tagline': 'Sales management',
    'common.save': 'Save',
    'common.cancel': 'Cancel',
    'common.delete': 'Delete',
    'common.edit': 'Edit',
    'common.add': 'Add',
    'common.close': 'Close',
    'common.search': 'Search',
    'common.clear': 'Clear',
    'common.confirm': 'Confirm',
    'common.retry': 'Retry',
    'common.loading': 'Loading…',
    'common.noData': 'No data available',
    'common.noResults': 'No results match your search',
    'common.optional': 'optional',
    'common.required': 'required',
    'common.yes': 'Yes',
    'common.no': 'No',
    'common.actions': 'Actions',
    'common.details': 'Details',
    'common.name': 'Name',
    'common.notes': 'Notes',
    'common.phone': 'Phone',
    'common.email': 'Email',
    'common.address': 'Address',
    'common.total': 'Total',
    'common.all': 'All',
    'common.results': '{0} results',
    'common.showing': 'Showing {0} of {1}',
    'common.sortBy': 'Sort by',
    'common.refresh': 'Refresh',
    'common.unexpectedError': 'Something went wrong. Please try again.',
    'error.database': 'A database error occurred. Please try again.',
    'error.notFound': 'The requested record no longer exists.',
    'error.inUse': 'This record is used by other data and cannot be deleted.',
    'error.required': 'This field is required.',
    'error.invalidEmail': 'Enter a valid email address.',
    'error.invalidNumber': 'Enter a valid number.',
    'error.unknown': 'An unexpected error occurred.',
    'error.deleteFailed': 'Could not delete the record.',
    'error.saveFailed': 'Could not save the record.',
    'error.loadFailed': 'Could not load data.',
    'error.nameExists': 'A record with this name already exists.',
    'lang.arabic': 'العربية',
    'lang.english': 'English',
    'lang.switch': 'Language',
    'nav.dashboard': 'Dashboard',
    'nav.customers': 'Customers',
    'nav.products': 'Products',
    'nav.quotations': 'Quotations',
    'nav.sales': 'Sales',
    'nav.analysis': 'Analysis',
    'nav.reports': 'Reports',
    'nav.settings': 'Settings',
    'nav.masterData': 'Master data',
    'nav.comingSoon': 'This module arrives in a later phase.',
    'dashboard.title': 'Dashboard',
    'dashboard.welcome': 'Welcome',
    'dashboard.customers': 'Customers',
    'dashboard.products': 'Products',
    'dashboard.quotations': 'Quotations',
    'dashboard.sales': 'Sales records',
    'dashboard.emptyHint':
        'The database is empty. Start by adding customers and products.',
    'dashboard.quickActions': 'Quick actions',
    'dashboard.addCustomer': 'Add customer',
    'dashboard.addProduct': 'Add product',
    'customer.title': 'Customers',
    'customer.plural': 'customers',
    'customer.singular': 'customer',
    'customer.add': 'Add customer',
    'customer.edit': 'Edit customer',
    'customer.delete': 'Delete customer',
    'customer.deleteTitle': 'Delete customer?',
    'customer.deleteMessage':
        '“{0}” will be permanently deleted. This action cannot be undone.',
    'customer.deleted': 'Customer deleted.',
    'customer.saved': 'Customer saved.',
    'customer.name': 'Customer name',
    'customer.accountName': 'Account name',
    'customer.contactPerson': 'Contact person',
    'customer.phone': 'Phone number',
    'customer.email': 'Email',
    'customer.address': 'Address',
    'customer.notes': 'Notes',
    'customer.empty': 'No customers yet',
    'customer.emptyHint': 'Add your first customer to start building quotations.',
    'customer.searchHint': 'Search by name, account, contact or phone',
    'customer.info': 'Customer information',
    'customer.sortName': 'Name (A–Z)',
    'customer.sortNewest': 'Newest first',
    'customer.sortOldest': 'Oldest first',
    'product.title': 'Products',
    'product.plural': 'products',
    'product.singular': 'product',
    'product.add': 'Add product',
    'product.edit': 'Edit product',
    'product.delete': 'Delete product',
    'product.deleteTitle': 'Delete product?',
    'product.deleteMessage':
        '“{0}” will be permanently deleted. This action cannot be undone.',
    'product.deleted': 'Product deleted.',
    'product.saved': 'Product saved.',
    'product.category': 'Category',
    'product.company': 'Company / manufacturer',
    'product.code': 'Product code',
    'product.description': 'Product description',
    'product.unit': 'Unit',
    'product.price': 'Default price',
    'product.notes': 'Notes',
    'product.empty': 'No products yet',
    'product.emptyHint': 'Add your first product to start building quotations.',
    'product.searchHint': 'Search by code, description, company or category',
    'product.info': 'Product information',
    'product.pricing': 'Pricing',
    'product.codeHint':
        'Codes are not unique. Several products may share the same code.',
    'product.filterCategory': 'Category',
    'product.filterCompany': 'Company',
    'product.sortNewest': 'Newest first',
    'product.sortCode': 'Code (A–Z)',
    'product.sortDescription': 'Description (A–Z)',
    'product.sortPrice': 'Price (low to high)',
    'settings.title': 'Settings',
    'settings.appearance': 'Appearance',
    'settings.language': 'Language',
    'settings.languageHint': 'The interface switches language and direction immediately.',
    'settings.data': 'Data',
    'settings.database': 'Database',
    'settings.databasePath': 'Local database',
    'settings.version': 'Application version',
    'settings.about': 'About',
    'settings.aboutText':
        'A local-first sales application that preserves the calculations of the original Excel workbook.',
    'settings.darkMode': 'Dark mode',
    'settings.lightMode': 'Light mode',
    'settings.systemMode': 'Follow system',
    'settings.storage': 'Local storage',
    'settings.storageLocal': 'Stored on this device',
    'settings.storageUnavailable': 'Not available on this platform',
    'validation.nameRequired': 'Enter a name.',
    'validation.tooLong': 'The value is too long.',
    'validation.priceInvalid': 'Enter a valid price (zero or greater).',
    'validation.phoneInvalid': 'Enter a valid phone number.',
  };

  static const Map<String, String> _ar = {
    'app.title': 'المبيعات',
    'app.tagline': 'إدارة المبيعات',
    'common.save': 'حفظ',
    'common.cancel': 'إلغاء',
    'common.delete': 'حذف',
    'common.edit': 'تعديل',
    'common.add': 'إضافة',
    'common.close': 'إغلاق',
    'common.search': 'بحث',
    'common.clear': 'مسح',
    'common.confirm': 'تأكيد',
    'common.retry': 'إعادة المحاولة',
    'common.loading': 'جارٍ التحميل…',
    'common.noData': 'لا توجد بيانات',
    'common.noResults': 'لا توجد نتائج مطابقة للبحث',
    'common.optional': 'اختياري',
    'common.required': 'مطلوب',
    'common.yes': 'نعم',
    'common.no': 'لا',
    'common.actions': 'إجراءات',
    'common.details': 'التفاصيل',
    'common.name': 'الاسم',
    'common.notes': 'ملاحظات',
    'common.phone': 'الهاتف',
    'common.email': 'البريد الإلكتروني',
    'common.address': 'العنوان',
    'common.total': 'الإجمالي',
    'common.all': 'الكل',
    'common.results': '{0} نتيجة',
    'common.showing': 'عرض {0} من {1}',
    'common.sortBy': 'الترتيب حسب',
    'common.refresh': 'تحديث',
    'common.unexpectedError': 'حدث خطأ غير متوقع. حاول مرة أخرى.',
    'error.database': 'حدث خطأ في قاعدة البيانات. حاول مرة أخرى.',
    'error.notFound': 'السجل المطلوب لم يعد موجوداً.',
    'error.inUse': 'هذا السجل مستخدم في بيانات أخرى ولا يمكن حذفه.',
    'error.required': 'هذا الحقل مطلوب.',
    'error.invalidEmail': 'أدخل بريداً إلكترونياً صحيحاً.',
    'error.invalidNumber': 'أدخل رقماً صحيحاً.',
    'error.unknown': 'حدث خطأ غير متوقع.',
    'error.deleteFailed': 'تعذر حذف السجل.',
    'error.saveFailed': 'تعذر حفظ السجل.',
    'error.loadFailed': 'تعذر تحميل البيانات.',
    'error.nameExists': 'يوجد سجل بنفس الاسم بالفعل.',
    'lang.arabic': 'العربية',
    'lang.english': 'English',
    'lang.switch': 'اللغة',
    'nav.dashboard': 'لوحة التحكم',
    'nav.customers': 'العملاء',
    'nav.products': 'المنتجات',
    'nav.quotations': 'عروض الأسعار',
    'nav.sales': 'المبيعات',
    'nav.analysis': 'التحليل',
    'nav.reports': 'التقارير',
    'nav.settings': 'الإعدادات',
    'nav.masterData': 'البيانات الأساسية',
    'nav.comingSoon': 'هذا القسم سيتم إضافته في مرحلة لاحقة.',
    'dashboard.title': 'لوحة التحكم',
    'dashboard.welcome': 'مرحباً',
    'dashboard.customers': 'العملاء',
    'dashboard.products': 'المنتجات',
    'dashboard.quotations': 'عروض الأسعار',
    'dashboard.sales': 'سجلات المبيعات',
    'dashboard.emptyHint':
        'قاعدة البيانات فارغة. ابدأ بإضافة العملاء والمنتجات.',
    'dashboard.quickActions': 'إجراءات سريعة',
    'dashboard.addCustomer': 'إضافة عميل',
    'dashboard.addProduct': 'إضافة منتج',
    'customer.title': 'العملاء',
    'customer.plural': 'عميل',
    'customer.singular': 'عميل',
    'customer.add': 'إضافة عميل',
    'customer.edit': 'تعديل بيانات العميل',
    'customer.delete': 'حذف العميل',
    'customer.deleteTitle': 'حذف العميل؟',
    'customer.deleteMessage':
        'سيتم حذف «{0}» نهائياً. لا يمكن التراجع عن هذا الإجراء.',
    'customer.deleted': 'تم حذف العميل.',
    'customer.saved': 'تم حفظ بيانات العميل.',
    'customer.name': 'اسم العميل',
    'customer.accountName': 'اسم الحساب',
    'customer.contactPerson': 'الشخص المسؤول',
    'customer.phone': 'رقم الهاتف',
    'customer.email': 'البريد الإلكتروني',
    'customer.address': 'العنوان',
    'customer.notes': 'ملاحظات',
    'customer.empty': 'لا يوجد عملاء بعد',
    'customer.emptyHint': 'أضف أول عميل للبدء في إنشاء عروض الأسعار.',
    'customer.searchHint': 'ابحث بالاسم أو الحساب أو المسؤول أو الهاتف',
    'customer.info': 'بيانات العميل',
    'customer.sortName': 'الاسم (أ–ي)',
    'customer.sortNewest': 'الأحدث أولاً',
    'customer.sortOldest': 'الأقدم أولاً',
    'product.title': 'المنتجات',
    'product.plural': 'منتج',
    'product.singular': 'منتج',
    'product.add': 'إضافة منتج',
    'product.edit': 'تعديل بيانات المنتج',
    'product.delete': 'حذف المنتج',
    'product.deleteTitle': 'حذف المنتج؟',
    'product.deleteMessage':
        'سيتم حذف «{0}» نهائياً. لا يمكن التراجع عن هذا الإجراء.',
    'product.deleted': 'تم حذف المنتج.',
    'product.saved': 'تم حفظ بيانات المنتج.',
    'product.category': 'الفئة',
    'product.company': 'الشركة / المُصنّع',
    'product.code': 'كود المنتج',
    'product.description': 'وصف المنتج',
    'product.unit': 'الوحدة',
    'product.price': 'السعر الافتراضي',
    'product.notes': 'ملاحظات',
    'product.empty': 'لا توجد منتجات بعد',
    'product.emptyHint': 'أضف أول منتج للبدء في إنشاء عروض الأسعار.',
    'product.searchHint': 'ابحث بالكود أو الوصف أو الشركة أو الفئة',
    'product.info': 'بيانات المنتج',
    'product.pricing': 'التسعير',
    'product.codeHint': 'الكود ليس معرّفاً فريداً، فقد تشترك عدة منتجات في الكود نفسه.',
    'product.filterCategory': 'الفئة',
    'product.filterCompany': 'الشركة',
    'product.sortNewest': 'الأحدث أولاً',
    'product.sortCode': 'الكود (أ–ي)',
    'product.sortDescription': 'الوصف (أ–ي)',
    'product.sortPrice': 'السعر (من الأقل)',
    'settings.title': 'الإعدادات',
    'settings.appearance': 'المظهر',
    'settings.language': 'اللغة',
    'settings.languageHint': 'يتم تغيير اللغة واتجاه الواجهة فوراً.',
    'settings.data': 'البيانات',
    'settings.database': 'قاعدة البيانات',
    'settings.databasePath': 'قاعدة البيانات المحلية',
    'settings.version': 'إصدار التطبيق',
    'settings.about': 'حول التطبيق',
    'settings.aboutText':
        'تطبيق مبيعات يعمل محلياً ويحافظ على حسابات ملف الإكسل الأصلي.',
    'settings.darkMode': 'الوضع الليلي',
    'settings.lightMode': 'الوضع النهاري',
    'settings.systemMode': 'حسب النظام',
    'settings.storage': 'التخزين المحلي',
    'settings.storageLocal': 'محفوظة على هذا الجهاز',
    'settings.storageUnavailable': 'غير متاح على هذه المنصة',
    'validation.nameRequired': 'أدخل الاسم.',
    'validation.tooLong': 'القيمة طويلة جداً.',
    'validation.priceInvalid': 'أدخل سعراً صحيحاً (صفر أو أكثر).',
    'validation.phoneInvalid': 'أدخل رقم هاتف صحيحاً.',
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any(
        (l) => l.languageCode == locale.languageCode,
      );

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Convenience extension used throughout the UI layer.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
