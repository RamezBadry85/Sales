import '../models/product.dart';
import 'product_repository.dart';

/// Abstraction over product persistence.
///
/// See [CustomerStore] for the rationale; the SQLite implementation is used in
/// production and an in-memory implementation is used by widget tests.
abstract class ProductStore {
  Future<List<Product>> search({
    String query = '',
    String? category,
    String? company,
    ProductSort sort = ProductSort.descriptionAsc,
  });

  Future<List<Product>> all();

  Future<Product?> findById(int id);

  Future<int> count();

  Future<List<String>> distinctValues(String column);

  Future<int> insert(Product product);

  Future<void> update(Product product);

  Future<void> delete(int id);
}

/// Adapts the SQLite [ProductRepository] to the [ProductStore] contract.
class SqliteProductStore implements ProductStore {
  SqliteProductStore(this._repository);

  final ProductRepository _repository;

  @override
  Future<List<Product>> all() => _repository.all();

  @override
  Future<int> count() => _repository.count();

  @override
  Future<void> delete(int id) => _repository.delete(id);

  @override
  Future<List<String>> distinctValues(String column) =>
      _repository.distinctValues(column);

  @override
  Future<Product?> findById(int id) => _repository.findById(id);

  @override
  Future<int> insert(Product product) => _repository.insert(product);

  @override
  Future<List<Product>> search({
    String query = '',
    String? category,
    String? company,
    ProductSort sort = ProductSort.descriptionAsc,
  }) =>
      _repository.search(
        query: query,
        category: category,
        company: company,
        sort: sort,
      );

  @override
  Future<void> update(Product product) => _repository.update(product);
}
