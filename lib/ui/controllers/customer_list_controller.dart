import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/app_exception.dart';
import '../../data/models/customer.dart';
import '../../data/repositories/customer_repository.dart';

/// State for the customer list: search text, sorting and derived counts.
class CustomerListController extends ChangeNotifier {
  CustomerListController(this._repository);

  final CustomerRepository _repository;

  List<Customer> _customers = const <Customer>[];
  List<Customer> _filtered = const <Customer>[];
  String _query = '';
  CustomerSort _sort = CustomerSort.nameAsc;
  bool _loading = true;
  Object? _error;
  int _totalCount = 0;
  Timer? _debounce;

  List<Customer> get all => _customers;
  List<Customer> get customers => _filtered;
  String get query => _query;
  CustomerSort get sort => _sort;
  bool get isLoading => _loading;
  Object? get error => _error;
  bool get isEmpty => !_loading && _error == null && _customers.isEmpty;
  bool get hasNoResults => !_loading && _error == null && _customers.isNotEmpty && _filtered.isEmpty;
  int get totalCount => _totalCount;

  /// Loads every customer once; filtering afterwards is local so typing feels
  /// instant even with a large customer base.
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final customers = await _repository.search(sort: _sort);
      _customers = customers;
      _totalCount = customers.length;
      _applyFilter();
    } on AppException catch (error) {
      _error = error;
      _customers = const <Customer>[];
      _filtered = const <Customer>[];
    } catch (error) {
      _error = error;
      _customers = const <Customer>[];
      _filtered = const <Customer>[];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void search(String value) {
    if (_query == value) return;
    _query = value;
    _debounce?.cancel();
    // Local filtering is cheap; a short debounce keeps typing smooth with
    // thousands of rows.
    _debounce = Timer(const Duration(milliseconds: 120), () {
      _applyFilter();
      notifyListeners();
    });
  }

  Future<void> changeSort(CustomerSort sort) async {
    if (_sort == sort) return;
    _sort = sort;
    await load();
  }

  void _applyFilter() {
    final query = _query.trim().toLowerCase();
    final sorted = List<Customer>.of(_customers)..sort((a, b) {
        switch (_sort) {
          case CustomerSort.nameAsc:
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          case CustomerSort.newest:
            return (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0));
          case CustomerSort.oldest:
            return (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0));
        }
      });

    if (query.isEmpty) {
      _filtered = List<Customer>.unmodifiable(sorted);
      return;
    }
    _filtered = List<Customer>.unmodifiable(sorted.where((customer) {
      bool matches(String? value) =>
          value != null && value.toLowerCase().contains(query);
      return matches(customer.name) ||
          matches(customer.accountName) ||
          matches(customer.contactPerson) ||
          matches(customer.phone) ||
          matches(customer.email) ||
          matches(customer.address);
    }));
  }

  /// Removes a customer from local state after a successful delete.
  void removeLocally(int id) {
    _customers = _customers.where((c) => c.id != id).toList(growable: false);
    _totalCount = _customers.length;
    _applyFilter();
    notifyListeners();
  }

  /// Replaces (or inserts) a customer after a save.
  void upsertLocally(Customer customer) {
    final id = customer.id;
    if (id == null) return;
    final updated = List<Customer>.of(_customers);
    final index = updated.indexWhere((c) => c.id == id);
    if (index >= 0) {
      updated[index] = customer;
    } else {
      updated.add(customer);
    }
    _customers = updated;
    _totalCount = updated.length;
    _applyFilter();
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
