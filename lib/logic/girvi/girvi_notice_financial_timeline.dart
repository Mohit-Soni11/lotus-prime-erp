import '../../models/girvi/contact_recovery_model.dart';
import '../../models/girvi/girvi_enums.dart';
import '../../models/girvi/girvi_interest_period_snapshot.dart';
import '../../models/girvi/girvi_loan_model.dart';
import '../../models/girvi/girvi_notice_action_model.dart';
import 'girvi_notice_document.dart';

/// Read-only notice view of the persisted account and interest timeline.
/// This class intentionally contains no interest calculator. Its only source
/// for period values is the financial snapshot ledger.
class GirviNoticeFinancialTimeline {
  const GirviNoticeFinancialTimeline({
    required this.item,
    required this.money,
    required this.date,
  });

  final ContactRecoveryCase item;
  final String Function(double value) money;
  final String Function(DateTime? value) date;

  GirviLoanWithCustomer get _account => item.account;
  List<GirviPaymentModel> get _interestPayments {
    final entries = item.paymentHistory.where((payment) {
      if (payment.type == GirviPaymentType.interest ||
          payment.type == GirviPaymentType.partialInterest) {
        return true;
      }
      return payment.interestComponent > 0 ||
          payment.interestDiscountComponent > 0;
    }).toList()
      ..sort((a, b) => a.paymentDate.compareTo(b.paymentDate));
    return entries;
  }

  List<GirviNoticeBlock> interestBlocks(GirviNoticeLanguage language) {
    if (!item.hasVerifiedInterestTimeline) {
      final isHindi = language == GirviNoticeLanguage.hindi;
      return [
        GirviNoticeBlock(
          lines: [
            isHindi
                ? 'सत्यापित ब्याज अवधि विवरण उपलब्ध नहीं है। सूचना तैयार नहीं की जा सकती।'
                : 'Verified interest-period records are unavailable. This notice cannot be prepared safely.',
          ],
        ),
      ];
    }
    if (GirviInterestCalculationType.isSimple(
        item.interestPeriodSnapshots.first.interestType)) {
      return _simpleBlocks(language);
    }
    return _compoundBlocks(language);
  }

  List<GirviNoticeBlock> _simpleBlocks(GirviNoticeLanguage language) {
    final isHindi = language == GirviNoticeLanguage.hindi;
    return [
      for (final snapshot in item.interestPeriodSnapshots)
        GirviNoticeBlock(
          heading: isHindi ? 'साधारण ब्याज अवधि' : 'Simple Interest Period',
          lines: _snapshotLines(snapshot,
              isHindi: isHindi,
              closingLabel: isHindi
                  ? 'क्लोजिंग / बकाया राशि'
                  : 'Closing / Outstanding Amount'),
        ),
    ];
  }

  List<GirviNoticeBlock> _compoundBlocks(GirviNoticeLanguage language) {
    final isHindi = language == GirviNoticeLanguage.hindi;
    final snapshots = item.interestPeriodSnapshots;
    if (snapshots.isEmpty) {
      return [
        GirviNoticeBlock(
          lines: [
            isHindi
                ? 'चक्रवृद्धि ब्याज अवधि का सत्यापित विवरण उपलब्ध नहीं है।'
                : 'The verified compound-interest timeline is not available for this account.',
          ],
        ),
      ];
    }

    return [
      for (final snapshot in snapshots)
        _compoundBlock(snapshot, isHindi: isHindi),
    ];
  }

  GirviNoticeBlock _compoundBlock(
    GirviInterestPeriodSnapshot snapshot, {
    required bool isHindi,
  }) {
    final fullCycle =
        snapshot.chargeableMonths == GirviLoanModel.compoundCycleMonths;
    final label = fullCycle
        ? (isHindi
            ? 'चक्रवृद्धि अवधि ${snapshot.sequence}'
            : 'Compound Period ${snapshot.sequence}')
        : (isHindi ? 'शेष चक्रवृद्धि अवधि' : 'Remaining Compound Period');
    return GirviNoticeBlock(
      heading:
          '$label - ${date(snapshot.periodFrom)} ${isHindi ? 'से' : 'to'} ${date(snapshot.periodTo)}',
      lines: _snapshotLines(snapshot,
          isHindi: isHindi,
          closingLabel: isHindi ? 'क्लोजिंग राशि' : 'Closing Amount'),
    );
  }

