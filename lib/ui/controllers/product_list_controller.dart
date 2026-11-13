import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/app_exception.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';

/// State for the product list: search, category/company filters and sorting.
class ProductListController extends ChangeNotifier {
  ProductListController(this._repository);

  final ProductRepository _repository;

  List<Product> _products = const <Product>[];
  List<Product> _filtered = const <Product>[];
  List<String> _categories = const <String>[];
  List<String> _companies = const <String>[];
  String _query = '';
  String? _category;
  String? _company;
  ProductSort _sort = ProductSort.descriptionAsc;
  bool _loading = true;
  Object? _error;
  Timer? _debounce;

  List<Product> get all => _products;
  List<Product> get products => _filtered;
  List<String> get categories => _categories;
  List<String> get companies => _companies;
  String get query => _query;
  String? get category => _category;
  String? get company => _company;
  ProductSort get sort => _sort;
  bool get isLoading => _loading;
  Object? get error => _error;
  bool get isEmpty => !_loading && _error == null && _products.isEmpty;
  bool get hasNoResults =>
      !_loading && _error == null && _products.isNotEmpty && _filtered.isEmpty;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.search(sort: _sort),
        _repository.distinctValues('category'),
        _repository.distinctValues('company'),
      ]);
      _products = results[0] as List<Product>;
      _categories = results[1] as List<String>;
      _companies = results[2] as List<String>;
      _applyFilter();
    } on AppException catch (error) {
      _error = error;
      _products = const <Product>[];
      _filtered = const <Product>[];
    } catch (error) {
      _error = error;
      _products = const <Product>[];
      _filtered = const <Product>[];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void search(String value) {
    if (_query == value) return;
    _query = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), () {
      _applyFilter();
      notifyListeners();
    });
  }

  void setCategory(String? value) {
    if (_category == value) return;
    _category = value;
    _applyFilter();
    notifyListeners();
  }

  void setCompany(String? value) {
    if (_company == value) return;
    _company = value;
    _applyFilter();
    notifyListeners();
  }

  Future<void> changeSort(ProductSort sort) async {
    if (_sort == sort) return;
    _sort = sort;
    await load();
  }

  void clearFilters() {
    _query = '';
    _category = null;
    _company = null;
    _applyFilter();
    notifyListeners();
  }

  bool get hasActiveFilters =>
      _query.trim().isNotEmpty || _category != null || _company != null;

  void _applyFilter() {
    final query = _query.trim().toLowerCase();
    final filtered = _products.where((product) {
      if (_category != null && product.category != _category) return false;
      if (_company != null && product.company != _company) return false;
      if (query.isEmpty) return true;
      bool matches(String? value) =>
          value != null && value.toLowerCase().contains(query);
      return matches(product.code) ||
          matches(product.description) ||
          matches(product.company) ||
          matches(product.category) ||
          matches(product.unit) ||
          matches(product.notes);
    }).toList();

    filtered.sort((a, b) {
      switch (_sort) {
        case ProductSort.newest:
          return (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0));
        case ProductSort.codeAsc:
          final codeCompare = (a.code ?? '').toLowerCase().compareTo((b.code ?? '').toLowerCase());
          if (codeCompare != 0) return codeCompare;
          return a.description.toLowerCase().compareTo(b.description.toLowerCase());
        case ProductSort.descriptionAsc:
          return a.description.toLowerCase().compareTo(b.description.toLowerCase());
        case ProductSort.priceAsc:
          final av = a.defaultPrice?.toDouble() ?? 0;
          final bv = b.defaultPrice?.toDouble() ?? 0;
          return av.compareTo(bv);
      }
    });

    _filtered = List<Product>.unmodifiable(filtered);
  }

  void removeLocally(int id) {
    _products = _products.where((p) => p.id != id).toList(growable: false);
    _applyFilter();
    notifyListeners();
  }

  void upsertLocally(Product product) {
    final id = product.id;
    if (id == null) return;
    final updated = List<Product>.of(_products);
    final index = updated.indexWhere((p) => p.id == id);
    if (index >= 0) {
      updated[index] = product;
    } else {
      updated.add(product);
    }
    _products = updated;
    _applyFilter();
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
