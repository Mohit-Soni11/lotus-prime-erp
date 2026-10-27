import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/customer/customer_list_logic.dart';
import 'package:lotus_erp/models/customer/customer_enums/customer_list_enums.dart';
import 'package:lotus_erp/models/customer/customer_list/customer_list_ui_model.dart';
import 'package:lotus_erp/repositories/customer/customer_list_repository.dart';
import 'package:lotus_erp/theme/customer/customer_list/customer_list_theme.dart';
import 'package:lotus_erp/ui/customer/customer_list/customer_list_app_bar.dart';
import 'package:lotus_erp/ui/customer/customer_list/customer_list_card.dart';
import 'package:lotus_erp/ui/customer/customer_list/customer_list_card_components.dart';
import 'package:lotus_erp/ui/customer/customer_list/customer_list_identity.dart';
import 'package:lotus_erp/ui/customer/customer_list/customer_list_result_header.dart';
import 'package:lotus_erp/ui/customer/customer_list/customer_list_stats_dashboard.dart';

void main() {
  testWidgets('customer list app bar matches the sidebar module name',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(appBar: CustomerListAppBar(onBack: () {})),
      ),
    );

    expect(find.text('CUSTOMER LIST'), findsOneWidget);
    expect(find.text('SYSTEM ONLINE'), findsOneWidget);
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
      expect(find.text('Invoices'), findsOneWidget);
      expect(find.text('Due Invoices'), findsNothing);
      expect(find.text('Active Girvi Loans'), findsNothing);
      expect(find.text('Open Advance Orders'), findsNothing);
      expect(find.textContaining('Girvi ticket GRV-001'), findsNothing);
    }
  });

  testWidgets(
      'customer card shows only relevant counts on small and wide windows',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in <double>[360, 900, 1300, 1920]) {
      await tester.binding.setSurfaceSize(Size(width, 900));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerListCard(
              customer: CustomerListItemModel(
                id: 1,
                name: 'A Customer With A Long Full Name',
                mobile: '9304499346',
                city: 'Patna',
                type: CustomerType.standard,
                billCount: 14,
                dueInvoiceCount: 2,
                activeGirviCount: 6,
                activeAdvanceCount: 7,
                dueAmount: 6825.50,
                createdAt: DateTime(2026, 1, 1),
                lastActivityLabel: 'Girvi ticket GRV-001',
                initials: 'AC',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CustomerListMetricTile), findsNWidgets(4));
      expect(find.text('Invoices'), findsOneWidget);
      expect(find.text('Due Invoices'), findsOneWidget);
      expect(find.text('Active Girvi Loans'), findsOneWidget);
      expect(find.text('Open Advance Orders'), findsOneWidget);
      final advanceTile = find.ancestor(
        of: find.text('Open Advance Orders'),
        matching: find.byType(CustomerListMetricTile),
      );
      expect(
        tester.widget<CustomerListMetricTile>(advanceTile).icon,
        Icons.pending_actions_rounded,
      );
      expect(find.text('₹ 6,825.50'), findsNothing);
      expect(find.textContaining('Girvi ticket GRV-001'), findsNothing);
      expect(find.text('Address not added'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Window width: $width');
      final avatarTop =
          tester.getTopLeft(find.byKey(const ValueKey('customer-avatar'))).dy;
      final actionTop = tester
          .getTopLeft(find.byKey(const ValueKey('open-profile-action')))
          .dy;
      expect(actionTop, closeTo(avatarTop, 2));
      if (width >= 900) {
        final identity = tester.getRect(find.byType(CustomerListIdentity));
        final metric = tester.getRect(find.byType(CustomerListMetricRail));
        expect(metric.left, greaterThan(identity.right));
        expect(metric.top, lessThan(identity.bottom));
        final nameTop =
            tester.getTopLeft(find.text('A Customer With A Long Full Name')).dy;
        expect(avatarTop, closeTo(nameTop, 2));
        expect(
          tester.getSize(find.byType(CustomerListCard)).height,
          lessThan(width >= 1300 ? 160 : 280),
        );
      }
    }
  });

  testWidgets('customer card displays the saved address', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in <double>[360, 1920]) {
      await tester.binding.setSurfaceSize(Size(width, 900));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerListCard(
              customer: CustomerListItemModel(
                id: 1,
                name: 'Asha',
                mobile: '9000000101',
                addressLine1: '12 MG Road',
                addressLine2: 'Near Temple',
                city: 'Patna',
                state: 'Bihar',
                pincode: '800001',
                type: CustomerType.standard,
                billCount: 1,
                createdAt: DateTime(2026, 1, 1),
                initials: 'AS',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Address: 12 MG Road, Near Temple, Patna, Bihar, 800001'),
        findsOneWidget,
      );
      expect(find.text('Patna'), findsNothing);
      expect(tester.takeException(), isNull, reason: 'Window width: $width');
    }
  });

  testWidgets('long metric labels fit at larger text sizes', (tester) async {
    for (final scale in <double>[1.0, 1.25, 1.5]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: Row(
                children: [
                  for (final label in <String>[
                    'Active Girvi Loans',
                    'Open Advance Orders',
                  ])
                    SizedBox(
                      width: 185,
                      child: CustomerListMetricTile(
                        icon: CustomerListIcons.advance,
                        label: label,
                        value: '7',
                        accent: CustomerListColors.teal,
                        background: CustomerListColors.tealBg,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'Text scale: $scale');
    }
  });

  testWidgets('customer profile heading stays left aligned', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1920, 900));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomerListResultHeader(
            visibleCount: 1,
            filter: CustomerFilter.all,
            sort: CustomerSort.newest,
            searchQuery: '',
          ),
        ),
      ),
    );

    expect(find.text('Customer Profiles'), findsOneWidget);
    expect(find.text('1 customer · Recent Activity'), findsOneWidget);
    expect(find.textContaining('visible'), findsNothing);
    expect(tester.getTopLeft(find.text('Customer Profiles')).dx, 22);
    expect(tester.takeException(), isNull);
  });

  testWidgets('summary cards stay equal and show full outstanding amount',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1300, 900));
    final customer = CustomerListItemModel(
      id: 1,
      name: 'Asha',
      mobile: '',
      city: '',
      type: CustomerType.standard,
      billCount: 14,
      dueAmount: 6825.50,
      createdAt: DateTime(2026, 1, 1),
      initials: 'AS',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomerListStatsDashboard(
            stats: CustomerListStatsModel.fromCustomers([customer]),
          ),
        ),
      ),
    );

    final cards = find.byType(CustomerListStatCard);
    expect(cards, findsNWidgets(4));
    final sizes = [
      for (final card in cards.evaluate())
        tester.getSize(find.byWidget(card.widget))
    ];
    expect(sizes.map((size) => size.height).toSet(), {158.0});
    expect(sizes.map((size) => size.width).toSet().length, 1);
    expect(find.text('Total Outstanding Amount'), findsOneWidget);
    expect(find.text('₹ 6,825.50'), findsOneWidget);
    expect(find.text('Customer accounts currently active'), findsOneWidget);
    expect(find.textContaining('invoices recorded'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('app bar and summary fit compact and wide windows',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in <double>[360, 900, 1300]) {
      await tester.binding.setSurfaceSize(Size(width, 900));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: CustomerListAppBar(onBack: () {}),
            body: CustomerListStatsDashboard(
              stats: CustomerListStatsModel.empty(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'Window width: $width');
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

  test('search matches saved street address', () async {
    final repository = _QueuedRepository([
      Future.value([
        _customer(1, 'Asha', addressLine1: '12 MG Road'),
        _customer(2, 'Zara'),
      ]),
    ]);
    final logic = CustomerListLogic(repo: repository);
    addTearDown(() {
      logic.dispose();
      repository.dispose();
    });
    await Future<void>.delayed(Duration.zero);

    logic.onSearchChanged('MG Road');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(logic.customers.map((customer) => customer.name), ['Asha']);
  });

  test('customer changes refresh the list without clearing visible cards',
      () async {
    final pending = Completer<List<CustomerListItemModel>>();
    final repository = _QueuedRepository([
      Future.value([_customer(1, 'Existing Customer')]),
      pending.future,
    ]);
    final logic = CustomerListLogic(repo: repository);
    addTearDown(() {
      logic.dispose();
      repository.dispose();
    });
    await Future<void>.delayed(Duration.zero);

    repository.notifyChange();
    await Future<void>.delayed(const Duration(milliseconds: 180));
    expect(repository.requestCount, 2);
    expect(logic.state, CustomerListState.loaded);
    expect(logic.customers.single.name, 'Existing Customer');

    pending.complete([_customer(2, 'Updated Customer')]);
    await Future<void>.delayed(Duration.zero);
    expect(logic.customers.single.name, 'Updated Customer');
  });
}

CustomerListItemModel _customer(
  int id,
  String name, {
  CustomerType type = CustomerType.elite,
  String addressLine1 = '',
}) {
  return CustomerListItemModel(
    id: id,
    name: name,
    mobile: '',
    addressLine1: addressLine1,
    city: '',
    type: type,
    billCount: 0,
    createdAt: DateTime(2026, 1, 1),
    lastActivityLabel: 'Girvi ticket GRV-001',
    initials: CustomerListItemModel.buildInitials(name),
  );
}

class _QueuedRepository extends CustomerListRepository {
  final List<Future<List<CustomerListItemModel>>> _responses;
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int requestCount = 0;

  _QueuedRepository(this._responses);

  @override
  Stream<void> watchChanges() => _changes.stream;

  void notifyChange() => _changes.add(null);

  void dispose() => _changes.close();

  @override
  Future<List<CustomerListItemModel>> getAllCustomers({
    CustomerFilter filter = CustomerFilter.all,
    CustomerSort sort = CustomerSort.newest,
  }) {
    requestCount++;
    return _responses.removeAt(0);
  }
}
