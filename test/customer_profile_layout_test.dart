import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/customer/customer_profile/customer_profile_model.dart';
import 'package:lotus_erp/repositories/customer/customer_profile_repository.dart';
import 'package:lotus_erp/ui/customer/customer_profile/customer_profile_screen.dart';

void main() {
  testWidgets(
      'profile shows full address, matching tier and smart account cards',
      (tester) async {
    await _pumpProfile(tester, const Size(1280, 900));

    expect(find.text('Standard Customer'), findsWidgets);
    expect(find.text('Full Address'), findsOneWidget);
    expect(find.text('Main Road, Patna, Bihar, 800001'), findsWidgets);
    expect(find.text('Total Sales Bills'), findsOneWidget);
    expect(find.text('Due Invoices'), findsWidgets);
    expect(find.text('Girvi Tickets'), findsWidgets);
    expect(find.text('Active Girvi'), findsOneWidget);
    expect(find.text('Open Advance Orders'), findsOneWidget);
    expect(find.text('Total Capital Given'), findsOneWidget);
    expect(find.text('Active Capital'), findsOneWidget);
    expect(find.text('Active Interest Due'), findsOneWidget);
    expect(find.text('Settled Bills'), findsNothing);
    expect(find.textContaining('Credit Limit'), findsNothing);
    expect(find.textContaining('Account Credit'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile remains usable in a compact window', (tester) async {
    await _pumpProfile(tester, const Size(390, 820));
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Transaction History').last);
    await tester.pump();
    await tester.ensureVisible(find.text('Girvi Tickets (1)'));
    await tester.pump();
    await tester.tap(find.text('Girvi Tickets (1)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('GRV-001'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Advance Orders (1)'));
    await tester.pump();
    await tester.tap(find.text('Advance Orders (1)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('ADV-001'), findsOneWidget);
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
    expect(find.text('Open Advance Orders'), findsNothing);
    expect(find.text('Account Ledgers'), findsNothing);
    expect(find.text('Pending Dues'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpProfile(WidgetTester tester, Size size,
    {CustomerProfileModel? profile}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    home: CustomerProfileScreen(
      customerId: 1,
      repository: _ProfileRepository(profile ?? _profile),
      onBack: () {},
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
  ],
);

class _ProfileRepository extends CustomerProfileRepository {
  _ProfileRepository(this.result);

  final CustomerProfileModel result;

  @override
  Future<CustomerProfileModel?> fetchProfile(int customerId) async => result;
}
