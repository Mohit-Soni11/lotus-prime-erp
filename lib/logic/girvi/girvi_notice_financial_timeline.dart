import '../../models/girvi/contact_recovery_model.dart';
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

  /// A completed cycle ends the day before the next cycle starts. An open
  /// cycle is shown only through the account's calculation date.
  DateTime displayPeriodEnd(GirviInterestPeriodSnapshot snapshot) {
    if (GirviInterestCalculationType.normalize(snapshot.interestType) ==
            GirviInterestCalculationType.compound &&
        snapshot.finalized &&
        snapshot.chargeableMonths == GirviLoanModel.compoundCycleMonths) {
      return snapshot.periodTo.subtract(const Duration(days: 1));
    }
    final asOf = item.loan.releaseDate ?? item.now;
    return snapshot.periodTo.isAfter(asOf) ? asOf : snapshot.periodTo;
  }

  List<GirviPaymentModel> get _receivedPayments {
    final entries = item.paymentHistory
        .where((payment) => payment.amount > 0)
        .toList()
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
          '$label - ${date(snapshot.periodFrom)} ${isHindi ? 'से' : 'to'} ${date(displayPeriodEnd(snapshot))}',
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
      '${isHindi ? 'अवधि' : 'Period'}: ${date(snapshot.periodFrom)} ${isHindi ? 'से' : 'to'} ${date(displayPeriodEnd(snapshot))}',
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
    return [
      for (final payment in _receivedPayments)
        GirviNoticeBlock(
          heading: date(payment.paymentDate),
          lines: [
            '${isHindi ? 'माध्यम' : 'Mode'}: ${payment.mode.displayName}',
            '${isHindi ? 'प्राप्त भुगतान' : 'Amount Received'}: ${money(payment.amount)}',
          ],
        ),
    ];
  }
}
