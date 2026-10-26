import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/customer/customer_list_logic.dart';
import 'package:lotus_erp/models/customer/customer_enums/customer_list_enums.dart';
import 'package:lotus_erp/models/customer/customer_list/customer_list_ui_model.dart';
import 'package:lotus_erp/repositories/customer/customer_list_repository.dart';
import 'package:lotus_erp/ui/customer/customer_list/customer_list_app_bar.dart';
import 'package:lotus_erp/ui/customer/customer_list/customer_list_card.dart';

void main() {
  testWidgets('customer list app bar matches the sidebar module name',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(appBar: CustomerListAppBar(onBack: () {})),
      ),
    );

    expect(find.text('CUSTOMER LIST'), findsOneWidget);
    expect(find.text('CLIENT DIRECTORY'), findsNothing);
  });

  testWidgets('customer card fits compact and wide window sizes',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final width in <double>[360, 900, 1300]) {
      await tester.binding.setSurfaceSize(Size(width, 900));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
              body: CustomerListCard(customer: _customer(1, 'A Customer'))),
        ),
      );
      await tester.pumpAndSettle();
      final layoutError = tester.takeException();
      expect(layoutError, isNull, reason: 'Window width: $width');
    }
  });

  test('customer list shows an error when loading fails', () async {
    final request = Completer<List<CustomerListItemModel>>();
    final logic = CustomerListLogic(repo: _QueuedRepository([request.future]));
    addTearDown(logic.dispose);

    request.completeError(StateError('database unavailable'));
    await Future<void>.delayed(Duration.zero);

    expect(logic.state, CustomerListState.error);
    expect(logic.errorMessage, contains('Failed to refresh customers'));
  });

  test('older refresh cannot replace a newer result', () async {
    final initial = Completer<List<CustomerListItemModel>>();
    final newer = Completer<List<CustomerListItemModel>>();
    final logic = CustomerListLogic(
      repo: _QueuedRepository([initial.future, newer.future]),
    );
    addTearDown(logic.dispose);

    logic.refresh();
    newer.complete([_customer(2, 'New Result')]);
    await Future<void>.delayed(Duration.zero);
    expect(logic.customers.single.name, 'New Result');

    initial.complete([_customer(1, 'Old Result')]);
    await Future<void>.delayed(Duration.zero);
    expect(logic.customers.single.name, 'New Result');
  });

  test('filter and sort reuse the loaded customer snapshot', () async {
    final repository = _QueuedRepository([
      Future.value([
        _customer(1, 'Zara', type: CustomerType.standard),
        _customer(2, 'Asha'),
      ]),
    ]);
    final logic = CustomerListLogic(repo: repository);
    addTearDown(logic.dispose);
    await Future<void>.delayed(Duration.zero);

    logic.setFilter(CustomerFilter.elite);
    expect(logic.customers.map((customer) => customer.name), ['Asha']);
    logic.setFilter(CustomerFilter.all);
    logic.setSort(CustomerSort.nameAsc);

    expect(logic.customers.map((customer) => customer.name), ['Asha', 'Zara']);
    expect(logic.stats.totalCount, 2);
    expect(repository.requestCount, 1);
  });
}

CustomerListItemModel _customer(
  int id,
  String name, {
  CustomerType type = CustomerType.elite,
}) {
  return CustomerListItemModel(
    id: id,
    name: name,
    mobile: '',
    city: '',
    type: type,
    billCount: 0,
    createdAt: DateTime(2026, 1, 1),
    initials: CustomerListItemModel.buildInitials(name),
  );
}

class _QueuedRepository extends CustomerListRepository {
  final List<Future<List<CustomerListItemModel>>> _responses;
  int requestCount = 0;

  _QueuedRepository(this._responses);

  @override
  Future<List<CustomerListItemModel>> getAllCustomers({
    CustomerFilter filter = CustomerFilter.all,
    CustomerSort sort = CustomerSort.newest,
  }) {
    requestCount++;
    return _responses.removeAt(0);
  }
}
