import 'package:intl/intl.dart';

import '../../models/girvi/contact_recovery_model.dart';
import '../../models/girvi/girvi_customer_response_model.dart';
import '../../models/girvi/girvi_enums.dart';
import '../../models/girvi/girvi_loan_model.dart';
import '../../models/girvi/girvi_notice_action_model.dart';
import 'girvi_notice_document.dart';
import 'girvi_notice_financial_timeline.dart';

part 'notice/girvi_formal_notice_copy.dart';

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
    final copy = _NoticeCopy.forLanguage(language);
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
        if (data.priorCustomerResponses.isNotEmpty)
          GirviNoticeSection(
            title: language == GirviNoticeLanguage.hindi
                ? 'पूर्व संपर्क और ग्राहक प्रतिक्रिया'
                : 'Previous Contact and Customer Response',
            blocks: data.customerResponseBlocks,
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
  String get noticeNumber => '$ticketNo-NOTICE';
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

  List<GirviCustomerResponse> get priorCustomerResponses {
    final responses = item.customerResponses
        .where((response) => !response.receivedAt.isAfter(service._now))
        .toList();
    responses.sort((a, b) => a.receivedAt.compareTo(b.receivedAt));
    return responses;
  }

  List<GirviNoticeBlock> get customerResponseBlocks {
    final hindi = language == GirviNoticeLanguage.hindi;
    return [
      for (final response in priorCustomerResponses)
        GirviNoticeBlock(
          heading:
              '${hindi ? 'संपर्क' : 'Contact'} · ${service.date(response.receivedAt)}',
          lines: [
            '${hindi ? 'माध्यम' : 'Channel'}: ${_channelLabel(response, hindi)}',
            '${hindi ? 'ग्राहक का कथन' : 'Customer Statement'}: ${response.responseText}',
            if (response.isPromise)
              '${hindi ? 'प्रतिबद्धता' : 'Commitment'}: ${_responseKindLabel(response, hindi)}',
            if (response.promiseDueAt != null)
              '${hindi ? 'वादा की तारीख' : 'Promised Date'}: ${service.date(response.promiseDueAt)}',
            if (response.promisedAmount != null)
              '${hindi ? 'वादा की राशि' : 'Promised Amount'}: ${service.money(response.promisedAmount!)}',
            '${hindi ? 'रिकॉर्ड की स्थिति' : 'Recorded Status'}: ${_statusLabel(response, hindi)}',
          ],
        ),
    ];
  }

  String _channelLabel(GirviCustomerResponse response, bool hindi) {
    if (!hindi) return response.channel.label;
    return switch (response.channel) {
      GirviContactChannel.shopVisit => 'दुकान पर मुलाकात',
      GirviContactChannel.phoneCall => 'फोन कॉल',
      GirviContactChannel.whatsapp => 'व्हाट्सऐप',
      GirviContactChannel.sms => 'एसएमएस',
      GirviContactChannel.email => 'ईमेल',
      GirviContactChannel.registeredPost => 'पंजीकृत डाक',
      GirviContactChannel.other => 'अन्य माध्यम',
    };
  }

  String _responseKindLabel(GirviCustomerResponse response, bool hindi) {
    if (!hindi) return response.kind.label;
    return switch (response.kind) {
      GirviCustomerResponseKind.willVisit => 'दुकान आने का वादा',
      GirviCustomerResponseKind.fullSettlement => 'पूर्ण निपटान का वादा',
      GirviCustomerResponseKind.partialPayment => 'आंशिक भुगतान का वादा',
      GirviCustomerResponseKind.extensionRequest => 'अतिरिक्त समय का अनुरोध',
      GirviCustomerResponseKind.amountDispute => 'बकाया राशि पर आपत्ति',
      GirviCustomerResponseKind.recoveryRequest => 'वसूली निपटान का अनुरोध',
      GirviCustomerResponseKind.noResponse =>
        'कोई प्रतिक्रिया प्राप्त नहीं हुई',
      GirviCustomerResponseKind.other => 'अन्य प्रतिक्रिया',
    };
  }

  String _statusLabel(GirviCustomerResponse response, bool hindi) {
    if (!hindi) {
      return response.isDueOn(item.now) ? 'Past due' : response.status.label;
    }
    if (response.isDueOn(item.now)) return 'वादा की तिथि बीत चुकी है';
    return switch (response.status) {
      GirviPromiseStatus.open => 'खुला',
      GirviPromiseStatus.fulfilled => 'पूरा हुआ',
      GirviPromiseStatus.partiallyFulfilled => 'आंशिक रूप से पूरा हुआ',
      GirviPromiseStatus.missed => 'पूरा नहीं हुआ',
      GirviPromiseStatus.cancelled => 'रद्द',
      GirviPromiseStatus.recorded => 'रिकॉर्ड किया गया',
    };
  }

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
