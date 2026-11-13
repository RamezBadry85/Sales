import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/services.dart';

import '../../core/decimal_format.dart';
import '../../core/l10n/app_localizations.dart';

/// Text field with consistent styling and validation messaging.
class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.helper,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.textInputAction,
    this.onChanged,
    this.autofocus = false,
    this.enabled = true,
    this.prefixIcon,
    this.textDirection,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helper;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final bool enabled;
  final IconData? prefixIcon;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType ?? (maxLines > 1 ? TextInputType.multiline : null),
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      onChanged: onChanged,
      autofocus: autofocus,
      enabled: enabled,
      textDirection: textDirection,
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return l10n.t('validation.nameRequired');
        }
        return validator?.call(value);
      },
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 3,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}

/// Characters accepted by [DecimalTextField]: ASCII/Arabic digits, '.' and ','
/// separators, and the Arabic decimal separator U+066B / thousands U+066C.
final RegExp _decimalChars = RegExp('[0-9.,\u0660-\u0669\u06F0-\u06F9\u066B\u066C]');

/// Same as [_decimalChars] but also accepts a minus sign.
final RegExp _decimalCharsWithSign =
    RegExp('[0-9.,\\-\u0660-\u0669\u06F0-\u06F9\u066B\u066C]');

/// Numeric field with Arabic-digit friendly input and decimal validation.
class DecimalTextField extends StatelessWidget {
  const DecimalTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.helper,
    this.required = false,
    this.allowNegative = false,
    this.onChanged,
    this.textInputAction,
    this.autofocus = false,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helper;
  final bool required;
  final bool allowNegative;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: textInputAction,
      autofocus: autofocus,
      textDirection: TextDirection.ltr,
      onChanged: onChanged,
      // Digits (ASCII, Arabic-Indic, extended Arabic-Indic) plus the '.' and
      // ',' separators and the Arabic decimal/thousands separators (U+066B,
      // U+066C). Filtering must never drop the separator a user typed.
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(
          allowNegative ? _decimalCharsWithSign : _decimalChars,
        ),
      ],
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) {
          if (required) return l10n.t('validation.priceInvalid');
          return null;
        }
        final parsed = DecimalFormat.tryParse(text);
        if (parsed == null) return l10n.t('validation.priceInvalid');
        if (!allowNegative && parsed < Decimal.zero) {
          return l10n.t('validation.priceInvalid');
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 3,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
      ),
    );
  }
}
