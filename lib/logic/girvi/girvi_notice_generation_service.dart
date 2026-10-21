import 'package:intl/intl.dart';

import '../../models/girvi/contact_recovery_model.dart';
import '../../models/girvi/girvi_enums.dart';
import '../../models/girvi/girvi_loan_model.dart';
import '../../models/girvi/girvi_notice_action_model.dart';
import 'girvi_notice_document.dart';
import 'girvi_notice_financial_timeline.dart';
import 'notice_pdf/notice_item_description.dart';

part 'notice/girvi_formal_notice_copy.dart';

/// Builds customer notices from verified Girvi account records.
/// Financial values remain owned by the existing account and ledger domain.
class GirviNoticeGenerationService {
  GirviNoticeGenerationService({DateTime? now, String? shopName})
      : _now = now ?? DateTime.now(),
        _shopName = shopName?.trim();

  final DateTime _now;
  final String? _shopName;
  final DateFormat _date = DateFormat('dd MMMM yyyy');
  final NumberFormat _money = NumberFormat('#,##,##0', 'en_IN');

  List<String> validate(ContactRecoveryCase item) {
    final account = item.account;
    final issues = <String>[];
    if (!item.hasVerifiedInterestTimeline) {
      issues.add(
        'Verified interest-period snapshots are missing. Refresh the financial ledger before preparing this notice.',
      );
    } else {
      final months = GirviLoanModel.chargeableMonthsBetween(
        item.loan.startDate,
        item.loan.releaseDate ?? item.now,
      );
      final requiredType =
          GirviInterestCalculationType.forChargeableMonths(months);
      if (item.interestPeriodSnapshots.any((snapshot) =>
          GirviInterestCalculationType.normalize(snapshot.interestType) !=
          requiredType)) {
        issues.add(
          'Interest method changed at month 13. Refresh the financial ledger before preparing this notice.',
        );
      }
      if (item.verifiedChargeableInterestMonths != months) {
        issues.add(
          'Verified interest months are out of date. Refresh the financial ledger before preparing this notice.',
        );
      }
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
    int? noticePeriodDays,
  }) =>
      buildDocument(
        item: item,
        noticeType: noticeType,
        language: language,
        noticePeriodDays: noticePeriodDays,
      ).toPlainText();

