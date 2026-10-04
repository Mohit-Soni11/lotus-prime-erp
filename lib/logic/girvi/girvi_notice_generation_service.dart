import 'package:intl/intl.dart';

import '../../models/girvi/contact_recovery_model.dart';
import '../../models/girvi/girvi_enums.dart';
import '../../models/girvi/girvi_loan_model.dart';
import '../../models/girvi/girvi_notice_action_model.dart';
import 'girvi_notice_document.dart';
import 'girvi_notice_financial_timeline.dart';

/// Builds customer notices from verified Girvi account records.
/// Financial values remain owned by the existing account and ledger domain.
class GirviNoticeGenerationService {
  GirviNoticeGenerationService({DateTime? now}) : _now = now ?? DateTime.now();

  final DateTime _now;
  final DateFormat _date = DateFormat('dd MMMM yyyy');
  final NumberFormat _money = NumberFormat('#,##,##0', 'en_IN');

  List<String> validate(ContactRecoveryCase item) {
    final account = item.account;
    final issues = <String>[];
    if (!item.hasVerifiedInterestTimeline) {
      issues.add(
        'Verified interest-period snapshots are missing. Refresh the financial ledger before preparing this notice.',
      );
    }
    final values = <String, double>{
      'principal outstanding': account.principalDue,
      'interest outstanding': item.verifiedInterestDue,
      'total payable': item.verifiedTotalPayable,
      'interest received': account.interestPaidTotal,
      'interest adjustment': account.interestDiscountTotal,
      'principal received': account.principalPaidTotal,
      'principal adjustment': account.principalDiscountTotal,
    };

    for (final entry in values.entries) {
      if (_invalidMoney(entry.value)) {
        issues
            .add('Invalid ${entry.key} found in the verified account record.');
      }
    }

    final recordedInterest =
        item.paymentHistory.fold<double>(0, (sum, payment) {
      if (payment.type == GirviPaymentType.fullRelease) {
        return sum + payment.interestComponent;
      }
      if (payment.type == GirviPaymentType.interest ||
          payment.type == GirviPaymentType.partialInterest) {
        final hasSplitComponents =
            payment.interestComponent > 0 || payment.principalComponent > 0;
        return sum +
            (hasSplitComponents ? payment.interestComponent : payment.amount);
      }
      return sum;
    });
    if ((recordedInterest - account.interestPaidTotal).abs() > 0.01) {
      issues.add(
        'Interest ledger total does not match the account payment summary.',
      );
    }
    final recordedInterestDiscount = item.paymentHistory.fold<double>(
      0,
      (sum, payment) => sum + payment.interestDiscountComponent,
    );
    if ((recordedInterestDiscount - account.interestDiscountTotal).abs() >
        0.01) {
      issues.add(
        'Interest adjustments do not match the account payment summary.',
      );
    }
    if (item.loan.startDate.isAfter(item.now)) {
      issues.add('The pledge start date is later than the notice date.');
    }
    if (item.loan.interestRate < 0 || item.loan.interestRate.isNaN) {
      issues.add('The recorded monthly interest rate is invalid.');
    }

    for (final payment in item.paymentHistory) {
      final paymentValues = <String, double>{
        'payment amount': payment.amount,
        'interest component': payment.interestComponent,
        'principal component': payment.principalComponent,
        'interest adjustment': payment.interestDiscountComponent,
        'principal adjustment': payment.principalDiscountComponent,
      };
      for (final value in paymentValues.entries) {
        if (_invalidMoney(value.value)) {
          issues.add(
            'Invalid ${value.key} found in the interest ledger for ${date(payment.paymentDate)}.',
          );
        }
      }

      final months = payment.monthsCovered ?? 0;
      final from = payment.interestFromDate;
      final to = payment.interestToDate;
      if (months > 0 && (from == null || to == null)) {
        issues.add(
            'Interest ledger period is incomplete for ${date(payment.paymentDate)}.');
      }
      if (from != null && to != null) {
        if (to.isBefore(from)) {
          issues.add(
            'Interest ledger period is reversed for ${date(payment.paymentDate)}.',
          );
        }
        if (from.isBefore(item.loan.startDate) || to.isAfter(item.now)) {
          issues.add(
            'Interest ledger period falls outside the account timeline for ${date(payment.paymentDate)}.',
          );
        }
      }
    }
    final snapshots = item.interestPeriodSnapshots;
    final sequences = <int>{};
    for (final snapshot in snapshots) {
      if (!sequences.add(snapshot.sequence) || snapshot.sequence <= 0) {
        issues
            .add('The verified interest timeline contains duplicate periods.');
      }
      final snapshotValues = <String, double>{
        'opening amount': snapshot.openingAmount,
        'monthly rate': snapshot.monthlyRatePercent,
        'interest per month': snapshot.interestPerMonth,
        'period interest': snapshot.periodInterest,
        'closing amount': snapshot.closingAmount,
      };
      for (final value in snapshotValues.entries) {
        if (_invalidMoney(value.value)) {
          issues.add(
              'Invalid ${value.key} found in the verified interest timeline.');
        }
      }
      if (snapshot.chargeableMonths <= 0 ||
          snapshot.periodTo.isBefore(snapshot.periodFrom) ||
          snapshot.periodFrom.isBefore(item.loan.startDate)) {
        issues.add('A verified interest period is incomplete or out of order.');
      }
    }
    return issues.toSet().toList(growable: false);
  }

