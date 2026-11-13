import 'package:flutter/material.dart';

import '../../../core/app_exception.dart';
import '../../../core/decimal_format.dart';
import '../../../core/error_messages.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/product_repository.dart';
import '../../widgets/form_fields.dart';

/// Displays the add/edit product dialog and returns the saved product.
Future<Product?> showProductFormDialog(
  BuildContext context, {
  required ProductRepository repository,
  Product? product,
}) {
  return showDialog<Product>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ProductFormDialog(
      repository: repository,
      product: product,
    ),
  );
}

/// Add/edit form for product master data.
///
/// The product code is explicitly presented as a non-unique attribute so the
/// user is never pushed into overwriting a product that shares a code.
class ProductFormDialog extends StatefulWidget {
  const ProductFormDialog({
    super.key,
    required this.repository,
    this.product,
  });

  final ProductRepository repository;
  final Product? product;

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _category;
  late final TextEditingController _company;
  late final TextEditingController _code;
  late final TextEditingController _description;
  late final TextEditingController _unit;
  late final TextEditingController _price;
  late final TextEditingController _notes;

  bool _saving = false;
  String? _serverError;

  bool get _isEditing => widget.product?.id != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _category = TextEditingController(text: product?.category ?? '');
    _company = TextEditingController(text: product?.company ?? '');
    _code = TextEditingController(text: product?.code ?? '');
    _description = TextEditingController(text: product?.description ?? '');
    _unit = TextEditingController(text: product?.unit ?? '');
    _price = TextEditingController(
      text: product?.defaultPrice != null
          ? DecimalFormat.format(product!.defaultPrice, minFractionDigits: 2)
          : '',
    );
    _notes = TextEditingController(text: product?.notes ?? '');
  }

  @override
  void dispose() {
    _category.dispose();
    _company.dispose();
    _code.dispose();
    _description.dispose();
    _unit.dispose();
    _price.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final price = DecimalFormat.tryParse(_price.text);
    setState(() {
      _saving = true;
      _serverError = null;
    });

    final candidate = Product(
      id: widget.product?.id,
      category: _category.text,
      company: _company.text,
      code: _code.text,
      description: _description.text.trim(),
      unit: _unit.text,
      defaultPrice: price,
      notes: _notes.text,
      createdAt: widget.product?.createdAt,
      updatedAt: widget.product?.updatedAt,
    );

    try {
      if (_isEditing) {
        await widget.repository.update(candidate);
        if (!mounted) return;
        Navigator.of(context).pop(candidate);
      } else {
        final id = await widget.repository.insert(candidate);
        final created = await widget.repository.findById(id);
        if (!mounted) return;
        Navigator.of(context).pop(created ?? candidate.copyWith(id: id));
      }
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _serverError = describeError(context, error);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _serverError = describeError(context, error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isCompact = MediaQuery.sizeOf(context).width < 620;
    final double width = isCompact ? MediaQuery.sizeOf(context).width - 32 : 680;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.inventory_2_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isEditing ? l10n.t('product.edit') : l10n.t('product.add'),
            ),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      content: SizedBox(
        width: width,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_serverError != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .error
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_serverError!)),
                      ],
                    ),
                  ),
                LabeledTextField(
                  controller: _description,
                  label: l10n.t('product.description'),
                  required: true,
                  autofocus: !_isEditing,
                  maxLines: 2,
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return l10n.t('validation.nameRequired');
                    }
                    if (value!.trim().length > 500) {
                      return l10n.t('validation.tooLong');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _ResponsivePair(
                  compact: isCompact,
                  first: LabeledTextField(
                    controller: _code,
                    label: l10n.t('product.code'),
                    textDirection: TextDirection.ltr,
                    textInputAction: TextInputAction.next,
                    helper: l10n.t('product.codeHint'),
                  ),
                  second: LabeledTextField(
                    controller: _unit,
                    label: l10n.t('product.unit'),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(height: 14),
                _ResponsivePair(
                  compact: isCompact,
                  first: LabeledTextField(
                    controller: _category,
                    label: l10n.t('product.category'),
                    textInputAction: TextInputAction.next,
                  ),
                  second: LabeledTextField(
                    controller: _company,
                    label: l10n.t('product.company'),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(height: 14),
                DecimalTextField(
                  controller: _price,
                  label: l10n.t('product.price'),
                  prefixIcon: Icons.payments_outlined,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                LabeledTextField(
                  controller: _notes,
                  label: l10n.t('product.notes'),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.t('common.cancel')),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check, size: 18),
          label: Text(l10n.t('common.save')),
        ),
      ],
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({
    required this.compact,
    required this.first,
    required this.second,
  });

  final bool compact;
  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        children: [
          first,
          const SizedBox(height: 14),
          second,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 12),
        Expanded(child: second),
      ],
    );
  }
}
