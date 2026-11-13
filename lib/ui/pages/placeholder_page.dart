import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../shell/app_shell.dart';
import '../widgets/app_scaffold.dart';

/// Page shown for modules that belong to later development phases.
///
/// Nothing is simulated: no sample quotations or fabricated statistics are
/// displayed, only a clear statement of the planned scope.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    required this.section,
    this.onBackToCustomers,
  });

  final AppSection section;
  final VoidCallback? onBackToCustomers;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (title, description) = _content(section, l10n);

    return PageScaffold(
      title: l10n.t(section.labelKey()),
      subtitle: l10n.t('nav.comingSoon'),
      child: SurfaceCard(
        padding: const EdgeInsets.all(24),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      section.icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(description),
                const SizedBox(height: 18),
                Text(
                  l10n.isArabic
                      ? 'البيانات الأساسية (العملاء والمنتجات) جاهزة الآن، '
                          'وهي المرجع الذي ستستخدمه هذه الوحدات عند تنفيذها.'
                      : 'Master data (customers and products) is ready and will be '
                          'used by this module when it is implemented.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                if (onBackToCustomers != null) ...[
                  const SizedBox(height: 20),
                  FilledButton.tonalIcon(
                    onPressed: onBackToCustomers,
                    icon: const Icon(Icons.groups_outlined),
                    label: Text(l10n.t('nav.customers')),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  (String, String) _content(AppSection section, dynamic l10n) {
    final isArabic = l10n.isArabic as bool;
    switch (section) {
      case AppSection.quotations:
        return (
          l10n.t('nav.quotations') as String,
          isArabic
              ? 'إدخال عروض الأسعار بناءً على ورقة «Target - TME» مع الخصومات '
                  'والإجماليات وحساب نسبة الخصم الإجمالية.'
              : 'Quotation entry based on the “Target - TME” worksheet, with '
                  'per-line discounts, totals and the overall discount percentage.',
        );
      case AppSection.sales:
        return (
          l10n.t('nav.sales') as String,
          isArabic
              ? 'تسجيل المبيعات بناءً على ورقة «Data Sales» مع الفلترة بالعميل '
                  'والمستشفى والمنتج والشركة والمندوب والتاريخ.'
              : 'Sales entry based on the “Data Sales” worksheet with filtering '
                  'by customer, hospital, product, company, representative and date.',
        );
      case AppSection.analysis:
        return (
          l10n.t('nav.analysis') as String,
          isArabic
              ? 'تحليل المبيعات والأسعار مع رسوم تفاعلية، دون أي نتائج '
                  'افتراضية عند غياب البيانات.'
              : 'Sales and price analysis with interactive charts and empty '
                  'states when no data exists.',
        );
      case AppSection.reports:
        return (
          l10n.t('nav.reports') as String,
          isArabic
              ? 'تقارير PDF وExcel ونسخ احتياطي كامل لقاعدة البيانات.'
              : 'PDF and Excel reports plus full database backup and restore.',
        );
      default:
        return (
          l10n.t(section.labelKey()) as String,
          l10n.t('nav.comingSoon') as String,
        );
    }
  }
}