  Map<GirviNoticeLanguage, String> buildAll({
    required ContactRecoveryCase item,
    required GirviNoticeType noticeType,
  }) =>
      {
        GirviNoticeLanguage.hindi: build(
          item: item,
          noticeType: noticeType,
          language: GirviNoticeLanguage.hindi,
        ),
        GirviNoticeLanguage.english: build(
          item: item,
          noticeType: noticeType,
          language: GirviNoticeLanguage.english,
        ),
      };

  String build({
    required ContactRecoveryCase item,
    required GirviNoticeType noticeType,
    required GirviNoticeLanguage language,
  }) =>
      buildDocument(
        item: item,
        noticeType: noticeType,
        language: language,
      ).toPlainText();

  GirviNoticeDocument buildDocument({
    required ContactRecoveryCase item,
    required GirviNoticeType noticeType,
    required GirviNoticeLanguage language,
  }) {
    final copy = _NoticeCopy.forStage(noticeType, language);
    final data = _NoticeData(
      item: item,
      noticeType: noticeType,
      service: this,
      language: language,
    );
    final paymentBlocks = data.financialTimeline.paymentBlocks(language);

    return GirviNoticeDocument(
      language: language,
      title: copy.title,
      noticeNumber: data.noticeNumber,
      noticeDate: data.noticeDate,
      pledgeReference: data.ticketNo,
      subject: copy.subject,
      sections: [
        GirviNoticeSection(
          title: '',
          blocks: [
            GirviNoticeBlock(
              lines: [
                '${language == GirviNoticeLanguage.hindi ? 'प्रिय' : 'Dear'} ${data.customerName},',
                copy.opening(data),
                copy.accountContext(data),
              ],
            ),
          ],
        ),
        GirviNoticeSection(
          title: language == GirviNoticeLanguage.hindi
              ? 'गिरवी खाता और अवधि'
              : 'Pledge Account and Duration',
          blocks: [
            GirviNoticeBlock(
              lines: [
                '${language == GirviNoticeLanguage.hindi ? 'गिरवी वस्तु' : 'Pledged Item'}: ${data.itemSummary}',
                '${language == GirviNoticeLanguage.hindi ? 'नेट वजन' : 'Net Weight'}: ${data.netWeight}',
                '${language == GirviNoticeLanguage.hindi ? 'मूल मूलधन' : 'Original Principal'}: ${data.originalPrincipal}',
                '${language == GirviNoticeLanguage.hindi ? 'गिरवी तारीख' : 'Pledge Date'}: ${data.startDate}',
                '${language == GirviNoticeLanguage.hindi ? 'परिपक्वता तारीख' : 'Maturity Date'}: ${data.maturityDate}',
                '${language == GirviNoticeLanguage.hindi ? 'वास्तविक अवधि' : 'Actual Duration'}: ${data.actualDuration}',
                '${language == GirviNoticeLanguage.hindi ? 'कुल कैलेंडर अवधि' : 'Total Calendar Duration'}: ${data.calendarDuration}',
                '${language == GirviNoticeLanguage.hindi ? 'चार्जेबल ब्याज अवधि' : 'Chargeable Interest Period'}: ${data.chargeablePeriod}',
              ],
            ),
          ],
        ),
        GirviNoticeSection(
          title: data.interestBreakdownTitle,
          blocks: data.financialTimeline.interestBlocks(language),
        ),
        if (paymentBlocks.isNotEmpty)
          GirviNoticeSection(
            title: language == GirviNoticeLanguage.hindi
                ? 'भुगतान और समायोजन'
                : 'Payments and Adjustments',
            blocks: paymentBlocks,
          ),
        GirviNoticeSection(
          title: language == GirviNoticeLanguage.hindi
              ? 'अंतिम बकाया सारांश'
              : 'Final Outstanding Summary',
          blocks: [GirviNoticeBlock(lines: data.outstandingSummaryLines)],
        ),
        GirviNoticeSection(
          title: language == GirviNoticeLanguage.hindi
              ? 'आवश्यक कार्रवाई'
              : 'Required Action',
          blocks: [
            GirviNoticeBlock(
              lines: [
                copy.requiredAction(data),
                copy.closing(data),
                language == GirviNoticeLanguage.hindi
                    ? 'यह सूचना गिरवी खाते की शर्तों, व्यापार नीति और लागू कानून के अनुसार जारी की जा रही है।'
                    : 'This notice is issued in accordance with the pledge account terms, business policy and applicable law.',
                '',
                language == GirviNoticeLanguage.hindi
                    ? 'अधिकृत हस्ताक्षर'
                    : 'Authorised Signatory',
              ],
            ),
          ],
        ),
      ],
    );
  }