  List<String> _snapshotLines(
    GirviInterestPeriodSnapshot snapshot, {
    required bool isHindi,
    required String closingLabel,
  }) {
    return [
      '${isHindi ? 'अवधि' : 'Period'}: ${date(snapshot.periodFrom)} ${isHindi ? 'से' : 'to'} ${date(snapshot.periodTo)}',
      '${isHindi ? 'ओपनिंग राशि' : 'Opening Amount'}: ${money(snapshot.openingAmount)}',
      '${isHindi ? 'मासिक ब्याज दर' : 'Monthly Interest Rate'}: ${snapshot.monthlyRatePercent.toStringAsFixed(2)}%',
      '${isHindi ? 'एक माह का ब्याज' : 'Interest per Month'}: ${money(snapshot.interestPerMonth)}',
      '${isHindi ? 'चार्जेबल माह' : 'Chargeable Months'}: ${snapshot.chargeableMonths}',
      '${isHindi ? 'इस अवधि का ब्याज' : 'Interest for Period'}: ${money(snapshot.periodInterest)}',
      '$closingLabel: ${money(snapshot.closingAmount)}',
    ];
  }

  List<GirviNoticeBlock> paymentBlocks(GirviNoticeLanguage language) {
    final isHindi = language == GirviNoticeLanguage.hindi;
    if (_interestPayments.isEmpty && !_hasAdjustments) {
      return const [];
    }

    return [
      for (final payment in _interestPayments)
        GirviNoticeBlock(
          heading: date(payment.paymentDate),
          lines: [
            '${isHindi ? 'माध्यम' : 'Mode'}: ${payment.mode.displayName}',
            '${isHindi ? 'ब्याज प्राप्त' : 'Interest Received'}: ${money(payment.interestComponent > 0 ? payment.interestComponent : payment.amount)}',
            if (payment.interestDiscountComponent > 0)
              '${isHindi ? 'ब्याज समायोजन' : 'Interest Adjustment'}: ${money(payment.interestDiscountComponent)}',
            '${isHindi ? 'अवधि' : 'Interest Period'}: ${_paymentPeriod(payment, isHindi: isHindi)}',
          ],
        ),
      if (_hasAdjustments)
        GirviNoticeBlock(
          heading: isHindi ? 'लागू समायोजन' : 'Applicable Adjustments',
          lines: [
            if (_account.principalDiscountTotal > 0)
              '${isHindi ? 'मूलधन समायोजन' : 'Principal Adjustment'}: ${money(_account.principalDiscountTotal)}',
            if (_account.interestDiscountTotal > 0)
              '${isHindi ? 'ब्याज समायोजन' : 'Interest Adjustment'}: ${money(_account.interestDiscountTotal)}',
          ],
        ),
    ];
  }

  bool get _hasAdjustments =>
      _account.principalDiscountTotal > 0 || _account.interestDiscountTotal > 0;

  String _paymentPeriod(GirviPaymentModel payment, {required bool isHindi}) {
    final from = payment.interestFromDate;
    final to = payment.interestToDate;
    final months = payment.monthsCovered;
    final monthText = months == null || months <= 0
        ? ''
        : ' ($months ${isHindi ? 'माह' : 'month${months == 1 ? '' : 's'}'})';
    if (from != null && to != null) {
      return '${date(from)} ${isHindi ? 'से' : 'to'} ${date(to)}$monthText';
    }
    return monthText.isEmpty
        ? (isHindi ? 'रिकॉर्ड में उपलब्ध नहीं' : 'Not recorded')
        : monthText.trim();
  }
}
