import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_exception.dart';
import '../../../core/error_messages.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../data/models/customer.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../widgets/form_fields.dart';

/// Displays the add/edit customer dialog and returns the saved customer.
Future<Customer?> showCustomerFormDialog(
  BuildContext context, {
  required CustomerRepository repository,
  Customer? customer,
}) {
  return showDialog<Customer>(
    context: context,
    barrierDismissible: false,
    builder: (context) => CustomerFormDialog(
      repository: repository,
      customer: customer,
    ),
  );
}

/// Add/edit form for customer master data with validation and persistence.
class CustomerFormDialog extends StatefulWidget {
  const CustomerFormDialog({
    super.key,
    required this.repository,
    this.customer,
  });

  final CustomerRepository repository;
  final Customer? customer;

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _accountName;
  late final TextEditingController _contactPerson;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _notes;

  bool _saving = false;
  String? _serverError;

  bool get _isEditing => widget.customer?.id != null;

  @override
  void initState() {
    super.initState();
    final customer = widget.customer;
    _name = TextEditingController(text: customer?.name ?? '');
    _accountName = TextEditingController(text: customer?.accountName ?? '');
    _contactPerson =
        TextEditingController(text: customer?.contactPerson ?? '');
    _phone = TextEditingController(text: customer?.phone ?? '');
    _email = TextEditingController(text: customer?.email ?? '');
    _address = TextEditingController(text: customer?.address ?? '');
    _notes = TextEditingController(text: customer?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _accountName.dispose();
    _contactPerson.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _serverError = null;
    });

    final base = widget.customer ??
        const Customer(name: '');
    final candidate = Customer(
      id: widget.customer?.id,
      name: _name.text.trim(),
      accountName: _accountName.text,
      contactPerson: _contactPerson.text,
      phone: _phone.text,
      email: _email.text,
      address: _address.text,
      notes: _notes.text,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
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
    final double width = isCompact ? MediaQuery.sizeOf(context).width - 32 : 640;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.person_outline),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isEditing ? l10n.t('customer.edit') : l10n.t('customer.add'),
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
                  controller: _name,
                  label: l10n.t('customer.name'),
                  required: true,
                  autofocus: !_isEditing,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return l10n.t('validation.nameRequired');
                    }
                    if (value!.trim().length > 200) {
                      return l10n.t('validation.tooLong');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                LabeledTextField(
                  controller: _accountName,
                  label: l10n.t('customer.accountName'),
                  helper: l10n.isArabic
                      ? 'يُستخدم في رأس عروض الأسعار؛ إذا تُرك فارغاً يُستخدم اسم العميل.'
                      : 'Used on quotation headers; falls back to the customer name.',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                _ResponsivePair(
                  compact: isCompact,
                  first: LabeledTextField(
                    controller: _contactPerson,
                    label: l10n.t('customer.contactPerson'),
                    textInputAction: TextInputAction.next,
                  ),
                  second: LabeledTextField(
                    controller: _phone,
                    label: l10n.t('customer.phone'),
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9+\-()\s]'),
                      ),
                    ],
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(height: 14),
                LabeledTextField(
                  controller: _email,
                  label: l10n.t('customer.email'),
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return null;
                    final valid =
                        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
                    return valid ? null : l10n.t('error.invalidEmail');
                  },
                ),
                const SizedBox(height: 14),
                LabeledTextField(
                  controller: _address,
                  label: l10n.t('customer.address'),
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                LabeledTextField(
                  controller: _notes,
                  label: l10n.t('customer.notes'),
                  maxLines: 3,
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