  String money(double value) => 'Rs ${_money.format(value.round())}';
  String date(DateTime? value) =>
      value == null ? 'Not set' : _date.format(value);
  bool _invalidMoney(double value) =>
      value.isNaN || value.isInfinite || value < -0.01;
}

class _NoticeData {
  _NoticeData({
    required this.item,
    required this.noticeType,
    required this.service,
    required this.language,
  }) : financialTimeline = GirviNoticeFinancialTimeline(
          item: item,
          money: service.money,
          date: service.date,
        );

  final ContactRecoveryCase item;
  final GirviNoticeType noticeType;
  final GirviNoticeGenerationService service;
  final GirviNoticeLanguage language;
  final GirviNoticeFinancialTimeline financialTimeline;

  GirviLoanWithCustomer get account => item.account;
  GirviLoanModel get loan => item.loan;
  String get ticketNo => loan.ticketNo;
  String get noticeNumber =>
      '$ticketNo-N${noticeType.stage.toString().padLeft(2, '0')}';
  String get noticeDate => service.date(service._now);
  String get deadline =>
      service.date(service._now.add(Duration(days: item.noticePeriodDays)));
  String get customerName => account.customerName;
  String get startDate => service.date(loan.startDate);
  String get maturityDate => service.date(loan.maturityDate);
  String get actualDuration => item.loanAgeLabel;
  String get calendarDuration => item.loanAgeMonthsDaysLabel;
  String get chargeablePeriod {
    final months = item.verifiedChargeableInterestMonths;
    return months == 0
        ? 'Verified period unavailable'
        : '$months chargeable month${months == 1 ? '' : 's'}';
  }

  String get originalPrincipal => service.money(account.originalPrincipal);
  String get interestBreakdownTitle {
    final interestType = item.interestPeriodSnapshots.isEmpty
        ? account.interestType
        : item.interestPeriodSnapshots.first.interestType;
    final isSimple = GirviInterestCalculationType.isSimple(interestType);
    if (language == GirviNoticeLanguage.hindi) {
      return isSimple ? 'साधारण ब्याज विवरण' : 'चक्रवृद्धि ब्याज विवरण';
    }
    return isSimple
        ? 'Simple Interest Breakdown'
        : 'Compound Interest Breakdown';
  }

  String get netWeight => '${loan.netWeight.toStringAsFixed(3)} g';
  String get itemSummary => _cleanItemSummary(
        loan.itemDescription.trim().isEmpty
            ? loan.itemSummary
            : loan.itemDescription,
      );

  List<String> get outstandingSummaryLines {
    final hindi = language == GirviNoticeLanguage.hindi;
    return [
      '${hindi ? 'मूलधन बकाया' : 'Principal Outstanding'}: ${service.money(account.principalDue)}',
      '${hindi ? 'ब्याज बकाया' : 'Interest Outstanding'}: ${service.money(item.verifiedInterestDue)}',
      if (account.principalDiscountTotal > 0)
        '${hindi ? 'मूलधन समायोजन' : 'Principal Adjustment'}: ${service.money(account.principalDiscountTotal)}',
      if (account.interestDiscountTotal > 0)
        '${hindi ? 'ब्याज समायोजन' : 'Interest Adjustment'}: ${service.money(account.interestDiscountTotal)}',
      '${hindi ? 'अंतिम कुल देय राशि' : 'Final Total Payable'}: ${service.money(item.verifiedTotalPayable)}',
    ];
  }

