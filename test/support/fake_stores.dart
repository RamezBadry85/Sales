import 'package:sales/core/app_exception.dart';
import 'package:sales/data/models/customer.dart';
import 'package:sales/data/models/product.dart';
import 'package:sales/data/repositories/customer_repository.dart';
import 'package:sales/data/repositories/customer_store.dart';
import 'package:sales/data/repositories/product_repository.dart';
import 'package:sales/data/repositories/product_store.dart';

/// In-memory [CustomerStore] used by widget tests.
///
/// It mirrors the validation rules of the SQLite implementation so the UI
/// behaviour under test matches production behaviour, while every call
/// completes synchronously and therefore works inside `testWidgets`.
class InMemoryCustomerStore implements CustomerStore {
  final Map<int, Customer> _rows = <int, Customer>{};
  int _nextId = 1;

  @override
  Future<List<Customer>> all() => search();

  @override
  Future<int> count() async => _rows.length;

  @override
  Future<List<Customer>> search({
    String query = '',
    CustomerSort sort = CustomerSort.nameAsc,
  }) async {
    final trimmed = query.trim().toLowerCase();
    final results = _rows.values.where((customer) {
      if (trimmed.isEmpty) return true;
      return [customer.name, customer.accountName, customer.contactPerson,
              customer.phone, customer.email, customer.address]
          .whereType<String>()
          .any((value) => value.toLowerCase().contains(trimmed));
    }).toList();

    results.sort((a, b) {
      switch (sort) {
        case CustomerSort.nameAsc:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case CustomerSort.newest:
          return (b.createdAt ?? DateTime(0))
              .compareTo(a.createdAt ?? DateTime(0));
        case CustomerSort.oldest:
          return (a.createdAt ?? DateTime(0))
              .compareTo(b.createdAt ?? DateTime(0));
      }
    });
    return results;
  }

  @override
  Future<Customer?> findById(int id) async => _rows[id];

  @override
  Future<int> insert(Customer customer) async {
    _validate(customer);
    final id = _nextId++;
    _rows[id] = customer.copyWith(id: id, createdAt: DateTime.now());
    return id;
  }

  @override
  Future<void> update(Customer customer) async {
    final id = customer.id;
    if (id == null || !_rows.containsKey(id)) {
      throw AppException(AppErrorCode.notFound);
    }
    _validate(customer);
    _rows[id] = customer;
  }

  @override
  Future<void> delete(int id) async {
    if (_rows.remove(id) == null) {
      throw AppException(AppErrorCode.notFound);
    }
  }

  void _validate(Customer customer) {
    if (customer.name.trim().isEmpty) {
      throw AppException(AppErrorCode.required, field: 'name');
    }
    final email = customer.email?.trim();
    if (email != null &&
        email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      throw AppException(AppErrorCode.invalidEmail, field: 'email');
    }
  }
}

/// In-memory [ProductStore] used by widget tests.
///
/// Product codes are intentionally not unique, matching the business rule.
class InMemoryProductStore implements ProductStore {
  final Map<int, Product> _rows = <int, Product>{};
  int _nextId = 1;

  @override
  Future<List<Product>> all() => search();

  @override
  Future<int> count() async => _rows.length;

  @override
  Future<List<String>> distinctValues(String column) async {
    final values = _rows.values
        .map((product) => switch (column) {
              'category' => product.category,
              'company' => product.company,
              'unit' => product.unit,
              _ => null,
            })
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return values;
  }

  @override
  Future<Product?> findById(int id) async => _rows[id];

  @override
  Future<List<Product>> search({
    String query = '',
    String? category,
    String? company,
    ProductSort sort = ProductSort.descriptionAsc,
  }) async {
    final trimmed = query.trim().toLowerCase();
    final results = _rows.values.where((product) {
      if (category != null && product.category != category) return false;
      if (company != null && product.company != company) return false;
      if (trimmed.isEmpty) return true;
      return [product.code, product.description, product.company,
              product.category, product.unit, product.notes]
          .whereType<String>()
          .any((value) => value.toLowerCase().contains(trimmed));
    }).toList();

    results.sort((a, b) => switch (sort) {
          ProductSort.descriptionAsc =>
            a.description.toLowerCase().compareTo(b.description.toLowerCase()),
          ProductSort.codeAsc =>
            (a.code ?? '').toLowerCase().compareTo((b.code ?? '').toLowerCase()),
          ProductSort.priceAsc => (a.defaultPrice?.toDouble() ?? 0)
              .compareTo(b.defaultPrice?.toDouble() ?? 0),
          ProductSort.newest => (b.createdAt ?? DateTime(0))
              .compareTo(a.createdAt ?? DateTime(0)),
        });
    return results;
  }

  @override
  Future<int> insert(Product product) async {
    _validate(product);
    final id = _nextId++;
    _rows[id] = product.copyWith(id: id, createdAt: DateTime.now());
    return id;
  }

  @override
  Future<void> update(Product product) async {
    final id = product.id;
    if (id == null || !_rows.containsKey(id)) {
      throw AppException(AppErrorCode.notFound);
    }
    _validate(product);
    _rows[id] = product;
  }

  @override
  Future<void> delete(int id) async {
    if (_rows.remove(id) == null) {
      throw AppException(AppErrorCode.notFound);
    }
  }

  void _validate(Product product) {
    if (product.description.trim().isEmpty) {
      throw AppException(AppErrorCode.required, field: 'description');
    }
  }
}
