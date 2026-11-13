import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/app_exception.dart';
import '../../core/error_messages.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../controllers/product_list_controller.dart';
import '../products/product_form_dialog.dart';
import '../widgets/app_scaffold.dart';

/// Product management: list, search, category/company filters, CRUD.
class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key, required this.state});

  final AppState state;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late final ProductListController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = ProductListController(widget.state.products)..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({Product? product}) async {
    final result = await showProductFormDialog(
      context,
      repository: widget.state.products,
      product: product,
    );
    if (result == null || !mounted) return;
    // Reload so category/company filter options stay in sync.
    await _controller.load();
    if (!mounted) return;
    showAppSnackBar(context, context.l10n.t('product.saved'));
  }

  Future<void> _delete(Product product) async {
    final l10n = context.l10n;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.t('product.deleteTitle'),
      message: l10n.tp('product.deleteMessage', [product.description]),
      confirmLabel: l10n.t('common.delete'),
    );
    if (!confirmed || !mounted) return;

    try {
      await widget.state.products.delete(product.id!);
      if (!mounted) return;
      _controller.removeLocally(product.id!);
      showAppSnackBar(context, l10n.t('product.deleted'));
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
          title: l10n.t('product.title'),
          subtitle: _controller.isLoading
              ? null
              : l10n.tp('common.results', [_controller.products.length]),
          actions: [
            FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.t('product.add')),
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
        hintText: l10n.t('product.searchHint'),
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

    final categoryField = DropdownButtonFormField<String?>(
      initialValue: _controller.category,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.t('product.filterCategory'),
        prefixIcon: const Icon(Icons.category_outlined, size: 18),
      ),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(l10n.t('common.all')),
        ),
        for (final category in _controller.categories)
          DropdownMenuItem<String?>(value: category, child: Text(category)),
      ],
      onChanged: _controller.setCategory,
    );

    final companyField = DropdownButtonFormField<String?>(
      initialValue: _controller.company,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.t('product.filterCompany'),
        prefixIcon: const Icon(Icons.factory_outlined, size: 18),
      ),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(l10n.t('common.all')),
        ),
        for (final company in _controller.companies)
          DropdownMenuItem<String?>(value: company, child: Text(company)),
      ],
      onChanged: _controller.setCompany,
    );

    final sortField = DropdownButtonFormField<ProductSort>(
      initialValue: _controller.sort,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.t('common.sortBy'),
        prefixIcon: const Icon(Icons.sort, size: 18),
      ),
      items: [
        DropdownMenuItem(
          value: ProductSort.descriptionAsc,
          child: Text(l10n.t('product.sortDescription')),
        ),
        DropdownMenuItem(
          value: ProductSort.codeAsc,
          child: Text(l10n.t('product.sortCode')),
        ),
        DropdownMenuItem(
          value: ProductSort.priceAsc,
          child: Text(l10n.t('product.sortPrice')),
        ),
        DropdownMenuItem(
          value: ProductSort.newest,
          child: Text(l10n.t('product.sortNewest')),
        ),
      ],
      onChanged: (value) {
        if (value != null) _controller.changeSort(value);
      },
    );

    if (isCompact) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final showThreePerRow = constraints.maxWidth > 560;
          return Column(
            children: [
              searchField,
              const SizedBox(height: 10),
              if (showThreePerRow)
                Row(
                  children: [
                    Expanded(child: categoryField),
                    const SizedBox(width: 10),
                    Expanded(child: companyField),
                  ],
                )
              else ...[
                categoryField,
                const SizedBox(height: 10),
                companyField,
              ],
              const SizedBox(height: 10),
              sortField,
            ],
          );
        },
      );
    }

    return Row(
      children: [
        Expanded(flex: 3, child: searchField),
        const SizedBox(width: 10),
        SizedBox(width: 170, child: categoryField),
        const SizedBox(width: 10),
        SizedBox(width: 170, child: companyField),
        const SizedBox(width: 10),
        SizedBox(width: 190, child: sortField),
      ],
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
          icon: Icons.inventory_2_outlined,
          title: l10n.t('product.empty'),
          message: l10n.t('product.emptyHint'),
          action: FilledButton.icon(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
            label: Text(l10n.t('product.add')),
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
              _controller.clearFilters();
              setState(() {});
            },
            child: Text(l10n.t('common.clear')),
          ),
        ),
      );
    }

    final isCompact = MediaQuery.sizeOf(context).width < AppBreakpoints.compact;
    if (isCompact) {
      return _buildCardList(context);
    }
    return SurfaceCard(child: _buildTable(context));
  }

  Widget _buildTable(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final products = _controller.products;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showUnit = constraints.maxWidth > 980;
              final showCategory = constraints.maxWidth > 860;
              return SingleChildScrollView(
                child: SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    showCheckboxColumn: false,
                    columnSpacing: 20,
                    horizontalMargin: 18,
                    headingRowHeight: 46,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 62,
                    columns: [
                      DataColumn(label: Text(l10n.t('product.code'))),
                      DataColumn(label: Text(l10n.t('product.description'))),
                      if (showCategory)
                        DataColumn(label: Text(l10n.t('product.category'))),
                      DataColumn(label: Text(l10n.t('product.company'))),
                      if (showUnit)
                        DataColumn(label: Text(l10n.t('product.unit'))),
                      DataColumn(
                        numeric: true,
                        label: Text(l10n.t('product.price')),
                      ),
                      DataColumn(label: Text(l10n.t('common.actions'))),
                    ],
                    rows: [
                      for (final product in products)
                        DataRow(
                          onSelectChanged: (_) => _openForm(product: product),
                          cells: [
                            DataCell(
                              Text(
                                product.code ?? '—',
                                textDirection: TextDirection.ltr,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 340),
                                child: Text(
                                  product.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                            if (showCategory)
                              DataCell(Text(product.category ?? '—')),
                            DataCell(Text(product.company ?? '—')),
                            if (showUnit) DataCell(Text(product.unit ?? '—')),
                            DataCell(
                              Text(
                                product.defaultPrice == null
                                    ? '—'
                                    : product.formattedPrice,
                                textDirection: TextDirection.ltr,
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: l10n.t('common.edit'),
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                    ),
                                    onPressed: () => _openForm(product: product),
                                  ),
                                  IconButton(
                                    tooltip: l10n.t('common.delete'),
                                    visualDensity: VisualDensity.compact,
                                    icon: Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: theme.colorScheme.error,
                                    ),
                                    onPressed: () => _delete(product),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCardList(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return ListView.separated(
      itemCount: _controller.products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final product = _controller.products[index];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _openForm(product: product),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.description,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.t('common.delete'),
                        icon: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                        ),
                        onPressed: () => _delete(product),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (product.code != null)
                        _Tag(label: product.code!, icon: Icons.qr_code_2),
                      if (product.company != null)
                        _Tag(label: product.company!, icon: Icons.factory_outlined),
                      if (product.category != null)
                        _Tag(
                          label: product.category!,
                          icon: Icons.category_outlined,
                        ),
                      if (product.unit != null)
                        _Tag(label: product.unit!, icon: Icons.straighten),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        l10n.t('product.price'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        product.defaultPrice == null
                            ? '—'
                            : product.formattedPrice,
                        textDirection: TextDirection.ltr,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
