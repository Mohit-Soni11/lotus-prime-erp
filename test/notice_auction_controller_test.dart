import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/girvi/notice_auction_controller.dart';
import 'package:lotus_erp/models/girvi/girvi_loan_model.dart';
import 'package:lotus_erp/models/girvi/girvi_notice_action_model.dart';
import 'package:lotus_erp/models/girvi/notice_auction_model.dart';
import 'package:lotus_erp/repositories/girvi/girvi_notice_action_repository.dart';

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
      expect(freshCase.noticesSentLabel, '0/3 Sent');
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
      expect(afterFirstNotice.stage, NoticeAuctionStage.firstNoticeDue);
      expect(afterFirstNotice.noticesSentLabel, '1/3 Sent');
      expect(afterFirstNotice.preparedNoticeActions, hasLength(1));
      expect(afterFirstNotice.preparedNoticeActions.single.noticeStage, 1);

      final afterSecondNotice = NoticeAuctionCase(
        account: account,
        noticePeriodDays: 30,
        now: now,
        actionHistory: [
          GirviNoticeAction(
            id: 2,
            girviId: account.loan.id,
            actionType: GirviNoticeType.second.actionType,
            noticeStage: 2,
            actionAt: now,
            createdAt: now,
          ),
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

      expect(afterSecondNotice.stage, NoticeAuctionStage.secondNoticeDue);
      expect(afterSecondNotice.noticeProgressLabel, '3/3');
      expect(afterSecondNotice.noticesSentLabel, '2/3 Sent');

      final finalNoticeOnly = NoticeAuctionCase(
        account: account,
        noticePeriodDays: 30,
        now: now,
        actionHistory: [
          GirviNoticeAction(
            id: 3,
            girviId: account.loan.id,
            actionType: GirviNoticeType.finalNotice.actionType,
            noticeStage: 3,
            actionAt: now,
            createdAt: now,
          ),
        ],
      );

      expect(finalNoticeOnly.stage, NoticeAuctionStage.finalNoticeDue);
      expect(finalNoticeOnly.nextNoticeType, isNull);
      expect(finalNoticeOnly.canCloseDisposal, isFalse);

      final disposalReadyCase = NoticeAuctionCase(
        account: account,
        noticePeriodDays: 30,
        now: now,
        actionHistory: [
          GirviNoticeAction(
            id: 3,
            girviId: account.loan.id,
            actionType: GirviNoticeType.finalNotice.actionType,
            noticeStage: 3,
            actionAt: now.subtract(const Duration(days: 30)),
            createdAt: now.subtract(const Duration(days: 30)),
          ),
        ],
      );

      expect(disposalReadyCase.stage, NoticeAuctionStage.disposalReady);
      expect(disposalReadyCase.canCloseDisposal, isTrue);

      final closedAfterThreeNotices = NoticeAuctionCase(
        account: account,
        noticePeriodDays: 30,
        now: now,
        actionHistory: [
          GirviNoticeAction(
            id: 4,
            girviId: account.loan.id,
            actionType: GirviNoticeActionTypes.disposalSettled,
            actionAt: now,
            createdAt: now,
          ),
          for (final noticeType in GirviNoticeType.values)
            GirviNoticeAction(
              id: noticeType.stage,
              girviId: account.loan.id,
              actionType: noticeType.actionType,
              noticeStage: noticeType.stage,
              actionAt: now,
              createdAt: now,
            ),
        ],
      );

      expect(closedAfterThreeNotices.stage, NoticeAuctionStage.settled);
      expect(closedAfterThreeNotices.noticeProgressLabel, 'Closed');
      expect(closedAfterThreeNotices.noticesSentLabel, '3/3 Sent');
      expect(
        closedAfterThreeNotices.preparedNoticeActions
            .map((action) => action.noticeStage)
            .toList(),
        [1, 2, 3],
      );

      final legacyDraftNotice = NoticeAuctionCase(
        account: account,
        noticePeriodDays: 30,
        now: now,
        actionHistory: [
          GirviNoticeAction(
            id: 5,
            girviId: account.loan.id,
            actionType: GirviNoticeActionTypes.noticeDraftCopied,
            actionAt: now,
            createdAt: now,
          ),
        ],
      );

      expect(legacyDraftNotice.noticesSentLabel, '1/3 Sent');
      expect(legacyDraftNotice.preparedNoticeActions, hasLength(1));

      final state = NoticeAuctionState.initial().copyWith(
        allCases: [
          freshCase,
          afterFirstNotice,
          afterSecondNotice,
          finalNoticeOnly,
          disposalReadyCase,
          closedAfterThreeNotices,
        ],
      );

      expect(state.countForFilter(NoticeAuctionFilter.all), 5);
      expect(state.countForFilter(NoticeAuctionFilter.firstNotice), 2);
      expect(state.countForFilter(NoticeAuctionFilter.secondNotice), 1);
      expect(state.countForFilter(NoticeAuctionFilter.finalNotice), 1);
      expect(state.countForFilter(NoticeAuctionFilter.disposalReady), 1);
      expect(state.countForFilter(NoticeAuctionFilter.settled), 1);
    });

    test('notice delivery proof persists without changing notice stage count',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final customerId = await db.into(db.customers).insert(
            CustomersCompanion.insert(
              name: 'Notice Customer',
              mobile: '9000000002',
            ),
          );
      final loanId = await db.into(db.girviLoans).insert(
            GirviLoansCompanion.insert(
              ticketNo: 'GRV-NOT-001',
              customerId: customerId,
              itemDescription: 'Gold ring',
              grossWeight: const drift.Value(6),
              netWeight: const drift.Value(6),
              ratePerGram: const drift.Value(7000),
              totalValue: const drift.Value(42000),
              loanAmount: const drift.Value(20000),
              interestRate: const drift.Value(5),
              startDate: drift.Value(DateTime(2025, 9, 9)),
              maturityDate: drift.Value(DateTime(2026, 3, 9)),
              status: const drift.Value('OVERDUE'),
            ),
          );

      final repository = GirviNoticeActionRepository(db);
      await repository.recordNoticePrepared(
        girviId: loanId,
        noticeType: GirviNoticeType.first,
        noticeText: 'First notice text',
      );
      await repository.recordNoticeDeliveryProof(
        girviId: loanId,
        noticeType: GirviNoticeType.first,
        noticeText: 'First notice text',
        actionType: GirviNoticeActionTypes.noticePdfSaved,
        deliveryChannel: 'PDF File',
        deliveryStatus: 'Saved',
        deliveryReference: r'C:\notice\GRV-NOT-001.pdf',
      );

      final history = (await repository.actionsByGirviIds([loanId]))[loanId]!;
      final proof =
          history.firstWhere((action) => action.isNoticeDeliveryProof);
      expect(proof.deliveryStatus, 'Saved');
      expect(proof.deliveryChannel, 'PDF File');
      expect(proof.deliveryReference, r'C:\notice\GRV-NOT-001.pdf');

      final account = GirviLoanWithCustomer(
        loan: GirviLoanModel(
          id: loanId,
          ticketNo: 'GRV-NOT-001',
          customerId: customerId,
          itemDescription: 'Gold ring',
          itemCount: 1,
          metalType: 'Gold',
          metalPurity: '18KT',
          grossWeight: 6,
          stoneWeight: 0,
          netWeight: 6,
          ratePerGram: 7000,
          totalValue: 42000,
          ltvPercent: 47.61,
          loanAmount: 20000,
          interestRate: 5,
          durationMonths: 6,
          disbursementMode: 'Cash',
          startDate: DateTime(2025, 9, 9),
          maturityDate: DateTime(2026, 3, 9),
          createdAt: DateTime(2025, 9, 9),
          status: 'OVERDUE',
        ),
        customerName: 'Notice Customer',
        customerMobile: '9000000002',
      );
      final noticeCase = NoticeAuctionCase(
        account: account,
        noticePeriodDays: 30,
        now: DateTime(2026, 6, 24),
        actionHistory: history,
      );

      expect(noticeCase.noticesSentLabel, '1/3 Sent');
      expect(noticeCase.preparedNoticeActions, hasLength(1));
      expect(noticeCase.noticeDeliveryProofActions, hasLength(1));
      expect(
        noticeCase.latestDeliveryProofForStage(1)?.deliveryProofLabel,
        'Saved via PDF File',
      );
    });

    test('notice schema safety upgrades a legacy action table', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await db.customStatement('DROP TABLE IF EXISTS girvi_notice_actions');
      await db.customStatement('''
        CREATE TABLE girvi_notice_actions (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          girvi_id INTEGER NOT NULL,
          action_type TEXT NOT NULL,
          notice_text TEXT,
          action_note TEXT,
          action_at INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER
        )
      ''');

      await db.ensureGirviNoticeActionSchema();

      final columns = await db
          .customSelect(
            "PRAGMA table_info('girvi_notice_actions')",
          )
          .get();
      final names = columns.map((row) => row.data['name']).toSet();

      expect(names, contains('notice_stage'));
      expect(names, contains('pledged_valuation'));
      expect(names, contains('delivery_channel'));
      expect(names, contains('delivery_status'));
      expect(names, contains('delivery_reference'));
      expect(names, contains('delivered_at'));
    });
  });
}
