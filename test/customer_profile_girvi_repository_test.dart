import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/repositories/customer/customer_profile_repository.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('customer profile reads saved Girvi records from girviLoans', () async {
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: 'Test Customer',
            mobile: '9999999999',
          ),
        );

    await db.into(db.girviLoans).insert(
          GirviLoansCompanion.insert(
            ticketNo: 'GRV/2026/00001',
            customerId: customerId,
            itemDescription: 'Gold ring',
            grossWeight: const Value(8.25),
            loanAmount: const Value(25000),
            interestRate: const Value(2),
            startDate: Value(DateTime(2026, 6, 9)),
          ),
        );
    await db.into(db.loans).insert(
          LoansCompanion.insert(
            loanNo: 'OLD/2025/00001',
            customerId: customerId,
            itemDesc: 'Legacy chain',
            startDate: Value(DateTime(2025, 6, 9)),
          ),
        );

    final profile =
        await CustomerProfileRepository(db: db).fetchProfile(customerId);

    expect(profile == null, isFalse);
    expect(profile!.loans, hasLength(2));
    expect(profile.loans.first.loanNo, 'GRV/2026/00001');
    expect(profile.loans.first.itemDesc, 'Gold ring');
    expect(profile.loans.first.loanAmount, 25000);
    expect(profile.loans.last.loanNo, 'OLD/2025/00001');
    expect(profile.activeLoans, 2);
  });
}