  String _cleanItemSummary(String source) => source
      .replaceAllMapped(
          RegExp(r'#\s*(\d+)'), (match) => 'Serial Number ${match.group(1)}')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class _NoticeCopy {
  const _NoticeCopy({
    required this.title,
    required this.subject,
    required this.opening,
    required this.accountContext,
    required this.requiredAction,
    required this.closing,
  });

  final String title;
  final String subject;
  final String Function(_NoticeData data) opening;
  final String Function(_NoticeData data) accountContext;
  final String Function(_NoticeData data) requiredAction;
  final String Function(_NoticeData data) closing;

  factory _NoticeCopy.forStage(
      GirviNoticeType type, GirviNoticeLanguage language) {
    final hindi = language == GirviNoticeLanguage.hindi;
    switch (type) {
      case GirviNoticeType.first:
        return _NoticeCopy(
          title:
              hindi ? 'पहली गिरवी खाता सूचना' : 'FIRST PLEDGE ACCOUNT NOTICE',
          subject: hindi
              ? 'लंबित गिरवी खाते के लिए स्मरण सूचना'
              : 'Reminder for Pending Pledge Account Settlement',
          opening: (_) => hindi
              ? 'आपके नीचे दिए गए गिरवी खाते के संबंध में यह औपचारिक स्मरण सूचना जारी की जा रही है।'
              : 'This is a formal reminder regarding the pledge account referenced below.',
          accountContext: (_) => hindi
              ? 'खाता परिपक्वता तिथि के बाद भी लंबित है। सत्यापित बकाया राशि की समीक्षा और निपटान के लिए आपसे संपर्क अपेक्षित है।'
              : 'The account remains pending after maturity and requires your attention for review and settlement of the verified outstanding balance.',
          requiredAction: (data) => hindi
              ? 'कृपया ${data.deadline} तक दुकान पर आएं या संपर्क करें और भुगतान, निपटान या स्वीकार्य समाधान पर चर्चा करें।'
              : 'Please visit or contact the shop by ${data.deadline} to discuss payment, settlement, or an acceptable resolution.',
          closing: (_) => hindi
              ? 'यह पहली सूचना है। समय पर कार्रवाई से आगे की अनुवर्ती प्रक्रिया से बचा जा सकता है।'
              : 'This is the first notice. Timely action can prevent further follow-up.',
        );
      case GirviNoticeType.second:
        return _NoticeCopy(
          title:
              hindi ? 'दूसरी गिरवी खाता सूचना' : 'SECOND PLEDGE ACCOUNT NOTICE',
          subject: hindi
              ? 'लंबित गिरवी खाते के लिए अनुवर्ती सूचना'
              : 'Follow-up for Pending Pledge Account Settlement',
          opening: (_) => hindi
              ? 'यह सूचना आपके खाते के लिए पहले जारी की गई सूचना के संदर्भ में भेजी जा रही है।'
              : 'This notice is issued as a follow-up to the earlier notice for this pledge account.',
          accountContext: (_) => hindi
              ? 'खाता अब भी लंबित है। बकाया की समीक्षा और निपटान के लिए तुरंत संपर्क आवश्यक है।'
              : 'The account remains unsettled. Immediate contact is required to review the outstanding balance and complete settlement.',
          requiredAction: (data) => hindi
              ? 'कृपया ${data.deadline} तक दुकान से संपर्क करके आवश्यक कार्रवाई पूरी करें।'
              : 'Please contact the shop and complete the required action by ${data.deadline}.',
          closing: (_) => hindi
              ? 'निर्धारित अवधि में समाधान न होने पर यह मामला अंतिम सूचना समीक्षा में जा सकता है।'
              : 'If the account is not resolved within the notice period, it may proceed to final notice review.',
        );
      case GirviNoticeType.finalNotice:
        return _NoticeCopy(
          title:
              hindi ? 'अंतिम गिरवी खाता सूचना' : 'FINAL PLEDGE ACCOUNT NOTICE',
          subject: hindi
              ? 'गिरवी खाते के निपटान के लिए अंतिम सूचना'
              : 'Final Notice for Pledge Account Settlement',
          opening: (_) => hindi
              ? 'यह आपके गिरवी खाते के संबंध में अंतिम सूचना है। पहले जारी की गई सूचनाओं के बाद भी खाता लंबित है।'
              : 'This is the final notice for your pledge account. The account remains pending despite the earlier notices.',
          accountContext: (_) => hindi
              ? 'कृपया नीचे दिए गए सत्यापित खाते के विवरण की समीक्षा करें और निपटान के लिए तुरंत संपर्क करें।'
              : 'Please review the verified account details below and contact the shop immediately for settlement.',
          requiredAction: (data) => hindi
              ? 'कृपया ${data.deadline} तक भुगतान, निपटान या स्वीकार्य समाधान के लिए दुकान से संपर्क करें।'
              : 'Please contact the shop by ${data.deadline} for payment, settlement, or an acceptable resolution.',
          closing: (_) => hindi
              ? 'निर्धारित अवधि में कोई प्रतिक्रिया या समाधान नहीं मिलने पर मामला लागू शर्तों और कानून के अनुसार वसूली समीक्षा में भेजा जा सकता है।'
              : 'If no response or resolution is received within the stated period, the case may proceed to recovery review in accordance with the applicable terms and law.',
        );
    }
  }
}
