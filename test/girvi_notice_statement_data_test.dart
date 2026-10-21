import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/girvi/girvi_notice_generation_service.dart';
import 'package:lotus_erp/logic/girvi/notice_pdf/notice_statement_data.dart';
import 'package:lotus_erp/models/girvi/girvi_notice_action_model.dart';

import 'fixtures/girvi_notice_case_fixture.dart';

void main() {
  test('new notice gives the review period after customer delivery', () {
    final item = createNoticeCase();
    final notice = GirviNoticeGenerationService(now: item.now).build(
      item: item,
      noticeType: GirviNoticeType.formal,
      language: GirviNoticeLanguage.english,
    );
    expect(notice, contains('within 7 days after receiving this notice'));
  });

  test('notice draft uses the selected response period and account recipient',
      () {
    final item = createNoticeCase();
    final notice = GirviNoticeGenerationService(now: item.now).build(
      item: item,
      noticeType: GirviNoticeType.formal,
      language: GirviNoticeLanguage.english,
      noticePeriodDays: 14,
    );
    final draft = NoticeStatementData.parse(
      notice,
      GirviNoticeLanguage.english,
    ).importantLines.join('\n');

    expect(draft, contains('To: Sample Customer'));
    expect(draft, contains('Customer Address: Sample address, Patna'));
    expect(draft, contains('Customer Mobile: 0000000000'));
    expect(draft, contains('within 14 days after receiving this notice'));
    expect(draft, contains('This notice or the absence of a reply'));
  });

  for (final simple in [true, false]) {
    for (final language in GirviNoticeLanguage.values) {
      test(
          'statement keeps verified ${simple ? 'simple' : 'compound'} '
          '${language.label} values and approved wording', () {
        final item = createNoticeCase(simple: simple);
        final generated = GirviNoticeGenerationService(now: item.now).build(
          item: item,
          noticeType: GirviNoticeType.formal,
          language: language,
        );
        final data = NoticeStatementData.parse(generated, language);

        expect(data.pledgeReference, item.loan.ticketNo);
        expect(data.itemName, 'ring');
        expect(data.purity, '22KT (91.6%)');
        expect(data.agreedLoanTerm, '6 months');
        expect(data.originalLoanPeriodLabel(12), '6 months');
        expect(data.elapsedLoanPeriod, '18 months');
        expect(data.chargeablePeriod, '18 months');
        expect(data.periods.length, simple ? 1 : 2);
        expect(data.isCompound, !simple);
        expect(data.totalPayable, simple ? 'Rs 1,18,000' : 'Rs 1,18,720');
        expect(data.importantLines.join(' '),
            contains('I will visit the shop on Friday.'));
        expect(data.importantLines.join(' '),
            isNot(contains(simple ? 'Rs 18,000' : 'Rs 18,720')));
      });
    }
  }

  test('unstructured historical notice keeps its complete approved wording',
      () {
    const text =
        'Legacy notice\nPlease settle the account.\nCustom operator note.';
    final data = NoticeStatementData.parse(
      text,
      GirviNoticeLanguage.english,
    );
    expect(data.importantLines.join('\n'), text);
  });

  test('a saved notice never displays an interest end after its notice date',
      () {
    const text = 'Notice Date: 17 October 2026\n'
        'Interest Period To: 09 November 2026';
    final data = NoticeStatementData.parse(
      text,
      GirviNoticeLanguage.english,
    );
    expect(data.interestPeriodTo, '17 October 2026');
    expect(data.lines.join('\n'), text);
  });

  test('compound notice carries verified payment and outstanding totals', () {
    final item = createNoticeCase(
      simple: false,
      interestPaid: 3000,
      interestDiscount: 200,
    );
    final generator = GirviNoticeGenerationService(now: item.now);
    expect(generator.validate(item), isEmpty);
    final approved = generator.build(
      item: item,
      noticeType: GirviNoticeType.formal,
      language: GirviNoticeLanguage.english,
    );
    final data = NoticeStatementData.parse(
      approved,
      GirviNoticeLanguage.english,
    );

    expect(data.isCompound, isTrue);
    expect(data.compoundingCycle, 'Every 12 months');
    expect(data.grossInterest, 'Rs 18,720');
    expect(data.interestPaidTotal, 'Rs 3,000');
    expect(data.interestAdjustmentTotal, 'Rs 200');
    expect(data.hasInterestPayment, isTrue);
    expect(data.hasInterestAdjustment, isTrue);
    expect(data.interestOutstanding, 'Rs 15,520');
    expect(data.totalPayable, 'Rs 1,15,520');
    expect(data.monthlyRate, '1.00%');
    expect(
      data.periods.first.value('Period', 'अवधि', GirviNoticeLanguage.english),
      '04 April 2025 to 03 April 2026',
    );
    expect(
      data.periods.last.value('Period', 'अवधि', GirviNoticeLanguage.english),
      '04 April 2026 to 04 October 2026',
    );
    expect(data.interestPeriodTo, '04 October 2026');
    expect(
        data.importantLines.join(' '), contains('Interest Received: Rs 3,000'));
  });

  test('final summary reconciles principal, interest, receipts and adjustments',
      () {
    final item = createNoticeCase(
      simple: false,
      principalPaid: 5000,
      principalDiscount: 1000,
      interestPaid: 3000,
      interestDiscount: 200,
    );
    final generated = GirviNoticeGenerationService(now: item.now).build(
      item: item,
      noticeType: GirviNoticeType.formal,
      language: GirviNoticeLanguage.english,
    );
    final summary = NoticeStatementData.parse(
      generated,
      GirviNoticeLanguage.english,
    );

    expect(summary.originalPrincipal, 'Rs 1,00,000');
    expect(summary.grossInterest, 'Rs 18,720');
    expect(summary.totalAccountCharges, 'Rs 1,18,720');
    expect(summary.principalPaidTotal, 'Rs 5,000');
    expect(summary.interestPaidTotal, 'Rs 3,000');
    expect(summary.totalReceived, 'Rs 8,000');
    expect(summary.principalAdjustment, 'Rs 1,000');
    expect(summary.interestAdjustment, 'Rs 200');
    expect(summary.totalAdjustments, 'Rs 1,200');
    expect(summary.principalOutstanding, 'Rs 94,000');
    expect(summary.interestOutstanding, 'Rs 15,520');
    expect(summary.totalPayable, 'Rs 1,09,520');
    expect(summary.hasPayments, isTrue);
    expect(summary.hasAdjustments, isTrue);
    expect(
        summary.importantLines.join(' '), isNot(contains('Total Received:')));
  });

  test('final summary includes principal paid through the earlier ledger path',
      () {
    final item = createNoticeCase(
      simple: false,
      legacyPrincipalPaid: 2000,
      principalPaid: 5000,
      interestPaid: 3000,
    );
    final generated = GirviNoticeGenerationService(now: item.now).build(
      item: item,
      noticeType: GirviNoticeType.formal,
      language: GirviNoticeLanguage.english,
    );
    final summary = NoticeStatementData.parse(
      generated,
      GirviNoticeLanguage.english,
    );
    expect(summary.originalPrincipal, 'Rs 1,00,000');
    expect(summary.principalPaidTotal, 'Rs 7,000');
    expect(summary.totalReceived, 'Rs 10,000');
    expect(summary.principalOutstanding, 'Rs 93,000');
    expect(summary.totalPayable, 'Rs 1,08,720');
  });

  test('zero legacy interest adjustment does not display a discount', () {
    final item = createNoticeCase(simple: false, interestPaid: 3000);
    final generated = GirviNoticeGenerationService(now: item.now).build(
      item: item,
      noticeType: GirviNoticeType.formal,
      language: GirviNoticeLanguage.english,
    );
    final summary = NoticeStatementData.parse(
      generated,
      GirviNoticeLanguage.english,
    );

    expect(summary.totalAdjustments, 'Rs 0');
    expect(summary.hasAdjustments, isFalse);
  });

  test('older approved notice derives gross interest from saved period lines',
      () {
    final item = createNoticeCase(simple: false);
    final generated = GirviNoticeGenerationService(now: item.now).build(
      item: item,
      noticeType: GirviNoticeType.formal,
      language: GirviNoticeLanguage.english,
    );
    final olderText = generated.replaceFirst(
      RegExp(r'^Gross Interest:.*\n', multiLine: true),
      '',
    );
    final data = NoticeStatementData.parse(
      olderText,
      GirviNoticeLanguage.english,
    );

    expect(data.periods, hasLength(2));
    expect(data.grossInterest, 'Rs 18,720');
    expect(data.hasInterestPayment, isFalse);
    expect(data.hasInterestAdjustment, isFalse);
    expect(data.lines.join('\n'), olderText.trim());
  });

  test('verified compound figures replace stale simple figures only in view',
      () {
    final approvedCase = createNoticeCase(simple: true);
    final verifiedCase = createNoticeCase(simple: false);
    final generator = GirviNoticeGenerationService(now: approvedCase.now);
    final approvedText = generator.build(
      item: approvedCase,
      noticeType: GirviNoticeType.formal,
      language: GirviNoticeLanguage.english,
    );
    final verifiedText = generator.build(
      item: verifiedCase,
      noticeType: GirviNoticeType.formal,
      language: GirviNoticeLanguage.english,
    );
    final approved = NoticeStatementData.parse(
      approvedText,
      GirviNoticeLanguage.english,
    );
    final verified = NoticeStatementData.parse(
      verifiedText,
      GirviNoticeLanguage.english,
    );
    final currentView = approved.withVerifiedFinancials(
      verified,
      asOf: verifiedCase.now,
    );

    expect(approved.isSimple, isTrue);
    expect(approved.grossInterest, 'Rs 18,000');
    expect(currentView.isCompound, isTrue);
    expect(currentView.isSimple, isFalse);
    expect(currentView.periods, hasLength(2));
    expect(currentView.grossInterest, 'Rs 18,720');
    expect(currentView.interestOutstanding, 'Rs 18,720');
    expect(currentView.totalPayable, 'Rs 1,18,720');
    expect(currentView.importantLines, approved.importantLines);
    expect(currentView.noticeNumber, approved.noticeNumber);
    expect(currentView.financialAsOf, verifiedCase.now);
  });

  test('older notice facts display a short item name without changing its text',
      () {
    const approvedText =
        'Pledged Item: Serial Number 1 - Ring | Gold | 22KT | 1 piece | Net Weight 10.000 g\n'
        'Actual Duration: 1 year 6 months\n'
        'Total Calendar Duration: 18 months\n'
        'Chargeable Interest Period: 18 chargeable months';
    final data = NoticeStatementData.parse(
      approvedText,
      GirviNoticeLanguage.english,
    );
    expect(data.itemName, 'Ring');
    expect(data.purity, '22KT (91.6%)');
    expect(data.agreedLoanTerm, isNull);
    expect(data.originalLoanPeriodLabel(6), '6 months');
    expect(data.originalLoanPeriodLabel(null), 'Not recorded');
    expect(data.elapsedLoanPeriod, '18 months');
    expect(data.lines.join('\n'), approvedText);
  });

  test('custom approved account note remains visible in the PDF narrative', () {
    final item = createNoticeCase();
    final generated = GirviNoticeGenerationService(now: item.now).build(
      item: item,
      noticeType: GirviNoticeType.formal,
      language: GirviNoticeLanguage.english,
    );
    final edited = generated.replaceFirst(
      'Pledge Account and Duration',
      'Pledge Account and Duration\nCustomer note: Please verify the item in person.',
    );
    final data = NoticeStatementData.parse(
      edited,
      GirviNoticeLanguage.english,
    );
    expect(data.importantLines.join(' '),
        contains('Customer note: Please verify the item in person.'));
  });
}
