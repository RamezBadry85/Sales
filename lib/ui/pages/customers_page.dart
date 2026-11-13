import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/app_exception.dart';
import '../../core/error_messages.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme.dart';
import '../../data/models/customer.dart';
import '../../data/repositories/customer_repository.dart';
import '../controllers/customer_list_controller.dart';
import '../customers/customer_form_dialog.dart';
import '../widgets/app_scaffold.dart';

/// Customer management: list, search, sort, create, edit and delete.
class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key, required this.state});

  final AppState state;

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  late final CustomerListController _controller;
  final TextEditingController _searchController = TextEditingController();
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _controller = CustomerListController(widget.state.customers)..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({Customer? customer}) async {
    final result = await showCustomerFormDialog(
      context,
      repository: widget.state.customers,
      customer: customer,
    );
    if (result == null || !mounted) return;
    _controller.upsertLocally(result);
    setState(() => _selectedId = result.id);
    showAppSnackBar(context, context.l10n.t('customer.saved'));
  }

  Future<void> _delete(Customer customer) async {
    final l10n = context.l10n;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.t('customer.deleteTitle'),
      message: l10n.tp('customer.deleteMessage', [customer.name]),
      confirmLabel: l10n.t('common.delete'),
    );
    if (!confirmed || !mounted) return;

    try {
      await widget.state.customers.delete(customer.id!);
      if (!mounted) return;
      _controller.removeLocally(customer.id!);
      if (_selectedId == customer.id) {
        setState(() => _selectedId = null);
      }
      showAppSnackBar(context, l10n.t('customer.deleted'));
    } on AppException catch (error) {
      if (!mounted) return;
      showAppSnackBar(context, describeError(context, error), isError: true);
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(context, describeError(context, error), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return PageScaffold(
          title: l10n.t('customer.title'),
          subtitle: _controller.isLoading
              ? null
              : l10n.tp('common.results', [_controller.totalCount]),
          actions: [
            FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.t('customer.add')),
            ),
          ],
          filters: _buildFilters(context),
          child: _buildContent(context),
        );
      },
    );
  }

  Widget _buildFilters(BuildContext context) {
    final l10n = context.l10n;
    final isCompact = MediaQuery.sizeOf(context).width < AppBreakpoints.compact;

    final searchField = TextField(
      controller: _searchController,
      onChanged: _controller.search,
      decoration: InputDecoration(
        hintText: l10n.t('customer.searchHint'),
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: l10n.t('common.clear'),
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  _searchController.clear();
                  _controller.search('');
                  setState(() {});
                },
              ),
      ),
    );

    final sortField = DropdownButtonFormField<CustomerSort>(
      initialValue: _controller.sort,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.t('common.sortBy'),
        prefixIcon: const Icon(Icons.sort, size: 18),
      ),
      items: [
        DropdownMenuItem(
          value: CustomerSort.nameAsc,
          child: Text(l10n.t('customer.sortName')),
        ),
        DropdownMenuItem(
          value: CustomerSort.newest,
          child: Text(l10n.t('customer.sortNewest')),
        ),
        DropdownMenuItem(
          value: CustomerSort.oldest,
          child: Text(l10n.t('customer.sortOldest')),
        ),
      ],
      onChanged: (value) {
        if (value != null) _controller.changeSort(value);
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (isCompact) {
          return Column(
            children: [
              searchField,
              const SizedBox(height: 10),
              sortField,
            ],
          );
        }
        return Row(
          children: [
            Expanded(flex: 3, child: searchField),
            const SizedBox(width: 10),
            SizedBox(width: 230, child: sortField),
          ],
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = context.l10n;

    if (_controller.isLoading) {
      return const SurfaceCard(child: LoadingState());
    }
    if (_controller.error != null) {
      return SurfaceCard(
        child: ErrorState(
          message: describeError(context, _controller.error!),
          onRetry: _controller.load,
        ),
      );
    }
    if (_controller.isEmpty) {
      return SurfaceCard(
        child: EmptyState(
          icon: Icons.groups_outlined,
          title: l10n.t('customer.empty'),
          message: l10n.t('customer.emptyHint'),
          action: FilledButton.icon(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
            label: Text(l10n.t('customer.add')),
          ),
        ),
      );
    }
    if (_controller.hasNoResults) {
      return SurfaceCard(
        child: EmptyState(
          icon: Icons.search_off,
          title: l10n.t('common.noResults'),
          action: TextButton(
            onPressed: () {
              _searchController.clear();
              _controller.search('');
              setState(() {});
            },
            child: Text(l10n.t('common.clear')),
          ),
        ),
      );
    }

    // The master/detail split needs room for the table plus a 340px panel;
    // below that the card list is used so nothing is squeezed.
    final isCompact = MediaQuery.sizeOf(context).width < AppBreakpoints.wide;
    if (isCompact) {
      return _buildCardList(context);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 3, child: SurfaceCard(child: _buildTable(context))),
        const SizedBox(width: 14),
        SizedBox(width: 340, child: _buildDetailPanel(context)),
      ],
    );
  }

  Widget _buildDetailPanel(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final selected = _controller.customers.firstWhere(
      (c) => c.id == _selectedId,
      orElse: () => _controller.customers.first,
    );

    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.t('customer.info'),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: l10n.t('common.edit'),
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => _openForm(customer: selected),
              ),
              IconButton(
                tooltip: l10n.t('common.delete'),
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
                onPressed: () => _delete(selected),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            selected.displayName,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoRow(label: l10n.t('customer.name'), value: selected.name),
                  InfoRow(
                    label: l10n.t('customer.accountName'),
                    value: selected.accountName,
                  ),
                  InfoRow(
                    label: l10n.t('customer.contactPerson'),
                    value: selected.contactPerson,
                  ),
                  InfoRow(label: l10n.t('customer.phone'), value: selected.phone),
                  InfoRow(label: l10n.t('customer.email'), value: selected.email),
                  InfoRow(
                    label: l10n.t('customer.address'),
                    value: selected.address,
                  ),
                  InfoRow(label: l10n.t('customer.notes'), value: selected.notes),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final customers = _controller.customers;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            final showContact = constraints.maxWidth > 860;
            final showPhone = constraints.maxWidth > 680;
            return SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                showCheckboxColumn: false,
                columnSpacing: 22,
                horizontalMargin: 18,
                headingRowHeight: 46,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 56,
                columns: [
                  DataColumn(label: Text(l10n.t('customer.name'))),
                  DataColumn(label: Text(l10n.t('customer.accountName'))),
                  if (showContact)
                    DataColumn(label: Text(l10n.t('customer.contactPerson'))),
                  if (showPhone)
                    DataColumn(label: Text(l10n.t('customer.phone'))),
                  DataColumn(label: Text(l10n.t('common.actions'))),
                ],
                rows: [
                  for (final customer in customers)
                    DataRow(
                      selected: customer.id == _selectedId,
                      onSelectChanged: (_) =>
                          setState(() => _selectedId = customer.id),
                      color: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return theme.colorScheme.primary
                              .withValues(alpha: 0.07);
                        }
                        return null;
                      }),
                      cells: [
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                customer.name,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (customer.address != null)
                                Text(
                                  customer.address!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        DataCell(Text(customer.accountName ?? '—')),
                        if (showContact)
                          DataCell(Text(customer.contactPerson ?? '—')),
                        if (showPhone)
                          DataCell(
                            Text(
                              customer.phone ?? '—',
                              textDirection: TextDirection.ltr,
                            ),
                          ),
                        DataCell(_RowActions(
                          onEdit: () => _openForm(customer: customer),
                          onDelete: () => _delete(customer),
                          editTooltip: l10n.t('common.edit'),
                          deleteTooltip: l10n.t('common.delete'),
                        )),
                      ],
                    ),
                ],
                ),
              ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCardList(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return ListView.separated(
      itemCount: _controller.customers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final customer = _controller.customers[index];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _openForm(customer: customer),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.10),
                    child: Text(
                      _initials(customer.name),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.displayName,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            customer.name,
                            if (customer.phone != null) customer.phone!,
                            if (customer.contactPerson != null)
                              customer.contactPerson!,
                          ].join(' • '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.t('common.delete'),
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: () => _delete(customer),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1);
    return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}';
  }
}


/// Compact edit/delete buttons that fit inside narrow table cells.
class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.onEdit,
    required this.onDelete,
    required this.editTooltip,
    required this.deleteTooltip,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String editTooltip;
  final String deleteTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: editTooltip,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.edit_outlined, size: 18),
          onPressed: onEdit,
        ),
        IconButton(
          tooltip: deleteTooltip,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          padding: EdgeInsets.zero,
          icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
          onPressed: onDelete,
        ),
      ],
    );
  }
}
