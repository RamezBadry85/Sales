import 'package:decimal/decimal.dart';

import '../../core/decimal_format.dart';

/// Product master data.
///
/// The business rule from the source workbook is respected: [code] is *not* a
/// unique identifier. Identity is always [id]; the code is a searchable
/// attribute only, and duplicates are explicitly allowed.
class Product {
  const Product({
    this.id,
    this.category,
    this.company,
    this.code,
    required this.description,
    this.unit,
    this.defaultPrice,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String? category;
  final String? company;
  final String? code;
  final String description;
  final String? unit;
  final Decimal? defaultPrice;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPersisted => id != null;

  /// Short label used in selection lists and tables.
  String get displayLabel {
    final codePart = (code ?? '').trim();
    if (codePart.isEmpty) return description;
    return '$codePart — $description';
  }

  String get formattedPrice => DecimalFormat.format(defaultPrice, minFractionDigits: 2);

  Product copyWith({
    int? id,
    String? category,
    String? company,
    String? code,
    String? description,
    String? unit,
    Decimal? defaultPrice,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearCategory = false,
    bool clearCompany = false,
    bool clearCode = false,
    bool clearUnit = false,
    bool clearPrice = false,
    bool clearNotes = false,
  }) {
    return Product(
      id: id ?? this.id,
      category: clearCategory ? null : (category ?? this.category),
      company: clearCompany ? null : (company ?? this.company),
      code: clearCode ? null : (code ?? this.code),
      description: description ?? this.description,
      unit: clearUnit ? null : (unit ?? this.unit),
      defaultPrice: clearPrice ? null : (defaultPrice ?? this.defaultPrice),
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'category': _emptyToNull(category),
      'company': _emptyToNull(company),
      'code': _emptyToNull(code),
      'description': description.trim(),
      'unit': _emptyToNull(unit),
      'default_price': DecimalFormat.toStorage(defaultPrice),
      'notes': _emptyToNull(notes),
    };
  }

  static Product fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as int?,
      category: map['category'] as String?,
      company: map['company'] as String?,
      code: map['code'] as String?,
      description: (map['description'] as String? ?? '').trim(),
      unit: map['unit'] as String?,
      defaultPrice: DecimalFormat.fromStorage(map['default_price']),
      notes: map['notes'] as String?,
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  static String? _emptyToNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
