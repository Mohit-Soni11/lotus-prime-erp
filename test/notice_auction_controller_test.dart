import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/girvi/notice_auction_controller.dart';
import 'package:lotus_erp/models/girvi/girvi_loan_model.dart';
import 'package:lotus_erp/models/girvi/girvi_notice_action_model.dart';
import 'package:lotus_erp/models/girvi/notice_auction_model.dart';

void main() {
  group('NoticeAuctionController', () {
    test('dispose does not close the app database connection', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final controller = NoticeAuctionController(db: db);
      controller.dispose();

      await db.into(db.customers).insert(
            CustomersCompanion.insert(
              name: 'Girvi Customer',
              mobile: '9000000000',
            ),
          );

      final customers = await db.select(db.customers).get();

      expect(customers, hasLength(1));
      expect(customers.single.name, 'Girvi Customer');
    });

    test('case shows next notice stage and calendar age in months and days',
        () {
      final now = DateTime(2026, 6, 24);
      final account = GirviLoanWithCustomer(
        loan: GirviLoanModel(
          id: 16,
          ticketNo: 'GRV-0016',
          customerId: 1,
          itemDescription: '#1 ring | Gold | 18KT | 1 pcs | Net 4.000 g',
          itemCount: 1,
          metalType: 'Gold',
          metalPurity: '18KT',
          grossWeight: 4,
          stoneWeight: 0,
          netWeight: 4,
          ratePerGram: 12000,
          totalValue: 31200,
          ltvPercent: 38.46,
          loanAmount: 12000,
          interestRate: 5,
          durationMonths: 6,
          disbursementMode: 'Cash',
          startDate: DateTime(2025, 3, 10),
          maturityDate: DateTime(2025, 9, 10),
          createdAt: DateTime(2025, 3, 10),
          status: 'OVERDUE',
        ),
        customerName: 'REYANSH SONI',
        customerMobile: '9304479436',
      );

      final freshCase = NoticeAuctionCase(
        account: account,
        noticePeriodDays: 30,
        now: now,
      );

      expect(freshCase.noticeProgressLabel, '1/3');
      expect(freshCase.loanAgeMonthsDaysLabel, '15 months 14 days');
      expect(freshCase.overdueAgeMonthsDaysLabel, '9 months 14 days');

      final afterFirstNotice = NoticeAuctionCase(
        account: account,
        noticePeriodDays: 30,
        now: now,
        actionHistory: [
          GirviNoticeAction(
            id: 1,
            girviId: account.loan.id,
            actionType: GirviNoticeType.first.actionType,
            noticeStage: 1,
            actionAt: now,
            createdAt: now,
          ),
        ],
      );

      expect(afterFirstNotice.noticeProgressLabel, '2/3');
    });
  });
}
