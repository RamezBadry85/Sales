import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/error_messages.dart';
import '../../core/l10n/app_localizations.dart';
import '../shell/app_shell.dart';
import '../widgets/app_scaffold.dart';

/// Overview page with real counts read from the local database.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.state, required this.onNavigate});

  final AppState state;
  final ValueChanged<AppSection> onNavigate;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _loading = true;
  Object? _error;
  int _customers = 0;
  int _products = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final counts = await Future.wait([
        widget.state.customers.count(),
        widget.state.products.count(),
      ]);
      if (!mounted) return;
      setState(() {
        _customers = counts[0];
        _products = counts[1];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return PageScaffold(
      title: l10n.t('dashboard.title'),
      actions: [
        OutlinedButton.icon(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(l10n.t('common.refresh')),
        ),
      ],
      child: _buildBody(context, l10n, theme),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    if (_loading) return const LoadingState();
    if (_error != null) {
      return ErrorState(message: describeError(context, _error!), onRetry: _load);
    }

    final isEmpty = _customers == 0 && _products == 0;

    return ListView(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 640;
            final cards = <Widget>[
              _StatCard(
                label: l10n.t('dashboard.customers'),
                value: '$_customers',
                icon: Icons.groups_outlined,
                color: theme.colorScheme.primary,
                onTap: () => widget.onNavigate(AppSection.customers),
              ),
              _StatCard(
                label: l10n.t('dashboard.products'),
                value: '$_products',
                icon: Icons.inventory_2_outlined,
                color: theme.colorScheme.secondary,
                onTap: () => widget.onNavigate(AppSection.products),
              ),
              _StatCard(
                label: l10n.t('dashboard.quotations'),
                value: null,
                icon: Icons.request_quote_outlined,
                color: theme.colorScheme.tertiary,
                hint: l10n.t('nav.comingSoon'),
              ),
              _StatCard(
                label: l10n.t('dashboard.sales'),
                value: null,
                icon: Icons.point_of_sale_outlined,
                color: theme.colorScheme.error,
                hint: l10n.t('nav.comingSoon'),
              ),
            ];

            if (isCompact) {
              return Column(
                children: [
                  for (final card in cards)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: card,
                    ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: cards[i]),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        if (isEmpty)
          SurfaceCard(
            child: EmptyState(
              icon: Icons.rocket_launch_outlined,
              title: l10n.t('dashboard.welcome'),
              message: l10n.t('dashboard.emptyHint'),
              action: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () => widget.onNavigate(AppSection.customers),
                    icon: const Icon(Icons.person_add_alt),
                    label: Text(l10n.t('dashboard.addCustomer')),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => widget.onNavigate(AppSection.products),
                    icon: const Icon(Icons.add_box_outlined),
                    label: Text(l10n.t('dashboard.addProduct')),
                  ),
                ],
              ),
            ),
          )
        else
          SurfaceCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('dashboard.quickActions'),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: () => widget.onNavigate(AppSection.customers),
                      icon: const Icon(Icons.person_add_alt),
                      label: Text(l10n.t('dashboard.addCustomer')),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => widget.onNavigate(AppSection.products),
                      icon: const Icon(Icons.add_box_outlined),
                      label: Text(l10n.t('dashboard.addProduct')),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.hint,
    this.onTap,
  });

  final String label;
  final String? value;
  final IconData icon;
  final Color color;
  final String? hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                value ?? '—',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: value == null ? theme.colorScheme.onSurfaceVariant : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (hint != null) ...[
                const SizedBox(height: 6),
                Text(
                  hint!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
