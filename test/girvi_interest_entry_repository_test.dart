import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/girvi/girvi_controllers.dart';
import 'package:lotus_erp/logic/girvi/girvi_notice_generation_service.dart';
import 'package:lotus_erp/logic/girvi/girvi_notice_pdf_service.dart';
import 'package:lotus_erp/logic/girvi/interest_entry/girvi_ledger_balance_service.dart';
import 'package:lotus_erp/logic/girvi/notice_pdf/notice_statement_data.dart';
import 'package:lotus_erp/models/girvi/contact_recovery_model.dart';
import 'package:lotus_erp/models/girvi/girvi_enums.dart';
import 'package:lotus_erp/models/girvi/girvi_invoice_branding.dart';
import 'package:lotus_erp/models/girvi/girvi_loan_model.dart';
import 'package:lotus_erp/models/girvi/girvi_notice_action_model.dart';
import 'package:lotus_erp/models/setting/billing_setup/girvi_billing_model.dart';
import 'package:lotus_erp/repositories/girvi/girvi_repository.dart';
import 'package:lotus_erp/repositories/girvi/girvi_interest_period_snapshot_repository.dart';
import 'package:lotus_erp/repositories/setting/billing_setup/girvi_billing_repo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late GirviRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = GirviRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('records interest payment with receipt and paid-through date', () async {
    final loanId = await _insertLoan(db);
    final receiptNo = await repository.generateNextPaymentReceiptNo();
    final periodFrom = DateTime(2026, 1, 1);
    final periodTo = DateTime(2026, 2, 1);

    final paymentId = await repository.recordInterestLedgerPayment(
      loanId: loanId,
      paymentMode: GirviPaymentMode.cash,
      amount: 2500,
      paymentDate: periodTo,
      monthsCovered: 1,
      interestFromDate: periodFrom,
      interestToDate: periodTo,
      receiptNo: receiptNo,
      notes: 'January interest received',
    );

    final payments = await repository.getPaymentModelsForLoan(loanId);
    final loan = await repository.getLoanById(loanId);

    expect(paymentId, isPositive);
    expect(receiptNo, 'GIP-00001');
    expect(payments, hasLength(1));
    expect(payments.single.receiptNo, 'GIP-00001');
    expect(payments.single.amount, 2500);
    expect(payments.single.monthsCovered, 1);
    expect(payments.single.balanceAfter, 50000);
    expect(loan!.loanAmount, 50000);
    expect(loan.lastInterestPaidDate, periodTo);
  });

  test('rejects interest payments outside the pledge dates or after settlement',
      () async {
    final loanId = await _insertLoan(db);

    Future<int> collectOn(DateTime date) =>
        repository.recordInterestLedgerPayment(
          loanId: loanId,
          paymentMode: GirviPaymentMode.cash,
          amount: 500,
          paymentDate: date,
        );

    await expectLater(collectOn(DateTime(2025, 12, 31)), throwsArgumentError);
    await expectLater(
      collectOn(DateTime.now().add(const Duration(days: 2))),
      throwsArgumentError,
    );
    await (db.update(db.girviLoans)..where((row) => row.id.equals(loanId)))
        .write(GirviLoansCompanion(
      status: drift.Value(GirviStatus.readyForDelivery.dbValue),
    ));
    await expectLater(collectOn(DateTime.now()), throwsStateError);
    expect(await repository.getPaymentsForLoan(loanId), isEmpty);
  });

  test('converts a saved simple timeline after month 12 automatically',
      () async {
    final loanId = await _insertLoan(
      db,
      startDate: DateTime(2025, 1, 1),
    );
    await db.update(db.girviLoans).write(const GirviLoansCompanion(
        interestCalculationType: drift.Value('Simple')));

    await GirviBillingRepo(db: db).save(
      GirviBillingModel.defaults.copyWith(interestType: 'Compound'),
    );
    final timeline = GirviInterestPeriodSnapshotRepository(db);
    final accounts = await repository.getLoansWithCustomer();
    final snapshots = await timeline.synchronizeForLoans(
      accounts,
      asOf: DateTime(2026, 1, 1),
    );

    expect(snapshots[loanId], hasLength(1));
    expect(snapshots[loanId]!.single.interestType, 'Simple');
    expect(snapshots[loanId]!.single.chargeableMonths, 12);
    expect(snapshots[loanId]!.single.interestPerMonth, 2500);
    expect(snapshots[loanId]!.single.periodInterest, 30000);

    final converted = await timeline.synchronizeForLoans(
      await repository.getLoansWithCustomer(),
      asOf: DateTime(2026, 3, 1),
    );
    expect(converted[loanId], hasLength(2));
    expect(converted[loanId]!.map((row) => row.interestType),
        everyElement('Compound'));
    expect(converted[loanId]!.map((row) => row.chargeableMonths), [12, 2]);
    expect(converted[loanId]!.map((row) => row.periodInterest), [30000, 8000]);
    expect((await repository.getLoanById(loanId))!.interestCalculationType,
        'Simple');
  });

  test('42-month legacy simple snapshot becomes compound in the next notice',
      () async {
    final asOf = DateTime(2026, 10, 17);
    final loanId = await _insertLoan(
      db,
      loanAmount: 25000,
      interestRate: 5,
      startDate: DateTime(2023, 5, 9),
    );
    await repository.updateLoan(
      loanId,
      GirviLoansCompanion(
        ticketNo: const drift.Value('GRV-0014'),
        durationMonths: const drift.Value(6),
        maturityDate: drift.Value(DateTime(2023, 11, 9)),
        interestCalculationType: const drift.Value('Simple'),
      ),
    );
    final timeline = GirviInterestPeriodSnapshotRepository(db);
    await timeline.synchronizeForLoans(
      await repository.getLoansWithCustomer(),
      asOf: DateTime(2024, 5, 9),
    );
    await db.customStatement('''
      UPDATE girvi_interest_period_snapshots
      SET period_to = ?, chargeable_months = 42,
          period_interest = 52500, closing_amount = 77500
      WHERE girvi_id = ?
    ''', [asOf.millisecondsSinceEpoch, loanId]);

    final old = await timeline.getForLoan(loanId);
    expect(old.single.interestType, 'Simple');
    expect(old.single.periodInterest, 52500);

    final account = (await repository.getLoansWithCustomer()).single;
    final generator = GirviNoticeGenerationService(now: asOf);
    final oldCase = ContactRecoveryCase(
      account: account,
      noticePeriodDays: 7,
      now: asOf,
      interestPeriodSnapshots: old,
    );
    final originalApprovedText = generator.build(
      item: oldCase,
      noticeType: GirviNoticeType.formal,
      language: GirviNoticeLanguage.english,
    );
    expect(
      generator.validate(oldCase),
      contains(contains('Interest method changed at month 13')),
    );
    final refreshed = await timeline.synchronizeForLoans(
      [account],
      asOf: asOf,
    );
    final periods = refreshed[loanId]!;
    expect(
        periods.map((period) => period.interestType), everyElement('Compound'));
    expect(periods.map((period) => period.chargeableMonths), [12, 12, 12, 6]);
    expect(periods.map((period) => period.periodInterest),
        [15000, 24000, 38400, 30720]);
    expect(periods.last.closingAmount, 133120);

    final noticeCase = ContactRecoveryCase(
      account: account,
      noticePeriodDays: 7,
      now: asOf,
      interestPeriodSnapshots: periods,
    );
    expect(generator.validate(noticeCase), isEmpty);
    final notice = generator.build(
      item: noticeCase,
      noticeType: GirviNoticeType.formal,
      language: GirviNoticeLanguage.english,
    );
    expect(notice, contains('Compound Interest Breakdown'));
    expect(notice, contains('09 May 2023 to 08 May 2024'));
    expect(notice, contains('09 May 2024 to 08 May 2025'));
    expect(notice, contains('09 May 2025 to 08 May 2026'));
    expect(notice, contains('09 May 2026 to 17 October 2026'));
    expect(notice, isNot(contains('09 November 2026')));
    expect(notice, contains('Gross Interest: Rs 1,08,120'));
    expect(notice, contains('Interest Outstanding: Rs 1,08,120'));
    final approvedStatement = NoticeStatementData.parse(
      originalApprovedText,
      GirviNoticeLanguage.english,
    );
    final verifiedStatement = NoticeStatementData.parse(
      notice,
      GirviNoticeLanguage.english,
    );
    final currentView = approvedStatement.withVerifiedFinancials(
      verifiedStatement,
      asOf: asOf,
    );
    expect(approvedStatement.isSimple, isTrue);
    expect(currentView.isCompound, isTrue);
    expect(currentView.periods, hasLength(4));
    expect(currentView.totalPayable, 'Rs 1,33,120');
    final pdf = await GirviNoticePdfService().build(
      item: noticeCase,
      noticeType: GirviNoticeType.formal,
      noticeLanguage: GirviNoticeLanguage.english,
      noticeText: notice,
      branding: const GirviInvoiceBranding(
        shopName: 'Shree Jewellers',
        shopAddress: '12 Main Market, Jaipur',
        shopMobile: '9876543210',
      ),
    );
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
    final previewDirectory = Platform.environment['NOTICE_LAYOUT_PREVIEW_DIR'];
    if (previewDirectory != null && previewDirectory.isNotEmpty) {
      await Directory(previewDirectory).create(recursive: true);
      await File('$previewDirectory/notice_42_month_compound.pdf')
          .writeAsBytes(pdf);
    }
    final correctedViewPdf = await GirviNoticePdfService().buildStoredNotice(
      ticketNo: account.loan.ticketNo,
      noticeType: GirviNoticeType.formal,
      noticeLanguage: GirviNoticeLanguage.english,
      noticeText: originalApprovedText,
      savedAt: asOf,
      verifiedFinancialText: notice,
      financialAsOf: asOf,
      branding: const GirviInvoiceBranding(
        shopName: 'Shree Jewellers',
        shopAddress: '12 Main Market, Jaipur',
        shopMobile: '9876543210',
      ),
    );
    expect(String.fromCharCodes(correctedViewPdf.take(5)), '%PDF-');
    if (previewDirectory != null && previewDirectory.isNotEmpty) {
      await File('$previewDirectory/notice_42_month_corrected_view.pdf')
          .writeAsBytes(correctedViewPdf);
    }

    await repository.recordInterestLedgerPayment(
      loanId: loanId,
      paymentMode: GirviPaymentMode.cash,
      amount: 3000,
      paymentDate: asOf,
      receiptNo: 'GIP-42-MONTH-001',
    );
    final paidCase = ContactRecoveryCase(
      account: (await repository.getLoansWithCustomer()).single,
      noticePeriodDays: 7,
      now: asOf,
      paymentHistory: await repository.getPaymentModelsForLoan(loanId),
      interestPeriodSnapshots: periods,
    );
    expect(generator.validate(paidCase), isEmpty);
    final paidNotice = generator.build(
      item: paidCase,
      noticeType: GirviNoticeType.formal,
      language: GirviNoticeLanguage.english,
    );
    expect(paidNotice, contains('Interest Paid Total: Rs 3,000'));
    expect(paidNotice, contains('Interest Outstanding: Rs 1,05,120'));
    final paidPdf = await GirviNoticePdfService().build(
      item: paidCase,
      noticeType: GirviNoticeType.formal,
      noticeLanguage: GirviNoticeLanguage.english,
      noticeText: paidNotice,
      branding: const GirviInvoiceBranding(
        shopName: 'Shree Jewellers',
        shopAddress: '12 Main Market, Jaipur',
        shopMobile: '9876543210',
      ),
    );
    expect(String.fromCharCodes(paidPdf.take(5)), '%PDF-');
    final paidPreviewDirectory =
        Platform.environment['NOTICE_PAID_PREVIEW_DIR'];
    if (paidPreviewDirectory != null && paidPreviewDirectory.isNotEmpty) {
      await Directory(paidPreviewDirectory).create(recursive: true);
      await File('$paidPreviewDirectory/notice_42_month_compound_paid.pdf')
          .writeAsBytes(paidPdf);
    }
  });

  test('notice timeline recalculates completed years after dated payment',
      () async {
    final loanId = await _insertLoan(
      db,
      loanAmount: 100000,
      interestRate: 1,
      startDate: DateTime(2025, 1, 1),
    );
    final timeline = GirviInterestPeriodSnapshotRepository(db);
    final before = await timeline.synchronizeForLoans(
      await repository.getLoansWithCustomer(),
      asOf: DateTime(2026, 2, 1),
    );
    expect(
        before[loanId]!.map((period) => period.periodInterest), [12000, 1120]);

    await repository.recordInterestLedgerPayment(
      loanId: loanId,
      paymentMode: GirviPaymentMode.cash,
      amount: 12000,
      paymentDate: DateTime(2026, 1, 1),
    );
    final after = await timeline.synchronizeForLoans(
      await repository.getLoansWithCustomer(),
      asOf: DateTime(2026, 2, 1),
    );
    expect(
        after[loanId]!.map((period) => period.periodInterest), [12000, 1000]);
    expect(
        after[loanId]!.map((period) => period.closingAmount), [100000, 101000]);
    expect(
        after[loanId]!
            .every((period) => period.source == 'DATED_UNPAID_INTEREST_POLICY'),
        isTrue);
  });

  test('records interest ledger payment with paid-through period', () async {
    final loanId = await _insertLoan(
      db,
      startDate: DateTime(2025, 2, 9),
    );

    final paymentId = await repository.recordInterestLedgerPayment(
      loanId: loanId,
      paymentMode: GirviPaymentMode.cash,
      amount: 20000,
      paymentDate: DateTime(2026, 6, 17),
      monthsCovered: 5,
      receiptNo: 'GIP-LEDGER-001',
      notes: 'Running interest ledger payment',
    );

    final payments = await repository.getPaymentModelsForLoan(loanId);
    final loan = await repository.getLoanById(loanId);
    final loansWithCustomer = await repository.getLoansWithCustomer();

    expect(paymentId, isPositive);
    expect(payments, hasLength(1));
    expect(payments.single.type, GirviPaymentType.interest);
    expect(payments.single.amount, 20000);
    expect(payments.single.monthsCovered, 8);
    expect(payments.single.interestFromDate, DateTime(2025, 2, 9));
    expect(payments.single.interestToDate, DateTime(2025, 10, 9));
    expect(payments.single.balanceAfter, 50000);
    expect(loan!.lastInterestPaidDate, DateTime(2025, 10, 9));
    expect(loansWithCustomer.single.interestPaidTotal, 20000);

    final ledgerSnapshot = GirviLoanWithCustomer(
      loan: _loanModel(
        loanAmount: 50000,
        interestRate: 5,
        startDate: DateTime(2025, 2, 9),
        releaseDate: DateTime(2026, 6, 17),
      ),
      customerName: 'Interest Entry Customer',
      customerMobile: '9999999999',
      interestPaidTotal: 20000,
      interestAdjustments: [
        GirviInterestAdjustment(date: DateTime(2026, 6, 17), paid: 20000),
      ],
    );

    expect(ledgerSnapshot.grossInterestAccrued, 50000);
    expect(ledgerSnapshot.netInterestDue, 30000);
    expect(ledgerSnapshot.advanceInterestCredit, 0);
    expect(ledgerSnapshot.totalPayable, 80000);
  });

  test('allocates extra interest collection as future interest credit',
      () async {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 5));
    final loanId = await _insertLoan(
      db,
      loanAmount: 10200,
      interestRate: 5,
      startDate: startDate,
    );

    await repository.recordInterestLedgerPayment(
      loanId: loanId,
      paymentMode: GirviPaymentMode.cash,
      amount: 510,
      paymentDate: now,
      monthsCovered: 1,
      receiptNo: 'GIP-INT-001',
    );
    await repository.recordInterestLedgerPayment(
      loanId: loanId,
      paymentMode: GirviPaymentMode.cash,
      amount: 510,
      paymentDate: now,
      receiptNo: 'GIP-ADV-001',
    );

    final loan = await repository.getLoanById(loanId);
    final payments = await repository.getPaymentModelsForLoan(loanId);
    final joined =
        (await repository.getLoansWithCustomer(loanId: loanId)).single;

    expect(loan!.loanAmount, 10200);
    expect(payments, hasLength(2));
    final advancePayment =
        payments.singleWhere((payment) => payment.receiptNo == 'GIP-ADV-001');
    expect(advancePayment.amount, 510);
    expect(advancePayment.interestComponent, 510);
    expect(advancePayment.principalComponent, 0);
    expect(advancePayment.monthsCovered, 1);
    expect(advancePayment.balanceAfter, 10200);
    expect(joined.originalPrincipal, 10200);
    expect(joined.interestPaidTotal, 1020);
    expect(joined.principalDue, 10200);
    expect(joined.advanceInterestCredit, greaterThan(0));
  });

  test('repairs no-period interest overpayment into interest credit', () async {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 5));
    final loanId = await _insertLoan(
      db,
      loanAmount: 10200,
      interestRate: 5,
      startDate: startDate,
    );

    await db.into(db.girviPayments).insert(
          GirviPaymentsCompanion.insert(
            girviId: loanId,
            paymentType: GirviPaymentType.interest.dbValue,
            paymentDate: drift.Value(now),
            amount: const drift.Value(510),
            paymentMode: drift.Value(GirviPaymentMode.cash.dbValue),
            monthsCovered: const drift.Value(1),
            balanceAfter: const drift.Value(10200),
            receiptNo: const drift.Value('GIP-OLD-INT'),
          ),
        );
    await db.into(db.girviPayments).insert(
          GirviPaymentsCompanion.insert(
            girviId: loanId,
            paymentType: GirviPaymentType.interest.dbValue,
            paymentDate: drift.Value(now),
            amount: const drift.Value(500),
            paymentMode: drift.Value(GirviPaymentMode.cash.dbValue),
            balanceAfter: const drift.Value(10200),
            receiptNo: const drift.Value('GIP-OLD-ADV'),
          ),
        );

    await repository.syncSettlementStatus();

    final loan = await repository.getLoanById(loanId);
    final payments = await repository.getPaymentModelsForLoan(loanId);
    final repaired =
        payments.singleWhere((payment) => payment.receiptNo == 'GIP-OLD-ADV');
    final joined =
        (await repository.getLoansWithCustomer(loanId: loanId)).single;

    expect(loan!.loanAmount, 10200);
    expect(repaired.interestComponent, 500);
    expect(repaired.principalComponent, 0);
    expect(repaired.balanceAfter, 10200);
    expect(joined.originalPrincipal, 10200);
    expect(joined.interestPaidTotal, 1010);
    expect(joined.principalDue, 10200);
  });

  test('normalizes payment amount and rejects duplicate receipt refs',
      () async {
    final loanId = await _insertLoan(db);

    await repository.recordInterestLedgerPayment(
      loanId: loanId,
      paymentMode: GirviPaymentMode.cash,
      amount: 123.456,
      paymentDate: DateTime(2026, 6, 19),
      receiptNo: '  GIP-UNIQ-001  ',
    );

    final payment = (await repository.getPaymentModelsForLoan(loanId)).single;
    expect(payment.amount, 123.46);
    expect(payment.receiptNo, 'GIP-UNIQ-001');

    expect(
      () => repository.recordInterestLedgerPayment(
        loanId: loanId,
        paymentMode: GirviPaymentMode.cash,
        amount: 10,
        paymentDate: DateTime(2026, 6, 20),
        receiptNo: 'GIP-UNIQ-001',
      ),
      throwsA(anything),
    );
  });

  test('ledger summary uses payment-adjusted principal and interest due',
      () async {
    final now = DateTime.now();
    final loanId = await _insertLoan(
      db,
      loanAmount: 10000,
      interestRate: 5,
      startDate: now.subtract(const Duration(days: 3)),
    );

    await _seedHistoricalPrincipalPayment(
      db,
      loanId: loanId,
      amount: 2500,
      paymentDate: now,
      receiptNo: 'GIP-PRN-001',
    );
    await repository.recordInterestLedgerPayment(
      loanId: loanId,
      paymentMode: GirviPaymentMode.cash,
      amount: 200,
      paymentDate: now,
      receiptNo: 'GIP-INT-SUM-001',
    );

    final summary = await repository.getSummary();

    expect(summary.totalActive, 1);
    expect(summary.totalPrincipalActive, 7500);
    expect(summary.totalInterestDue, 300);
    expect(summary.totalOverdueReceivable, 0);
  });

  test('ledger summary reports overdue receivable as payable amount', () async {
    final now = DateTime.now();
    final loanId = await _insertLoan(
      db,
      loanAmount: 10000,
      interestRate: 5,
      startDate: now.subtract(const Duration(days: 40)),
    );

    await repository.updateLoan(
      loanId,
      GirviLoansCompanion(
        maturityDate: drift.Value(now.subtract(const Duration(days: 1))),
      ),
    );

    final summary = await repository.getSummary();

    expect(summary.totalOverdue, 1);
    expect(summary.totalPrincipalActive, 10000);
    expect(summary.totalInterestDue, 1000);
    expect(summary.totalOverdueReceivable, 11000);
  });

  test('maturity date stays active until the following calendar day', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final loanId = await _insertLoan(
      db,
      startDate: today.subtract(const Duration(days: 30)),
    );
    await repository.updateLoan(
      loanId,
      GirviLoansCompanion(maturityDate: drift.Value(today)),
    );

    expect(await repository.syncOverdueStatus(), 0);
    expect((await repository.getLoanById(loanId))!.status,
        GirviStatus.active.dbValue);
    final summary = await repository.getSummary();
    expect(summary.totalActive, 1);
    expect(summary.totalOverdue, 0);
  });

  test('pledge register keeps ticket order across lifecycle statuses',
      () async {
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: 'Register Order Customer',
            mobile: '9888888888',
          ),
        );

    Future<void> addTicket(String number, GirviStatus status) async {
      await db.into(db.girviLoans).insert(
            GirviLoansCompanion.insert(
              ticketNo: number,
              customerId: customerId,
              itemDescription: 'Gold ring',
              loanAmount: const drift.Value(10000),
              interestRate: const drift.Value(5),
              startDate: drift.Value(DateTime.now()),
              status: drift.Value(status.dbValue),
            ),
          );
    }

    await addTicket('GRV-0013', GirviStatus.active);
    await addTicket('GRV-0011', GirviStatus.overdue);
    await addTicket('GRV-0012', GirviStatus.released);

    final controller = GirviListController(db);
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.loans.map((item) => item.loan.ticketNo).toList(),
        ['GRV-0011', 'GRV-0012', 'GRV-0013']);

    controller.onSearchChanged('0012');
    expect(controller.countForFilter(GirviFilter.all), 1);
    expect(controller.loans.single.loan.ticketNo, 'GRV-0012');

    controller.onSearchChanged('');
    await addTicket('GRV-0014', GirviStatus.active);
    await controller.reload();
    expect(controller.loans.last.loan.ticketNo, 'GRV-0014');
  });

  test('ready for delivery tickets are not counted as released tickets',
      () async {
    final loanId = await _insertLoan(db);

    await repository.recordReleaseSettlement(
      loanId: loanId,
      principalDue: 50000,
      interestDue: 0,
      principalReceived: 50000,
      interestReceived: 0,
      paymentMode: GirviPaymentMode.cash,
      paymentDate: DateTime.now(),
      expectedDeliveryDate: DateTime.now(),
      receiptNo: 'GIP-READY-001',
    );

    final summary = await repository.getSummary();

    expect(summary.totalReadyForDelivery, 1);
    expect(summary.totalReleased, 0);
    expect(summary.totalLoans, 1);
  });

  test('keeps released account history beyond 30 days', () async {
    final now = DateTime(2026, 9, 25, 12);
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: 'Released Retention Customer',
            mobile: '9777777777',
          ),
        );

    Future<int> insertReleasedLoan({
      required String ticketNo,
      required DateTime deliveredAt,
    }) {
      return db.into(db.girviLoans).insert(
            GirviLoansCompanion.insert(
              ticketNo: ticketNo,
              customerId: customerId,
              itemDescription: 'Gold ring',
              grossWeight: const drift.Value(8),
              loanAmount: const drift.Value(10000),
              interestRate: const drift.Value(5),
              startDate: drift.Value(DateTime(2026, 1, 1)),
              status: drift.Value(GirviStatus.released.dbValue),
              releaseDate: drift.Value(deliveredAt),
              deliveredAt: drift.Value(deliveredAt),
            ),
          );
    }

    final expiredLoanId = await insertReleasedLoan(
      ticketNo: 'GRV-OLD-REL',
      deliveredAt: now.subtract(const Duration(days: 31)),
    );
    final retainedLoanId = await insertReleasedLoan(
      ticketNo: 'GRV-RECENT-REL',
      deliveredAt: now.subtract(const Duration(days: 30)),
    );

    await db.into(db.girviPayments).insert(
          GirviPaymentsCompanion.insert(
            girviId: expiredLoanId,
            paymentType: GirviPaymentType.fullRelease.dbValue,
            amount: const drift.Value(10000),
          ),
        );
    await db.into(db.girviDisbursements).insert(
          GirviDisbursementsCompanion.insert(
            girviId: expiredLoanId,
            sequenceNo: 1,
            mode: 'Cash',
            displayLabel: 'Cash',
            amount: 10000,
          ),
        );
    final itemId = await db.into(db.girviLoanItems).insert(
          GirviLoanItemsCompanion.insert(
            girviId: expiredLoanId,
            serialNo: 1,
            itemName: 'Gold ring',
            metalType: 'Gold',
            purity: '22KT',
          ),
        );
    await db.into(db.girviItemPhotos).insert(
          GirviItemPhotosCompanion.insert(
            itemId: itemId,
            filePath: 'ring.jpg',
          ),
        );
    await db.into(db.girviNoticeActions).insert(
          GirviNoticeActionsCompanion.insert(
            girviId: expiredLoanId,
            actionType: 'DELIVERY',
          ),
        );

    final retainedLoans = await repository.getLoansWithCustomer();

    expect(retainedLoans.map((entry) => entry.loan.id),
        containsAll([expiredLoanId, retainedLoanId]));
    expect(await repository.getLoanById(expiredLoanId), isNotNull);
    expect(await repository.getLoanById(retainedLoanId), isNotNull);
    expect(await db.select(db.girviPayments).get(), hasLength(1));
    expect(await db.select(db.girviDisbursements).get(), hasLength(1));
    expect(await db.select(db.girviLoanItems).get(), hasLength(1));
    expect(await db.select(db.girviItemPhotos).get(), hasLength(1));
    expect(await db.select(db.girviNoticeActions).get(), hasLength(1));
  });

  test('active ledger filter includes all running open accounts', () async {
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: 'Ledger Filter Customer',
            mobile: '9888888888',
          ),
        );

    Future<void> insertLoan(String ticketNo, GirviStatus status) {
      return db.into(db.girviLoans).insert(
            GirviLoansCompanion.insert(
              ticketNo: ticketNo,
              customerId: customerId,
              itemDescription: 'Gold item',
              grossWeight: const drift.Value(10),
              loanAmount: const drift.Value(10000),
              interestRate: const drift.Value(5),
              startDate: drift.Value(DateTime(2026, 1, 1)),
              status: drift.Value(status.dbValue),
            ),
          );
    }

    await insertLoan('GRV-ACTIVE-001', GirviStatus.active);
    await insertLoan('GRV-OVERDUE-001', GirviStatus.overdue);
    await insertLoan('GRV-PARTIAL-001', GirviStatus.partialRelease);
    await insertLoan('GRV-READY-001', GirviStatus.readyForDelivery);
    await insertLoan('GRV-RELEASED-001', GirviStatus.released);

    final activeRows = await repository.getLoansWithCustomer(
      filter: GirviFilter.active,
    );

    expect(activeRows.map((row) => row.loan.ticketNo).toSet(), {
      'GRV-ACTIVE-001',
      'GRV-OVERDUE-001',
      'GRV-PARTIAL-001',
    });
  });

  test('tracks partial release settlement, ready state and final delivery',
      () async {
    final loanId = await _insertLoan(db);
    final firstPaymentDate = DateTime(2026, 6, 19);
    final promisedPickup = DateTime(2026, 6, 21);

    final partial = await repository.recordReleaseSettlement(
      loanId: loanId,
      principalDue: 50000,
      interestDue: 20000,
      principalReceived: 20000,
      interestReceived: 10000,
      paymentMode: GirviPaymentMode.cash,
      paymentDate: firstPaymentDate,
      expectedDeliveryDate: promisedPickup,
      receiptNo: 'GIP-SET-001',
    );

    var loan = await repository.getLoanById(loanId);
    var payments = await repository.getPaymentModelsForLoan(loanId);

    expect(partial.fullySettled, isFalse);
    expect(partial.principalRemaining, 30000);
    expect(partial.interestRemaining, 10000);
    expect(loan!.status, GirviStatus.partialRelease.dbValue);
    expect(loan.releaseDate, isNull);
    expect(loan.expectedDeliveryDate, promisedPickup);
    expect(payments.single.principalComponent, 20000);
    expect(payments.single.interestComponent, 10000);
    expect(payments.single.balanceAfter, 40000);

    final completed = await repository.recordReleaseSettlement(
      loanId: loanId,
      principalDue: 30000,
      interestDue: 10000,
      principalReceived: 30000,
      interestReceived: 10000,
      paymentMode: GirviPaymentMode.upi,
      paymentDate: DateTime(2026, 6, 20),
      expectedDeliveryDate: promisedPickup,
      receiptNo: 'GIP-SET-002',
    );

    loan = await repository.getLoanById(loanId);
    payments = await repository.getPaymentModelsForLoan(loanId);

    expect(completed.fullySettled, isTrue);
    expect(completed.totalRemaining, 0);
    final account = (await repository.getLoansWithCustomer()).single;
    final balances = GirviLedgerBalanceService.calculate(account, payments);
    final firstEntry =
        payments.firstWhere((payment) => payment.receiptNo == 'GIP-SET-001');
    final finalEntry =
        payments.firstWhere((payment) => payment.receiptNo == 'GIP-SET-002');
    expect(balances[firstEntry.id]!.principalRemaining, 30000);
    expect(balances[firstEntry.id]!.interestRemaining, 10000);
    expect(balances[firstEntry.id]!.totalRemaining, 40000);
    expect(balances[finalEntry.id]!.totalRemaining, 0);
    expect(loan!.status, GirviStatus.readyForDelivery.dbValue);
    expect(loan.releaseDate, DateTime(2026, 6, 20));
    expect(loan.deliveredAt, isNull);
    expect(loan.releasePrincipal, 50000);
    expect(loan.releaseInterest, 20000);
    expect(loan.releaseTotalAmount, 70000);
    expect(payments, hasLength(2));

    final deliveredAt = DateTime(2026, 6, 21, 11, 30);
    final delivered = await repository.markGirviDelivered(
      loanId: loanId,
      deliveredAt: deliveredAt,
      deliveredBy: 'Test Staff',
    );
    loan = await repository.getLoanById(loanId);

    expect(delivered, isTrue);
    expect(loan!.status, GirviStatus.released.dbValue);
    expect(loan.expectedDeliveryDate, deliveredAt);
    expect(loan.deliveredAt, deliveredAt);
    expect(loan.releasedBy, 'Test Staff');
  });

  test('applies final release discount to interest first and audits waiver',
      () async {
    final loanId = await _insertLoan(
      db,
      interestRate: 4,
      startDate: DateTime(2026, 1, 1),
    );
    final settlement = await repository.recordReleaseSettlement(
      loanId: loanId,
      principalDue: 50000,
      interestDue: 12000,
      principalReceived: 50000,
      interestReceived: 10000,
      discountAmount: 2000,
      paymentMode: GirviPaymentMode.cash,
      paymentDate: DateTime(2026, 6, 19),
      expectedDeliveryDate: DateTime(2026, 6, 20),
      receiptNo: 'GIP-DISC-001',
    );

    final loan = await repository.getLoanById(loanId);
    final payment = (await repository.getPaymentModelsForLoan(loanId)).single;
    final joined = (await repository.getLoansWithCustomer()).single;

    expect(settlement.fullySettled, isTrue);
    expect(settlement.discountApplied, 2000);
    expect(settlement.interestDiscount, 2000);
    expect(settlement.principalDiscount, 0);
    expect(loan!.status, GirviStatus.readyForDelivery.dbValue);
    expect(loan.releaseTotalAmount, 60000);
    expect(loan.releaseDiscount, 2000);
    expect(payment.amount, 60000);
    expect(payment.principalComponent, 50000);
    expect(payment.interestComponent, 10000);
    expect(payment.interestDiscountComponent, 2000);
    expect(payment.principalDiscountComponent, 0);
    expect(payment.balanceAfter, 0);
    expect(joined.principalDue, 0);
    expect(joined.interestPaidTotal, 10000);
    expect(joined.interestDiscountTotal, 2000);
  });

  test('rejects discount on an incomplete release settlement', () async {
    final loanId = await _insertLoan(db);

    expect(
      () => repository.recordReleaseSettlement(
        loanId: loanId,
        principalDue: 50000,
        interestDue: 12000,
        principalReceived: 30000,
        interestReceived: 10000,
        discountAmount: 2000,
        paymentMode: GirviPaymentMode.cash,
        paymentDate: DateTime(2026, 6, 19),
        expectedDeliveryDate: DateTime(2026, 6, 20),
      ),
      throwsArgumentError,
    );
  });

  test('final release never applies an interest waiver to principal', () async {
    final loanId = await _insertLoan(db);

    await expectLater(
      repository.recordReleaseSettlement(
        loanId: loanId,
        principalDue: 50000,
        interestDue: 1000,
        principalReceived: 49000,
        interestReceived: 1000,
        discountAmount: 1000,
        paymentMode: GirviPaymentMode.cash,
        paymentDate: DateTime(2026, 6, 19),
        expectedDeliveryDate: DateTime(2026, 6, 20),
      ),
      throwsArgumentError,
    );
    expect(await repository.getPaymentModelsForLoan(loanId), isEmpty);
  });

  test('final release rejects stale principal and invalid collection dates',
      () async {
    final loanId = await _insertLoan(db);

    Future<GirviSettlementResult> settle({
      double principalDue = 50000,
      DateTime? paymentDate,
      DateTime? pickupDate,
    }) =>
        repository.recordReleaseSettlement(
          loanId: loanId,
          principalDue: principalDue,
          interestDue: 0,
          principalReceived: 1000,
          interestReceived: 0,
          paymentMode: GirviPaymentMode.cash,
          paymentDate: paymentDate ?? DateTime.now(),
          expectedDeliveryDate: pickupDate ?? DateTime.now(),
        );

    await expectLater(settle(principalDue: 1000), throwsStateError);
    await expectLater(
      settle(paymentDate: DateTime(2025, 12, 31)),
      throwsArgumentError,
    );
    await expectLater(
      settle(paymentDate: DateTime.now().add(const Duration(days: 2))),
      throwsArgumentError,
    );
    await expectLater(
      settle(
        paymentDate: DateTime(2026, 6, 20),
        pickupDate: DateTime(2026, 6, 19),
      ),
      throwsArgumentError,
    );
    expect(await repository.getPaymentModelsForLoan(loanId), isEmpty);
  });

  test('final release cannot be recorded twice after full settlement',
      () async {
    final loanId = await _insertLoan(db);
    await repository.recordReleaseSettlement(
      loanId: loanId,
      principalDue: 50000,
      interestDue: 0,
      principalReceived: 50000,
      interestReceived: 0,
      paymentMode: GirviPaymentMode.cash,
      paymentDate: DateTime.now(),
      expectedDeliveryDate: DateTime.now(),
    );

    await expectLater(
      repository.recordReleaseSettlement(
        loanId: loanId,
        principalDue: 50000,
        interestDue: 0,
        principalReceived: 50000,
        interestReceived: 0,
        paymentMode: GirviPaymentMode.cash,
        paymentDate: DateTime.now(),
        expectedDeliveryDate: DateTime.now(),
      ),
      throwsStateError,
    );
    expect(await repository.getPaymentModelsForLoan(loanId), hasLength(1));
  });

  test('reconciles legacy zero-principal open loan as ready for delivery',
      () async {
    final now = DateTime.now();
    final loanId = await _insertLoan(
      db,
      startDate: now.subtract(const Duration(days: 1)),
    );

    await repository.recordInterestLedgerPayment(
      loanId: loanId,
      paymentMode: GirviPaymentMode.cash,
      amount: 2500,
      paymentDate: now,
      receiptNo: 'GIP-LEGACY-I',
    );
    await _seedHistoricalPrincipalPayment(
      db,
      loanId: loanId,
      amount: 50000,
      paymentDate: now,
      receiptNo: 'GIP-LEGACY-P',
    );

    final updated = await repository.syncSettlementStatus();
    final loan = await repository.getLoanById(loanId);
    final joined = (await repository.getLoansWithCustomer()).single;

    expect(updated, 1);
    expect(loan!.loanAmount, 0);
    expect(loan.status, GirviStatus.readyForDelivery.dbValue);
    expect(loan.releaseDate, isNotNull);
    expect(joined.originalPrincipal, 50000);
    expect(joined.principalDue, 0);
    expect(joined.grossInterestAccrued, 2500);
    expect(joined.netInterestDue, 0);
  });

  test('reads historical partial principal payment and outstanding principal',
      () async {
    final loanId = await _insertLoan(db);

    await _seedHistoricalPrincipalPayment(
      db,
      loanId: loanId,
      amount: 12000,
      paymentDate: DateTime(2026, 2, 10),
      receiptNo: 'GIP-00099',
      paymentMode: GirviPaymentMode.upi,
    );

    final loan = await repository.getLoanById(loanId);
    final payments = await repository.getPaymentModelsForLoan(loanId);

    expect(loan!.loanAmount, 38000);
    expect(
        payments.single.paymentType, GirviPaymentType.partialPrincipal.dbValue);
    expect(payments.single.balanceAfter, 38000);
    expect(payments.single.paymentMode, GirviPaymentMode.upi.dbValue);
  });

  test('interest payment advances paid-through date without reducing principal',
      () async {
    final loanId = await _insertLoan(
      db,
      loanAmount: 5000,
      interestRate: 5,
      startDate: DateTime(2026, 1, 1),
    );

    await repository.recordInterestLedgerPayment(
      loanId: loanId,
      paymentMode: GirviPaymentMode.cash,
      amount: 4000,
      paymentDate: DateTime(2026, 4, 1),
      receiptNo: 'GIP-ADV-001',
    );

    final loan = await repository.getLoanById(loanId);
    final payment = (await repository.getPaymentModelsForLoan(loanId)).single;

    expect(loan!.loanAmount, 5000);
    expect(loan.lastInterestPaidDate, DateTime(2027, 5, 1));
    expect(payment.amount, 4000);
    expect(payment.monthsCovered, 16);
    expect(payment.interestFromDate, DateTime(2026, 1, 1));
    expect(payment.interestToDate, DateTime(2027, 5, 1));
    expect(payment.balanceAfter, 5000);

    final advanceSnapshot = _loanModel(
      loanAmount: 5000,
      interestRate: 5,
      startDate: DateTime(2026, 1, 1),
      releaseDate: DateTime(2026, 4, 1),
      lastInterestPaidDate: loan.lastInterestPaidDate,
    );
    expect(advanceSnapshot.accruedInterest, 0);
    expect(advanceSnapshot.advanceInterestMonths, 13);
  });

  test('girvi interest charges started months and compounds annually', () {
    expect(GirviInterestCalculationType.forChargeableMonths(12), 'Simple');
    expect(GirviInterestCalculationType.forChargeableMonths(13), 'Compound');
    expect(
      GirviInterestCalculator.interestForMonths(
        principal: 25000,
        monthlyRatePercent: 5,
        months: 42,
      ),
      108120,
    );
    expect(
      GirviLoanModel.chargeableMonthsBetween(
        DateTime(2025, 6, 17),
        DateTime(2026, 6, 17, 14, 8),
      ),
      12,
    );
    expect(
      GirviLoanModel.chargeableMonthsBetween(
        DateTime(2025, 6, 17),
        DateTime(2026, 6, 18),
      ),
      13,
    );

    final oneStartedMonth = _loanModel(
      loanAmount: 5000,
      interestRate: 5,
      startDate: DateTime(2026, 1, 1),
      releaseDate: DateTime(2026, 1, 2),
    );
    final annualCycle = _loanModel(
      loanAmount: 5000,
      interestRate: 5,
      startDate: DateTime(2026, 1, 1),
      releaseDate: DateTime(2027, 1, 1),
    );
    final monthAfterAnnualCycle = _loanModel(
      loanAmount: 5000,
      interestRate: 5,
      startDate: DateTime(2026, 1, 1),
      releaseDate: DateTime(2027, 2, 1),
    );
    final paidThroughAnnualCycle = _loanModel(
      loanAmount: 5000,
      interestRate: 5,
      startDate: DateTime(2026, 1, 1),
      releaseDate: DateTime(2027, 2, 1),
      lastInterestPaidDate: DateTime(2027, 1, 1),
    );
    final seventeenMonthLoan = _loanModel(
      loanAmount: 50000,
      interestRate: 5,
      startDate: DateTime(2025, 2, 9),
      releaseDate: DateTime(2026, 6, 17),
    );
    final seventeenMonthBreakdown = GirviInterestCalculator.quoteAt(
      principal: seventeenMonthLoan.loanAmount,
      monthlyRatePercent: seventeenMonthLoan.interestRate,
      startDate: seventeenMonthLoan.startDate,
      asOf: seventeenMonthLoan.releaseDate!,
      adjustments: const [],
    ).cycles;
    final seventeenMonthElapsed =
        seventeenMonthLoan.unpaidInterestElapsedPeriod;

    expect(oneStartedMonth.accruedInterest, 250);
    expect(annualCycle.accruedInterest, 3000);
    expect(monthAfterAnnualCycle.accruedInterest, 3400);
    expect(paidThroughAnnualCycle.accruedInterest, 250);
    expect(seventeenMonthBreakdown, hasLength(2));
    expect(seventeenMonthBreakdown[0].months, 12);
    expect(seventeenMonthBreakdown[0].principalBase, 50000);
    expect(seventeenMonthBreakdown[0].interestAmount, 30000);
    expect(seventeenMonthBreakdown[0].capitalizedAfterLine, isTrue);
    expect(seventeenMonthBreakdown[1].months, 5);
    expect(seventeenMonthBreakdown[1].principalBase, 80000);
    expect(seventeenMonthBreakdown[1].interestAmount, 20000);
    expect(seventeenMonthElapsed.years, 1);
    expect(seventeenMonthElapsed.months, 4);
    expect(seventeenMonthElapsed.days, 8);
  });

  test('ledger remains simple through month 12 despite compound setting',
      () async {
    await GirviBillingRepo(db: db).save(
      GirviBillingModel.defaults.copyWith(interestType: 'Compound'),
    );
    final loanId = await _insertLoan(
      db,
      loanAmount: 10000,
      interestRate: 10,
      startDate: DateTime(2025, 1, 1),
    );
    await repository.updateLoan(
      loanId,
      GirviLoansCompanion(
        releaseDate: drift.Value(DateTime(2025, 12, 1)),
      ),
    );

    final account = (await repository.getLoansWithCustomer()).single;

    expect(account.interestType, GirviInterestCalculationType.simple);
    expect(account.grossInterestAccrued, 11000);
    expect(account.netInterestDue, 11000);
  });

  test('ledger compounds after month 12 despite simple setting', () async {
    await GirviBillingRepo(db: db).save(
      GirviBillingModel.defaults.copyWith(interestType: 'Simple'),
    );
    final loanId = await _insertLoan(
      db,
      loanAmount: 10000,
      interestRate: 10,
      startDate: DateTime(2025, 1, 1),
    );
    await repository.updateLoan(
      loanId,
      GirviLoansCompanion(
        releaseDate: drift.Value(DateTime(2026, 2, 1)),
      ),
    );

    final account = (await repository.getLoansWithCustomer()).single;

    expect(account.interestType, GirviInterestCalculationType.compound);
    expect(account.grossInterestAccrued, 14200);
    expect(account.netInterestDue, 14200);
  });
}