  GirviNoticeDocument buildDocument({
    required ContactRecoveryCase item,
    required GirviNoticeType noticeType,
    required GirviNoticeLanguage language,
    int? noticePeriodDays,
  }) {
    final copy = _NoticeCopy.forLanguage(language);
    final data = _NoticeData(
      item: item,
      noticeType: noticeType,
      service: this,
      language: language,
      noticePeriodDays: noticePeriodDays ?? item.noticePeriodDays,
    );
    return GirviNoticeDocument(
      language: language,
      title: language == GirviNoticeLanguage.english
          ? '${copy.title}: PLEDGE ACCOUNT ${data.ticketNo}'
          : '${copy.title}: ${data.ticketNo}',
      noticeNumber: data.noticeNumber,
      noticeDate: data.noticeDate,
      pledgeReference: data.ticketNo,
      subject: copy.subject(data),
      sections: [
        GirviNoticeSection(
          title: '',
          blocks: [
            GirviNoticeBlock(
              lines: [
                if (language == GirviNoticeLanguage.english) ...[
                  'To: ${data.customerName}',
                  if (data.account.customerAddress.trim().isNotEmpty)
                    'Customer Address: ${data.account.customerAddress.trim()}',
                  if (data.account.customerMobile.trim().isNotEmpty)
                    'Customer Mobile: ${data.account.customerMobile.trim()}',
                ],
                '${language == GirviNoticeLanguage.hindi ? 'प्रिय' : 'Dear'} ${data.customerName},',
                ...copy.opening(data),
                ...copy.accountContext(data),
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
                '${language == GirviNoticeLanguage.hindi ? 'वस्तु का नाम' : 'Item Name'}: ${data.itemName}',
                if (data.purity != null)
                  '${language == GirviNoticeLanguage.hindi ? 'शुद्धता' : 'Purity'}: ${data.purity}',
                '${language == GirviNoticeLanguage.hindi ? 'नेट वजन' : 'Net Weight'}: ${data.netWeight}',
                '${language == GirviNoticeLanguage.hindi ? 'मूल मूलधन' : 'Original Principal'}: ${data.originalPrincipal}',
                '${language == GirviNoticeLanguage.hindi ? 'गिरवी तारीख' : 'Pledge Date'}: ${data.startDate}',
                '${language == GirviNoticeLanguage.hindi ? 'परिपक्वता तारीख' : 'Maturity Date'}: ${data.maturityDate}',
                '${language == GirviNoticeLanguage.hindi ? 'मूल ऋण अवधि' : 'Original Loan Period'}: ${data.agreedLoanTerm}',
                '${language == GirviNoticeLanguage.hindi ? 'वर्तमान ऋण अवधि' : 'Current Loan Period'}: ${data.elapsedLoanPeriod}',
                '${language == GirviNoticeLanguage.hindi ? 'ब्याज योग्य महीने' : 'Chargeable Months'}: ${data.chargeablePeriod}',
              ],
            ),
          ],
        ),
        GirviNoticeSection(
          title: data.interestBreakdownTitle,
          blocks: [
            ...data.financialTimeline.interestBlocks(language),
            GirviNoticeBlock(lines: data.interestSummaryLines),
          ],
        ),
        GirviNoticeSection(
          title: language == GirviNoticeLanguage.hindi
              ? 'खाते का सारांश'
              : 'Account Summary',
          blocks: [GirviNoticeBlock(lines: data.outstandingSummaryLines)],
        ),
        GirviNoticeSection(
          title: language == GirviNoticeLanguage.hindi
              ? 'आवश्यक कार्रवाई'
              : 'Required Action',
          blocks: [
            GirviNoticeBlock(
              lines: [
                ...copy.requiredAction(data),
                language == GirviNoticeLanguage.hindi
                    ? 'निपटान न होने पर कार्रवाई'
                    : 'Consequence of Non-Settlement',
                ...copy.closing(data),
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
    required this.noticePeriodDays,
  }) : financialTimeline = GirviNoticeFinancialTimeline(
          item: item,
          money: service.money,
          date: service.date,
        );

  final ContactRecoveryCase item;
  final GirviNoticeType noticeType;
  final GirviNoticeGenerationService service;
  final GirviNoticeLanguage language;
  final int noticePeriodDays;
  final GirviNoticeFinancialTimeline financialTimeline;

  GirviLoanWithCustomer get account => item.account;
  GirviLoanModel get loan => item.loan;
  String get ticketNo => loan.ticketNo;
  String get noticeNumber {
    final priorFormalNotices = item.preparedNoticeActions
        .where((action) => action.isFormalNoticePreparation)
        .length;
    return priorFormalNotices == 0
        ? '$ticketNo-NOTICE'
        : '$ticketNo-NOTICE-R${priorFormalNotices + 1}';
  }

  String get noticeDate => service.date(service._now);
  String get responseDueDate => service.date(DateTime(
        service._now.year,
        service._now.month,
        service._now.day + noticePeriodDays,
      ));
  String get finalOutstanding => service.money(item.verifiedTotalPayable);
  String get shopName =>
      service._shopName?.isNotEmpty == true ? service._shopName! : 'our shop';
  String get customerName => account.customerName;
  String get startDate => service.date(loan.startDate);
  String get maturityDate => service.date(loan.maturityDate);
  String get agreedLoanTerm =>
      '${loan.durationMonths} month${loan.durationMonths == 1 ? '' : 's'}';
  String get elapsedLoanPeriod => item.loanAgeMonthsDaysLabel;
  String get chargeablePeriod {
    final months = item.verifiedChargeableInterestMonths;
    return months == 0
        ? 'Verified period unavailable'
        : '$months month${months == 1 ? '' : 's'}';
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
  String get pledgedItemSummary => [
        itemName,
        netWeight,
        if (purity != null) purity!,
      ].join(', ');
  String get interestCalculatedTo => item.interestPeriodSnapshots.isEmpty
      ? noticeDate
      : service.date(financialTimeline
          .displayPeriodEnd(item.interestPeriodSnapshots.last));

  List<String> get interestSummaryLines {
    final hindi = language == GirviNoticeLanguage.hindi;
    final snapshots = item.interestPeriodSnapshots;
    final isCompound = snapshots.isNotEmpty &&
        !GirviInterestCalculationType.isSimple(snapshots.first.interestType);
    return [
      if (snapshots.isNotEmpty)
        '${hindi ? 'ब्याज अवधि शुरू' : 'Interest Period From'}: ${service.date(snapshots.first.periodFrom)}',
      if (snapshots.isNotEmpty)
        '${hindi ? 'ब्याज अवधि समाप्त' : 'Interest Period To'}: ${service.date(financialTimeline.displayPeriodEnd(snapshots.last))}',
      if (isCompound)
        '${hindi ? 'चक्रवृद्धि चक्र' : 'Compounding Cycle'}: ${hindi ? 'हर' : 'Every'} ${GirviLoanModel.compoundCycleMonths} ${hindi ? 'माह' : 'months'}',
      '${hindi ? 'कुल ब्याज' : 'Gross Interest'}: ${service.money(item.verifiedGrossInterest)}',
      '${hindi ? 'प्राप्त ब्याज कुल' : 'Interest Paid Total'}: ${service.money(account.interestPaidTotal)}',
      '${hindi ? 'ब्याज समायोजन कुल' : 'Interest Adjustment Total'}: ${service.money(account.interestDiscountTotal)}',
      '${hindi ? 'ब्याज बकाया' : 'Interest Outstanding'}: ${service.money(item.verifiedInterestDue)}',
    ];
  }

  String get itemName =>
      NoticeItemDescription.itemNames(loan.itemDescription) ??
      'Item not recorded';
  String? get purity => NoticeItemDescription.purity(
        loan.itemDescription,
        fallback: loan.metalPurity,
      );

  List<String> get outstandingSummaryLines {
    final hindi = language == GirviNoticeLanguage.hindi;
    final principalReceived =
        account.principalPaidTotal + account.legacyPrincipalRepaidTotal;
    final interestReceived = account.interestPaidTotal;
    final totalReceived = principalReceived + interestReceived;
    final totalAdjustments =
        account.principalDiscountTotal + account.interestDiscountTotal;
    return [
      '${hindi ? 'मूलधन राशि' : 'Principal Amount'}: ${service.money(account.originalPrincipal)}',
      '${hindi ? 'कुल ब्याज' : 'Total Interest'}: ${service.money(item.verifiedGrossInterest)}',
      '${hindi ? 'कुल राशि' : 'Total Amount'}: ${service.money(account.originalPrincipal + item.verifiedGrossInterest)}',
      if (totalReceived > 0)
        '${hindi ? 'प्राप्त भुगतान' : 'Payments Received'}: ${service.money(totalReceived)}',
      if (totalAdjustments > 0)
        '${hindi ? 'स्वीकृत छूट' : 'Approved Discount'}: ${service.money(totalAdjustments)}',
      '${hindi ? 'अंतिम बकाया राशि' : 'Final Outstanding'}: ${service.money(item.verifiedTotalPayable)}',
    ];
  }
}
