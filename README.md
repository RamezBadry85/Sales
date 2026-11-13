# Sales — تطبيق إدارة المبيعات / Sales Management

تطبيق Flutter لإدارة المبيعات يحوّل سير العمل القائم على ملف Excel إلى تطبيق
سطح مكتبي/جوال، مع الحفاظ على منطق الحسابات الأصلي، وواجهة عربية أولاً بدعم
كامل لاتجاه RTL وتبديل إلى الإنجليزية LTR.

A Flutter sales-management application that replaces the Excel based workflow
while preserving its calculations. Arabic-first interface with full RTL
support and an English LTR alternative.

---

## الحالة الحالية / Current status

| المرحلة | الوصف | الحالة |
| --- | --- | --- |
| Phase 1 | هيكل المشروع، التصميم، الترجمة، RTL | ✅ مكتمل |
| **Phase 2** | **قاعدة بيانات SQLite + إدارة العملاء والمنتجات** | ✅ **مكتمل** |
| Phase 3 | عروض الأسعار (ورقة `Target - TME`) | ⏳ التالي |
| Phase 4 | بيانات المبيعات (ورقة `Data Sales`) | ⏳ مخطط له |
| Phase 5 | تحليل المبيعات والأسعار | ⏳ مخطط له |
| Phase 6 | التقارير (PDF/Excel) والنسخ الاحتياطي | ⏳ مخطط له |

عند تنفيذ المراحل اللاحقة لا تُعرض أي إحصاءات أو بيانات تجريبية وهمية؛
الأقسام غير المنفذة تعرض حالة فارغة صريحة.

## ما تم تنفيذه في هذه المرحلة / What Phase 2 delivers

### قاعدة البيانات المحلية (SQLite)
- مخطط مُصدَّر بإصدار (`DatabaseSchema.version = 1`) مع ترحيلات صريحة
  (`DatabaseSchema.migrations`) و`onUpgrade` تدريجي — لا حذف للبيانات عند الترقية.
- `PRAGMA foreign_keys = ON` لضمان سلامة المراجع.
- فتح القاعدة حسب المنصة: `sqflite` على Android/iOS و`sqflite_common_ffi`
  على Windows/Linux/macOS.
- جداول المراحل اللاحقة (`quotations`, `quotation_items`, `sales_records`)
  مُنشأة مسبقاً بمفاتيح أجنبية، لذا لن تحتاج ترحيلاً هدّاماً لاحقاً.
- أخطاء قاعدة البيانات تُترجم إلى `AppException` مع رسائل محلية، دون كشف
  تفاصيل تقنية للمستخدم.

### إدارة العملاء (CRUD كامل)
- إضافة / تعديل / حذف (مع تأكيد) / بحث / ترتيب.
- الحقول: اسم العميل، اسم الحساب، الشخص المسؤول، الهاتف، البريد، العنوان، ملاحظات.
- البحث يعمل بالاسم/الحساب/المسؤول/الهاتف/البريد/العنوان، ويتعامل مع `%` و`_`
  كحروف عادية (تشفير `LIKE`).
- الحذف ممنوع إذا كان العميل مرتبطاً بعرض سعر أو سجل مبيعات (رسالة واضحة).
- تحقق: الاسم مطلوب، البريد الإلكتروني يُتحقق من صحته.

### إدارة المنتجات (CRUD كامل)
- الحقول: الفئة، الشركة/المصنّع، كود المنتج، وصف المنتج، الوحدة، السعر
  الافتراضي، ملاحظات.
- **قاعدة العمل**: كود المنتج **ليس** معرّفاً فريداً. المعرّف هو `id`،
  ويُسمح بتكرار الأكواد مع الحفاظ على كل الأوصاف (مُختبَر صريحاً).
- فلترة بالفئة والشركة (قوائم مستمدة من البيانات الفعلية) + بحث + ترتيب
  (الوصف، الكود، السعر، الأحدث).

### الأرقام والعمليات الحسابية
- لا تُستخدم أبداً أرقام الفاصلة العائمة للأموال: `package:decimal` في الذاكرة
  ونصوص عشرية مُعيّرة في SQLite (`DecimalFormat.toStorage`).
- تنسيق آمن: فواصل آلاف، تقريب نصف-إلى-أعلى على النص، دعم الأرقام العربية
  والفارسية والفواصل العربية (٫ ،).
- `DecimalTextField` يقبل الأرقام العربية والفارسية والفواصل العربية.

### الواجهة
- عربية أولاً + RTL، تبديل فوري للإنجليزية LTR مع حفظ التفضيل.
- سطح مكتب: شريط جانبي + جدول + لوحة تفاصيل. الجوال: شريط سفلي + Drawer
  + بطاقات.
- وضع ليلي/نهاري/حسب النظام.
- حالات فارغة / تحميل / خطأ برسائل واضحة، ورسائل تحقق عربية.

## البنية / Architecture

