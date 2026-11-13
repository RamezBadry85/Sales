import '../models/customer.dart';
import 'customer_repository.dart';

/// Abstraction over customer persistence.
///
/// The UI depends on this contract, which allows the SQLite implementation to
/// be swapped for an in-memory one in widget tests without touching widgets.
abstract class CustomerStore {
  Future<List<Customer>> search({
    String query = '',
    CustomerSort sort = CustomerSort.nameAsc,
  });

  Future<List<Customer>> all();

  Future<Customer?> findById(int id);

  Future<int> count();

  Future<int> insert(Customer customer);

  Future<void> update(Customer customer);

  Future<void> delete(int id);
}

/// Adapts the SQLite [CustomerRepository] to the [CustomerStore] contract.
class SqliteCustomerStore implements CustomerStore {
  SqliteCustomerStore(this._repository);

  final CustomerRepository _repository;

  @override
  Future<List<Customer>> all() => _repository.all();

  @override
  Future<int> count() => _repository.count();

  @override
  Future<void> delete(int id) => _repository.delete(id);

  @override
  Future<Customer?> findById(int id) => _repository.findById(id);

  @override
  Future<int> insert(Customer customer) => _repository.insert(customer);

  @override
  Future<List<Customer>> search({
    String query = '',
    CustomerSort sort = CustomerSort.nameAsc,
  }) =>
      _repository.search(query: query, sort: sort);

  @override
  Future<void> update(Customer customer) => _repository.update(customer);
}
