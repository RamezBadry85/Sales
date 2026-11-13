import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme.dart';
import '../pages/customers_page.dart';
import '../pages/dashboard_page.dart';
import '../pages/products_page.dart';
import '../pages/settings_page.dart';
import '../pages/placeholder_page.dart';

/// Navigation destinations of the application shell.
enum AppSection {
  dashboard,
  customers,
  products,
  quotations,
  sales,
  analysis,
  reports,
  settings;

  String labelKey() => switch (this) {
        AppSection.dashboard => 'nav.dashboard',
        AppSection.customers => 'nav.customers',
        AppSection.products => 'nav.products',
        AppSection.quotations => 'nav.quotations',
        AppSection.sales => 'nav.sales',
        AppSection.analysis => 'nav.analysis',
        AppSection.reports => 'nav.reports',
        AppSection.settings => 'nav.settings',
      };

  IconData get icon => switch (this) {
        AppSection.dashboard => Icons.dashboard_outlined,
        AppSection.customers => Icons.groups_outlined,
        AppSection.products => Icons.inventory_2_outlined,
        AppSection.quotations => Icons.request_quote_outlined,
        AppSection.sales => Icons.point_of_sale_outlined,
        AppSection.analysis => Icons.insights_outlined,
        AppSection.reports => Icons.description_outlined,
        AppSection.settings => Icons.settings_outlined,
      };

  /// Sections implemented in the current development phase.
  bool get isAvailable => switch (this) {
        AppSection.dashboard ||
        AppSection.customers ||
        AppSection.products ||
        AppSection.settings =>
          true,
        _ => false,
      };
}

/// Adaptive application shell: sidebar on desktop, drawer + bottom bar on
/// phones, with full RTL support.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.state});

  final AppState state;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppSection _section = AppSection.dashboard;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _select(AppSection section) {
    setState(() => _section = section);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < AppBreakpoints.compact;
    final isWide = width >= AppBreakpoints.wide;
    final l10n = context.l10n;

    final primarySections = <AppSection>[
      AppSection.dashboard,
      AppSection.customers,
      AppSection.products,
      AppSection.quotations,
      AppSection.sales,
    ];

    final body = _buildBody(context);

    if (isCompact) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            tooltip: l10n.t('nav.dashboard'),
          ),
          title: Text(l10n.t(_section.labelKey())),
          actions: [
            _LanguageButton(state: widget.state),
          ],
        ),
        drawer: Drawer(
          child: SafeArea(
            child: _Sidebar(
              sections: AppSection.values,
              selected: _section,
              onSelect: _select,
              state: widget.state,
              showHeader: true,
            ),
          ),
        ),
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: primarySections.indexOf(_section).clamp(0, primarySections.length - 1),
          onDestinationSelected: (index) => _select(primarySections[index]),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (final section in primarySections)
              NavigationDestination(
                icon: Icon(section.icon),
                label: l10n.t(section.labelKey()),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        textDirection: Directionality.of(context),
        children: [
          SizedBox(
            width: isWide ? 256 : 216,
            child: _Sidebar(
              sections: AppSection.values,
              selected: _section,
              onSelect: _select,
              state: widget.state,
              showHeader: isWide,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                _DesktopTopBar(
                  title: l10n.t(_section.labelKey()),
                  state: widget.state,
                ),
                const Divider(height: 1),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_section) {
      case AppSection.dashboard:
        return DashboardPage(state: widget.state, onNavigate: _select);
      case AppSection.customers:
        return CustomersPage(state: widget.state);
      case AppSection.products:
        return ProductsPage(state: widget.state);
      case AppSection.settings:
        return SettingsPage(state: widget.state);
      case AppSection.quotations:
      case AppSection.sales:
      case AppSection.analysis:
      case AppSection.reports:
        return PlaceholderPage(
          section: _section,
          onBackToCustomers: () => _select(AppSection.customers),
        );
    }
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.sections,
    required this.selected,
    required this.onSelect,
    required this.state,
    required this.showHeader,
  });

  final List<AppSection> sections;
  final AppSection selected;
  final ValueChanged<AppSection> onSelect;
  final AppState state;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final masterSections = <AppSection>[
      AppSection.dashboard,
      AppSection.customers,
      AppSection.products,
    ];
    final operationSections = <AppSection>[
      AppSection.quotations,
      AppSection.sales,
      AppSection.analysis,
      AppSection.reports,
    ];

    return Container(
      color: isDark ? const Color(0xFF111820) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.assessment_outlined,
                      color: theme.colorScheme.onPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.t('app.title'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          l10n.t('app.tagline'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (!showHeader) const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              children: [
                _sectionLabel(context, l10n.t('nav.masterData')),
                for (final section in masterSections)
                  _SidebarTile(
                    section: section,
                    selected: selected == section,
                    onTap: () => onSelect(section),
                  ),
                const SizedBox(height: 8),
                _sectionLabel(context, l10n.t('nav.analysis')),
                for (final section in operationSections)
                  _SidebarTile(
                    section: section,
                    selected: selected == section,
                    onTap: () => onSelect(section),
                  ),
                const SizedBox(height: 8),
                _sectionLabel(context, l10n.t('settings.title')),
                _SidebarTile(
                  section: AppSection.settings,
                  selected: selected == AppSection.settings,
                  onTap: () => onSelect(AppSection.settings),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(10),
            child: _LanguageButton(state: state, expanded: true),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final AppSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final available = section.isAvailable;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  section.icon,
                  size: 20,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.t(section.labelKey()),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (!available)
                  Tooltip(
                    message: l10n.t('nav.comingSoon'),
                    child: Icon(
                      Icons.schedule,
                      size: 15,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({required this.state, this.expanded = false});

  final AppState state;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = l10n.isArabic ? l10n.t('lang.english') : l10n.t('lang.arabic');
    final button = OutlinedButton.icon(
      onPressed: state.settings.toggleLanguage,
      icon: const Icon(Icons.translate, size: 18),
      label: Text(label),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({required this.title, required this.state});

  final String title;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _LanguageButton(state: state),
        ],
      ),
    );
  }
}