```
lib/
├── main.dart                     نقطة الدخول
├── app.dart                      MaterialApp، الترجمة، الاتجاه، الثيم
├── app_state.dart                جذر التكوين (Settings + DB + Stores)
├── core/
│   ├── app_exception.dart        أكواد الأخطاء القابلة للترجمة
│   ├── decimal_format.dart       تحليل/تنسيق/tخزين عشري آمن
│   ├── error_messages.dart       تحويل الاستثناءات إلى رسائل محلية
│   ├── settings_controller.dart  اللغة والثيم (SharedPreferences)
│   ├── theme.dart                رموز التصميم والثيمات
│   └── l10n/app_localizations.dart  الترجمة (ar/en) + Delegate
├── data/
│   ├── database/                 AppDatabase, DatabaseSchema, DatabaseOpener
│   ├── models/                   Customer, Product
│   └── repositories/             CustomerRepository, ProductRepository,
│                                 CustomerStore/ProductStore (عقود)
└── ui/
    ├── shell/app_shell.dart      التنقل المتجاوب
    ├── pages/                    dashboard, customers, products, settings
    ├── customers/ products/       حوارات الإضافة/التعديل
    ├── controllers/              حالة القوائم
    └── widgets/                  مكونات مشتركة وحقول النماذج
```

قاعدة الاعتماد: الواجهة تعتمد على `CustomerStore`/`ProductStore`، والتنفيذ
الحقيقي `SqliteCustomerStore`/`SqliteProductStore` يغلّف المستودعات. يسمح ذلك
باختبار الواجهة بمخازن في الذاكرة، وبتوسيع المشروع لاحقاً.

## التشغيل / Getting started

```bash
flutter pub get
flutter run -d windows     # أو: chrome / android
```

### البناء / Building

```bash
flutter build apk --release      # Android
flutter build web --release      # Web (انظر الملاحظة أدناه)
flutter build windows --release  # Windows (يتطلب Windows + Visual Studio)
```

> **ملاحظة Web**: قاعدة البيانات المحلية تحتاج أصول SQLite WASM
> (`sqflite_common_ffi_web`). إذا لم تكن الأصول مضمنة، يعرض التطبيق رسالة
> صريحة بأن الحفظ المحلي غير متاح على هذه المنصة بدلاً من فقدان البيانات.

## الاختبارات / Tests

```bash
flutter analyze   # No issues found!
flutter test      # 104 tests, all passed
```

التغطية:
- `test/decimal_format_test.dart`: التحليل (عربي/فارسي/فواصل)، التنسيق،
  التقريب، والتخزين الذري دون فقدان دقة.
- `test/customer_repository_test.dart`: CRUD، البحث، الترتيب، الحذف المحظور،
  الاستمرارية بعد إعادة فتح ملف قاعدة البيانات.
- `test/product_repository_test.dart`: كل الحقول، **تكرار الأكواد**، الفلترة،
  القيم المميزة، الترتيب، منع حذف منتج مستخدم.
- `test/database_schema_test.dart`: إصدار المخطط، وجود كل الجداول والفهارس،
  تفعيل المفاتيح الأجنبية، الحذف المتتالي لبنود عرض السعر، منع حذف عميل مرتبط،
  وتخزين المبالغ كنصوص.
- `test/ui/sales_app_test.dart`: RTL/LTR، التنقل المتجاوب، إنشاء عميل/منتج من
  النموذج، رسائل التحقق، تأكيد الحذف، البحث، وحالات فارغة بلا بيانات وهمية.

### نتائج البناء / Build results

تم البناء فعلياً عبر GitHub Actions (`Build` workflow) على `ubuntu-latest` و
`windows-latest`:

| المنصة | الأمر | النتيجة | حجم المخرج |
| --- | --- | --- | --- |
| Android | `flutter build apk --release` | ✅ نجح | ~27 MB |
| Web | `flutter build web --release` | ✅ نجح | ~14 MB |
| Windows | `flutter build windows --release` | ✅ نجح | ~13 MB |

## قاعدة العمل المحفوظة من الملف الأصلي

- مجموع السطر قبل الخصم = الكمية × سعر الوحدة.
- قيمة الخصم للوحدة = سعر الوحدة × نسبة الخصم.
- السعر بعد الخصم = سعر الوحدة − قيمة الخصم للوحدة.
- مجموع السطر بعد الخصم = الكمية × السعر بعد الخصم.
- إجمالي الخصم = الإجمالي قبل الخصم − الإجمالي بعد الخصم.
- نسبة الخصم الإجمالية = إجمالي الخصم ÷ الإجمالي قبل الخصم × 100 (مع حماية
  من القسمة على صفر).

هذه القواعد ستُستخدم حرفياً في المرحلة الثالثة، وتُخزَّن مبالغها كنصوص عشرية.

## المساهمة / Continuous integration

`.github/workflows/ci.yml` يشغّل `flutter analyze` و`flutter test`،
و`.github/workflows/build.yml` ينشئ حزمة APK ونسخة الويب كتحقق فعلي من البناء.
