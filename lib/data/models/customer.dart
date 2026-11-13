/// Customer (account) master data.
class Customer {
  const Customer({
    this.id,
    required this.name,
    this.accountName,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String name;
  final String? accountName;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPersisted => id != null;

  /// The account name is used on quotations; fall back to the customer name.
  String get displayAccountName {
    final account = accountName?.trim();
    if (account != null && account.isNotEmpty) return account;
    return name;
  }

  /// Text used for compact lists: prefers the account name with the legal
  /// customer name as a secondary line.
  String get displayName {
    final account = accountName?.trim();
    if (account != null && account.isNotEmpty && account != name) {
      return account;
    }
    return name;
  }

  Customer copyWith({
    int? id,
    String? name,
    String? accountName,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearAccountName = false,
    bool clearContactPerson = false,
    bool clearPhone = false,
    bool clearEmail = false,
    bool clearAddress = false,
    bool clearNotes = false,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      accountName: clearAccountName ? null : (accountName ?? this.accountName),
      contactPerson:
          clearContactPerson ? null : (contactPerson ?? this.contactPerson),
      phone: clearPhone ? null : (phone ?? this.phone),
      email: clearEmail ? null : (email ?? this.email),
      address: clearAddress ? null : (address ?? this.address),
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'name': name.trim(),
      'account_name': _emptyToNull(accountName),
      'contact_person': _emptyToNull(contactPerson),
      'phone': _emptyToNull(phone),
      'email': _emptyToNull(email),
      'address': _emptyToNull(address),
      'notes': _emptyToNull(notes),
    };
  }

  static Customer fromMap(Map<String, Object?> map) {
    return Customer(
      id: map['id'] as int?,
      name: (map['name'] as String? ?? '').trim(),
      accountName: map['account_name'] as String?,
      contactPerson: map['contact_person'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
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
    final text = value.toString();
    return DateTime.tryParse(text)?.toLocal();
  }
}
