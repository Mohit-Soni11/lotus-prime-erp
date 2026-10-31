// -----------------------------------------------------------------------------
// FILE: customer_list_repository.dart
// MODULE: Customer -> Customer List
// DESCRIPTION: Aggregates customer directory data from billing, advance, and
//              girvi records into fast UI-ready models.
// -----------------------------------------------------------------------------

import 'package:lotus_erp/database/db/app_database.dart';

import '../../models/customer/customer_enums/customer_list_enums.dart';
import '../../models/customer/customer_list/customer_list_ui_model.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';
import 'customer_list_activity_loader.dart';
import '../../features/customer/category/data/customer_category_repository.dart';

class CustomerListRepository {
  final AppDatabase _db;

  CustomerListRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  Stream<void> watchChanges() {
    return _db
        .customSelect(
          'SELECT 1 AS watch_key',
          readsFrom: {
            _db.customers,
            _db.bills,
            _db.salesOrders,
            _db.girviLoans,
            _db.billItems,
            _db.girviPayments,
          },
        )
        .watch()
        .skip(1)
        .map((_) {});
  }

  Future<List<CustomerListItemModel>> getAllCustomers({
    CustomerFilter filter = CustomerFilter.all,
    CustomerSort sort = CustomerSort.newest,
  }) async {
    try {
      final rows = await _db.select(_db.customers).get();
      final categoryRepository = CustomerCategoryRepository(_db);
      final scores = await categoryRepository
          .scoresFor(rows.map((customer) => customer.id));
      await categoryRepository.persistCategories(scores);
      final models = await CustomerListActivityLoader(_db).load(rows, scores);
      return filterAndSort(models, filter: filter, sort: sort);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Customer list fetch failed.',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  List<CustomerListItemModel> filterAndSort(
    List<CustomerListItemModel> customers, {
    CustomerFilter filter = CustomerFilter.all,
    CustomerSort sort = CustomerSort.newest,
  }) {
    final filtered = _applyFilter(customers, filter);
    _sortCustomers(filtered, sort);
    return filtered;
  }

  List<CustomerListItemModel> _applyFilter(
    List<CustomerListItemModel> customers,
    CustomerFilter filter,
  ) {
    switch (filter) {
      case CustomerFilter.alert:
        return customers
            .where((customer) => customer.type == CustomerType.alert)
            .toList();
      case CustomerFilter.standard:
        return customers
            .where((customer) => customer.type == CustomerType.standard)
            .toList();
      case CustomerFilter.elite:
        return customers
            .where((customer) => customer.type == CustomerType.elite)
            .toList();
      case CustomerFilter.today:
        return customers
            .where((customer) => customer.hasActivityToday)
            .toList();
      case CustomerFilter.all:
        return List<CustomerListItemModel>.from(customers);
    }
  }

  void _sortCustomers(
    List<CustomerListItemModel> customers,
    CustomerSort sort,
  ) {
    switch (sort) {
      case CustomerSort.nameAsc:
        customers.sort((a, b) => a.name.compareTo(b.name));
        break;
      case CustomerSort.nameDesc:
        customers.sort((a, b) => b.name.compareTo(a.name));
        break;
      case CustomerSort.newest:
        customers.sort(
          (a, b) => b.lastActivityAt.compareTo(a.lastActivityAt),
        );
        break;
      case CustomerSort.oldest:
        customers.sort(
          (a, b) => a.lastActivityAt.compareTo(b.lastActivityAt),
        );
        break;
      case CustomerSort.mostBills:
        customers.sort((a, b) {
          final billSort = b.billCount.compareTo(a.billCount);
          if (billSort != 0) return billSort;
          return b.lastActivityAt.compareTo(a.lastActivityAt);
        });
        break;
    }
  }
}