Future<int> _insertLoan(
  AppDatabase db, {
  double loanAmount = 50000,
  double interestRate = 5,
  DateTime? startDate,
}) async {
  final customerId = await db.into(db.customers).insert(
        CustomersCompanion.insert(
          name: 'Interest Entry Customer',
          mobile: '9999999999',
        ),
      );

  return db.into(db.girviLoans).insert(
        GirviLoansCompanion.insert(
          ticketNo: 'GRV-INT-0001',
          customerId: customerId,
          itemDescription: 'Gold chain',
          grossWeight: const drift.Value(12),
          netWeight: const drift.Value(12),
          loanAmount: drift.Value(loanAmount),
          interestRate: drift.Value(interestRate),
          startDate: drift.Value(startDate ?? DateTime(2026, 1, 1)),
        ),
      );
}

Future<void> _seedHistoricalPrincipalPayment(
  AppDatabase db, {
  required int loanId,
  required double amount,
  required DateTime paymentDate,
  required String receiptNo,
  GirviPaymentMode paymentMode = GirviPaymentMode.cash,
}) async {
  final loan = await (db.select(db.girviLoans)
        ..where((row) => row.id.equals(loanId)))
      .getSingle();
  final balanceAfter = loan.loanAmount - amount;
  await (db.update(db.girviLoans)..where((row) => row.id.equals(loanId)))
      .write(GirviLoansCompanion(loanAmount: drift.Value(balanceAfter)));
  await db.into(db.girviPayments).insert(
        GirviPaymentsCompanion.insert(
          girviId: loanId,
          paymentType: GirviPaymentType.partialPrincipal.dbValue,
          paymentMode: drift.Value(paymentMode.dbValue),
          paymentDate: drift.Value(paymentDate),
          amount: drift.Value(amount),
          balanceAfter: drift.Value(balanceAfter),
          receiptNo: drift.Value(receiptNo),
        ),
      );
}

GirviLoanModel _loanModel({
  required double loanAmount,
  required double interestRate,
  required DateTime startDate,
  DateTime? releaseDate,
  DateTime? lastInterestPaidDate,
}) {
  return GirviLoanModel(
    id: 1,
    ticketNo: 'GRV-TEST',
    customerId: 1,
    itemDescription: 'Gold item',
    itemCount: 1,
    metalType: 'Gold',
    metalPurity: '22K',
    grossWeight: 1,
    stoneWeight: 0,
    netWeight: 1,
    loanAmount: loanAmount,
    interestRate: interestRate,
    durationMonths: 12,
    disbursementMode: 'Cash',
    startDate: startDate,
    releaseDate: releaseDate,
    lastInterestPaidDate: lastInterestPaidDate,
    createdAt: startDate,
  );
}
