import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/customer/customer_profile/customer_profile_model.dart';
import 'package:lotus_erp/repositories/customer/customer_profile_repository.dart';
import 'package:lotus_erp/ui/customer/customer_profile/customer_profile_screen.dart';
import 'package:lotus_erp/ui/customer/customer_profile/customer_profile_metric_cards.dart';
import 'package:lotus_erp/ui/customer/customer_profile/customer_profile_information_tiles.dart';

void main() {
  testWidgets(
      'profile shows full address, matching tier and smart account cards',
      (tester) async {
    await _pumpProfile(tester, const Size(1280, 900));

    expect(find.text('Standard Customer'), findsWidgets);
    expect(find.text('Mobile Number'), findsNWidgets(2));
    expect(find.text('Address'), findsNWidgets(2));
    expect(find.text('Full Address'), findsNothing);
    expect(find.text('Main Road, Patna, Bihar, 800001'), findsWidgets);
    expect(find.text('Customer Account Overview'), findsOneWidget);
    expect(find.text('Customer Information'), findsOneWidget);
    expect(find.text('Total Sales Bills'), findsOneWidget);
    expect(find.textContaining('Sales value'), findsNothing);
    expect(find.text('Due Invoices'), findsWidgets);
    expect(find.text('Active Girvi'), findsOneWidget);
    expect(find.text('Active Advance Orders'), findsOneWidget);
    expect(find.text('Total Capital Given'), findsNothing);
    expect(find.text('Due Invoice Value'), findsNothing);
    expect(find.text('Active Capital'), findsOneWidget);
    expect(find.text('Active Interest Due'), findsOneWidget);
    expect(find.text('Pending Dues'), findsNothing);
    expect(find.text('Customer since'), findsNothing);
    expect(find.text('Settled Bills'), findsNothing);
    expect(find.textContaining('Credit Limit'), findsNothing);
    expect(find.textContaining('Account Credit'), findsNothing);
    final informationTiles = find.byType(CustomerProfileInformationTile);
    expect(informationTiles, findsNWidgets(4));
    final tileSizes = informationTiles
        .evaluate()
        .map((element) => tester.getSize(find.byWidget(element.widget)))
        .toList();
    expect(tileSizes.every((size) => size == tileSizes.first), isTrue);
    final positions = informationTiles
        .evaluate()
        .map((element) => tester.getTopLeft(find.byWidget(element.widget)))
        .toList();
    expect(positions[0].dy, positions[1].dy);
    expect(positions[2].dy, positions[3].dy);
    expect(positions[0].dx, positions[2].dx);
    expect(positions[1].dx, positions[3].dx);
    final ledgerCards = tester
        .widgetList<CustomerProfileLedgerCard>(
            find.byType(CustomerProfileLedgerCard))
        .toList();
    expect(ledgerCards, hasLength(3));
    final heights =
        tester.getSize(find.byType(CustomerProfileLedgerCard).first).height;
    for (final card in find.byType(CustomerProfileLedgerCard).evaluate()) {
      expect(tester.getSize(find.byWidget(card.widget)).height, heights);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('WhatsApp replaces repeated name without changing the grid',
      (tester) async {
    await _pumpProfile(tester, const Size(1280, 900),
        profile: _profile.copyWith(whatsapp: '9304479436'));

    expect(find.byType(CustomerProfileInformationTile), findsNWidgets(4));
    expect(find.text('WhatsApp Number'), findsOneWidget);
    expect(find.text('Customer Name'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile remains usable in a compact window', (tester) async {
    await _pumpProfile(tester, const Size(390, 820));
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Invoice History').last);
    await tester.pump();
    await tester.ensureVisible(find.text('Due Bills (1)'));
    await tester.pump();
    await tester.tap(find.text('Due Bills (1)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('INV-001'), findsOneWidget);
    expect(find.text('INV-002'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Active Girvi (1)'));
    await tester.pump();
    await tester.tap(find.text('Active Girvi (1)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('GRV-001'), findsOneWidget);
    expect(find.text('GRV-CLOSED'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Active Advances (1)'));
    await tester.pump();
    await tester.tap(find.text('Active Advances (1)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('ADV-001'), findsOneWidget);
    expect(find.text('ADV-DONE'), findsNothing);
    expect(find.text('Advance payment progress'), findsNothing);
    expect(find.text('Convert to Sale'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty activity hides irrelevant overview and ledger cards',
      (tester) async {
    await _pumpProfile(tester, const Size(900, 760),
        profile: CustomerProfileModel(
          id: 2,
          name: 'New Customer',
          mobile: '',
          type: 'Regular',
          createdAt: DateTime(2026, 10, 1),
          initials: 'NC',
        ));

    expect(find.text('Total Sales Bills'), findsOneWidget);
    expect(find.text('Active Girvi'), findsNothing);
    expect(find.text('Active Advance Orders'), findsNothing);
    expect(find.text('Account Ledgers'), findsNothing);
    expect(find.text('Pending Dues'), findsNothing);
    expect(find.textContaining('Sales Bills ('), findsNothing);
    expect(find.textContaining('Due Bills ('), findsNothing);
    expect(find.text('No account activity yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settled due disappears from tabs while sales history remains',
      (tester) async {
    final settled = CustomerBillModel(
      id: 1,
      billNo: 'INV-001',
      totalAmount: 1000,
      paidAmount: 1000,
      status: 'PAID',
      billDate: DateTime(2026, 8, 10),
    );
    await _pumpProfile(
      tester,
      const Size(1280, 900),
      profile: _profile.copyWith(bills: [settled], dues: []),
    );

    expect(find.text('Sales Bills (1)'), findsOneWidget);
    expect(find.textContaining('Due Bills ('), findsNothing);
    expect(find.text('Active Girvi (1)'), findsOneWidget);
    expect(find.text('Active Advances (1)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active Girvi shows recorded interest and relevant actions',
      (tester) async {
    final loan = CustomerLoanModel(
      id: 1,
      loanNo: 'GRV-001',
      itemDesc: 'Gold ring',
      grossWeight: 10,
      loanAmount: 25000,
      interestRate: 2,
      startDate: DateTime(2026, 8, 12),
      status: 'ACTIVE',
      isManagedGirvi: true,
      interestPaymentCount: 1,
      lastInterestPaymentAt: DateTime(2026, 10, 29),
    );
    await _pumpProfile(
      tester,
      const Size(1280, 900),
      profile: _profile.copyWith(loans: [loan]),
    );
    await tester.ensureVisible(find.text('Active Girvi (1)'));
    await tester.tap(find.text('Active Girvi (1)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Interest activity · 1 payment'), findsOneWidget);
    expect(find.text('Last paid 29 Oct 2026'), findsOneWidget);
    await tester.tap(find.text('GRV-001'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Open Girvi Account'), findsOneWidget);
    expect(find.text('Record Interest Payment'), findsOneWidget);
    expect(find.text('Edit Girvi Ticket'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editable Girvi ticket opens its edit callback', (tester) async {
    final loan = CustomerLoanModel(
      id: 42,
      loanNo: 'GRV-DRAFT-42',
      itemDesc: 'Gold chain',
      grossWeight: 8,
      loanAmount: 18000,
      interestRate: 2,
      startDate: DateTime(2026, 10, 29),
      status: 'ACTIVE',
      isManagedGirvi: true,
      canEditGirvi: true,
    );
    int? openedLoanId;
    await _pumpProfile(
      tester,
      const Size(1280, 900),
      profile: _profile.copyWith(loans: [loan]),
      onEditGirvi: (loanId) => openedLoanId = loanId,
    );
    await tester.ensureVisible(find.text('Active Girvi (1)'));
    await tester.tap(find.text('Active Girvi (1)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(find.text('GRV-DRAFT-42'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Edit Girvi Ticket'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(openedLoanId, 42);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active advance opens booking cancellation in the desk',
      (tester) async {
    String? selectedOrderNo;
    int? selectedCustomerId;
    await _pumpProfile(
      tester,
      const Size(1280, 900),
      onCancelAdvance: (orderNo, customerId) {
        selectedOrderNo = orderNo;
        selectedCustomerId = customerId;
      },
    );
    await tester.ensureVisible(find.text('Active Advances (1)'));
    await tester.pump();
    await tester.tap(find.text('Active Advances (1)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(find.text('ADV-001'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.scrollUntilVisible(
      find.text('Cancel Advance Order'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Cancel Advance Order'));
    await tester.pump();

    expect(selectedOrderNo, 'ADV-001');
    expect(selectedCustomerId, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing customer ID replaces the displayed profile',
      (tester) async {
    final repository = _ProfileRepository(_profile);
    await tester.pumpWidget(MaterialApp(
      home: CustomerProfileScreen(
        customerId: 1,
        repository: repository,
        onBack: () {},
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Reyansh Soni'), findsWidgets);

    final nextProfile = CustomerProfileModel(
      id: 2,
      name: 'Second Customer',
      mobile: '9000000000',
      createdAt: DateTime(2026, 10, 1),
      initials: 'SC',
    );
    repository.result = nextProfile;
    await tester.pumpWidget(MaterialApp(
      home: CustomerProfileScreen(
        customerId: 2,
        repository: repository,
        onBack: () {},
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Second Customer'), findsWidgets);
    expect(find.text('Reyansh Soni'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpProfile(WidgetTester tester, Size size,
    {CustomerProfileModel? profile,
    Function(int)? onEditGirvi,
    Function(String, int)? onCancelAdvance}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    home: CustomerProfileScreen(
      customerId: 1,
      repository: _ProfileRepository(profile ?? _profile),
      onBack: () {},
      onEditGirvi: onEditGirvi,
      onCancelAdvance: onCancelAdvance,
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

final _profile = CustomerProfileModel(
  id: 1,
  name: 'Reyansh Soni',
  mobile: '9304479436',
  city: 'Patna',
  addressLine1: 'Main Road',
  state: 'Bihar',
  pincode: '800001',
  type: 'Regular',
  createdAt: DateTime(2026, 8, 9),
  initials: 'RS',
  outstanding: 500,
  bills: [
    CustomerBillModel(
      id: 1,
      billNo: 'INV-001',
      totalAmount: 1000,
      paidAmount: 500,
      status: 'PARTIAL',
      billDate: DateTime(2026, 8, 10),
    ),
    CustomerBillModel(
      id: 2,
      billNo: 'INV-002',
      totalAmount: 1200,
      paidAmount: 1200,
      status: 'PAID',
      billDate: DateTime(2026, 8, 11),
    ),
  ],
  dues: [
    CustomerDueModel(
      billId: 1,
      billNo: 'INV-001',
      totalAmount: 1000,
      paidAmount: 500,
      billDate: DateTime(2026, 8, 10),
    ),
  ],
  loans: [
    CustomerLoanModel(
      id: 1,
      loanNo: 'GRV-001',
      itemDesc: 'Gold ring',
      grossWeight: 10,
      loanAmount: 25000,
      originalPrincipalAmount: 30000,
      principalOutstandingAmount: 25000,
      interestRate: 2,
      startDate: DateTime(2026, 8, 12),
      status: 'ACTIVE',
      recordedInterestOutstanding: 1000,
    ),
    CustomerLoanModel(
      id: 2,
      loanNo: 'GRV-CLOSED',
      itemDesc: 'Gold chain',
      grossWeight: 8,
      loanAmount: 18000,
      interestRate: 2,
      startDate: DateTime(2026, 7, 1),
      status: 'RELEASED',
    ),
  ],
  advanceOrders: [
    CustomerAdvanceOrderModel(
      id: 1,
      orderNo: 'ADV-001',
      itemName: 'Ring',
      metalType: 'Gold',
      purity: '22K',
      approxWeight: 5,
      lockedRate: 6000,
      bookingType: 'LOCKED',
      status: AdvanceOrderStatus.pending,
      totalAdvancePaid: 5000,
      estimatedTotal: 30000,
      createdAt: DateTime(2026, 8, 13),
    ),
    CustomerAdvanceOrderModel(
      id: 2,
      orderNo: 'ADV-DONE',
      itemName: 'Pendant',
      metalType: 'Gold',
      purity: '22K',
      approxWeight: 3,
      lockedRate: 6000,
      bookingType: 'LOCKED',
      status: AdvanceOrderStatus.delivered,
      totalAdvancePaid: 18000,
      estimatedTotal: 18000,
      createdAt: DateTime(2026, 7, 15),
    ),
  ],
);

class _ProfileRepository extends CustomerProfileRepository {
  _ProfileRepository(this.result);

  CustomerProfileModel result;

  @override
  Future<CustomerProfileModel?> fetchProfile(int customerId) async => result;
}
