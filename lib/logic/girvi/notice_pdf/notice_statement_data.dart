import 'package:intl/intl.dart';

import '../../../models/girvi/girvi_notice_action_model.dart';
import 'notice_item_description.dart';
import 'notice_period_display.dart';

/// Reads the approved notice text so a later download cannot silently pick up
/// changed loan balances or interest settings.
class NoticeStatementData {
  NoticeStatementData._({
    required this.language,
    required this.lines,
    required this.values,
    required this.periods,
    this.financialAsOf,
    this.compoundOverride,
  });

  final GirviNoticeLanguage language;
  final List<String> lines;
  final Map<String, String> values;
  final List<NoticeInterestPeriod> periods;
  final DateTime? financialAsOf;
  final bool? compoundOverride;

  /// Keeps the approved wording intact while showing a separately dated,
  /// verified account calculation for a superseded interest method.
  NoticeStatementData withVerifiedFinancials(
    NoticeStatementData verified, {
    required DateTime asOf,
  }) {
    if (language != verified.language || !verified.hasInterestMethod) {
      throw ArgumentError('A matching verified notice statement is required.');
    }
    const financialKeys = <String>{
      'Pledged Item',
      'Item Name',
      'Purity',
      'Net Weight',
      'Original Principal',
      'Principal Amount',
      'Pledge Date',
      'Maturity Date',
      'Original Loan Period',
      'Current Loan Period',
      'Chargeable Months',
      'Principal Outstanding',
      'Interest Outstanding',
      'Final Total Payable',
      'Final Outstanding',
      'Interest Period From',
      'Interest Period To',
      'Compounding Cycle',
      'Gross Interest',
      'Total Interest',
      'Total Account Charges',
      'Total Amount',
      'Principal Paid Total',
      'Interest Paid Total',
      'Interest Adjustment Total',
      'Principal Adjustment',
      'Interest Adjustment',
      'Total Received',
      'Payments Received',
      'Total Adjustments',
      'Approved Discount',
      'गिरवी वस्तु',
      'वस्तु का नाम',
      'शुद्धता',
      'नेट वजन',
      'मूल मूलधन',
      'मूलधन राशि',
      'गिरवी तारीख',
      'परिपक्वता तारीख',
      'मूल ऋण अवधि',
      'वर्तमान ऋण अवधि',
      'ब्याज योग्य महीने',
      'मूलधन बकाया',
      'ब्याज बकाया',
      'अंतिम कुल देय राशि',
      'अंतिम बकाया राशि',
      'ब्याज अवधि शुरू',
      'ब्याज अवधि समाप्त',
      'चक्रवृद्धि चक्र',
      'कुल ब्याज',
      'कुल खाता राशि',
      'कुल राशि',
      'प्राप्त मूलधन कुल',
      'प्राप्त ब्याज कुल',
      'ब्याज समायोजन कुल',
      'मूलधन समायोजन',
      'ब्याज समायोजन',
      'कुल प्राप्त राशि',
      'प्राप्त भुगतान',
      'कुल समायोजन',
      'स्वीकृत छूट',
    };
    final currentValues = Map<String, String>.of(values)
      ..removeWhere((key, _) => financialKeys.contains(key));
    for (final entry in verified.values.entries) {
      if (financialKeys.contains(entry.key)) {
        currentValues[entry.key] = entry.value;
      }
    }
    return NoticeStatementData._(
      language: language,
      lines: lines,
      values: Map.unmodifiable(currentValues),
      periods: verified.periods,
      financialAsOf: asOf,
      compoundOverride: verified.isCompound,
    );
  }

  bool get isHindi => language == GirviNoticeLanguage.hindi;

  /// Account figures already appear in the statement on page one. Keep every
  /// customer-facing narrative and contact/payment note on the following page.
  List<String> get importantLines {
    final accountHeading =
        isHindi ? 'गिरवी खाता और अवधि' : 'Pledge Account and Duration';
    final interestHeadings = isHindi
        ? {'साधारण ब्याज विवरण', 'चक्रवृद्धि ब्याज विवरण'}
        : {'Simple Interest Breakdown', 'Compound Interest Breakdown'};
    final finalHeadings = isHindi
        ? {'अंतिम बकाया सारांश', 'खाते का सारांश'}
        : {'Final Outstanding Summary', 'Account Summary'};
    final responseHeading = isHindi
        ? 'पूर्व संपर्क और ग्राहक प्रतिक्रिया'
        : 'Previous Contact and Customer Response';
    final paymentHeadings = isHindi
        ? {'भुगतान और समायोजन', 'प्राप्त भुगतान'}
        : {'Payments and Adjustments', 'Payments Received'};
    final actionHeading = isHindi ? 'आवश्यक कार्रवाई' : 'Required Action';
    final hasSections =
        lines.contains(accountHeading) && lines.contains(actionHeading);
    if (!hasSections) return lines;

    final result = <String>[];
    var keep = false;
    var started = false;
    for (final line in lines) {
      if (line.startsWith(isHindi ? 'विषय:' : 'Subject:')) {
        started = true;
        keep = true;
        continue;
      }
      if (!started) continue;
      if (line == responseHeading ||
          paymentHeadings.contains(line) ||
          line == actionHeading) {
        keep = true;
      } else if (line == accountHeading ||
          interestHeadings.contains(line) ||
          finalHeadings.contains(line)) {
        keep = false;
        continue;
      }
      if (keep || (line.isNotEmpty && !_isDisplayedFact(line))) {
        result.add(line);
      }
    }
    return result;
  }

  bool _isDisplayedFact(String line) {
    if (line == (isHindi ? 'साधारण ब्याज अवधि' : 'Simple Interest Period') ||
        line.startsWith(isHindi ? 'चक्रवृद्धि अवधि ' : 'Compound Period ') ||
        line.startsWith(
            isHindi ? 'शेष चक्रवृद्धि अवधि' : 'Remaining Compound Period')) {
      return true;
    }
    final divider = line.indexOf(':');
    if (divider < 1) return false;
    final key = line.substring(0, divider).trim();
    final displayedKeys = isHindi
        ? <String>{
            'गिरवी वस्तु',
            'वस्तु का नाम',
            'शुद्धता',
            'नेट वजन',
            'मूल मूलधन',
            'मूलधन राशि',
            'गिरवी तारीख',
            'परिपक्वता तारीख',
            'वास्तविक अवधि',
            'सहमति की ऋण अवधि',
            'बीती हुई ऋण अवधि',
            'गिरवी रखने की अवधि',
            'गिरवी रखे हुए समय',
            'ब्याज की गणना अवधि',
            'मूल ऋण अवधि',
            'वर्तमान ऋण अवधि',
            'ब्याज योग्य महीने',
            'कुल कैलेंडर अवधि',
            'चार्जेबल ब्याज अवधि',
            'अवधि',
            'ओपनिंग राशि',
            'मासिक ब्याज दर',
            'एक माह का ब्याज',
            'चार्जेबल माह',
            'इस अवधि का ब्याज',
            'क्लोजिंग राशि',
            'क्लोजिंग / बकाया राशि',
            'मूलधन बकाया',
            'ब्याज बकाया',
            'मूलधन समायोजन',
            'ब्याज समायोजन',
            'अंतिम कुल देय राशि',
            'अंतिम बकाया राशि',
            'ब्याज अवधि शुरू',
            'ब्याज अवधि समाप्त',
            'चक्रवृद्धि चक्र',
            'कुल ब्याज',
            'कुल खाता राशि',
            'कुल राशि',
            'प्राप्त मूलधन कुल',
            'प्राप्त ब्याज कुल',
            'ब्याज समायोजन कुल',
            'कुल प्राप्त राशि',
            'प्राप्त भुगतान',
            'कुल समायोजन',
            'स्वीकृत छूट',
          }
        : <String>{
            'Pledged Item',
            'Item Name',
            'Purity',
            'Net Weight',
            'Original Principal',
            'Principal Amount',
            'Pledge Date',
            'Maturity Date',
            'Actual Duration',
            'Agreed Loan Term',
            'Elapsed Loan Period',
            'Pledged For',
            'Time Since Pledge',
            'Interest Charged For',
            'Original Loan Period',
            'Current Loan Period',
            'Total Calendar Duration',
            'Chargeable Interest Period',
            'Period',
            'Opening Amount',
            'Monthly Interest Rate',
            'Interest per Month',
            'Chargeable Months',
            'Interest for Period',
            'Closing Amount',
            'Closing / Outstanding Amount',
            'Principal Outstanding',
            'Interest Outstanding',
            'Principal Adjustment',
            'Interest Adjustment',
            'Final Total Payable',
            'Final Outstanding',
            'Interest Period From',
            'Interest Period To',
            'Compounding Cycle',
            'Gross Interest',
            'Total Interest',
            'Total Account Charges',
            'Total Amount',
            'Principal Paid Total',
            'Interest Paid Total',
            'Interest Adjustment Total',
            'Total Received',
            'Payments Received',
            'Total Adjustments',
            'Approved Discount',
          };
    return displayedKeys.contains(key);
  }

  String? value(String english, String hindi) =>
      values[isHindi ? hindi : english];

  String? get noticeNumber => value('Notice Number', 'सूचना नंबर');
  String? get noticeDate => value('Notice Date', 'सूचना दिनांक');
  String? get pledgeReference => value('Pledge Reference', 'गिरवी संदर्भ');
  String? get subject => value('Subject', 'विषय');
  String? get pledgedItem => value('Pledged Item', 'गिरवी वस्तु');
  String? get itemName =>
      value('Item Name', 'वस्तु का नाम') ??
      (pledgedItem == null
          ? null
          : NoticeItemDescription.itemNames(pledgedItem!));
  String? get purity =>
      value('Purity', 'शुद्धता') ??
      (pledgedItem == null ? null : NoticeItemDescription.purity(pledgedItem!));
  String? get netWeight => value('Net Weight', 'नेट वजन');
  String? get originalPrincipal =>
      value('Principal Amount', 'मूलधन राशि') ??
      value('Original Principal', 'मूल मूलधन');
  String? get pledgeDate => value('Pledge Date', 'गिरवी तारीख');
  String? get maturityDate => value('Maturity Date', 'परिपक्वता तारीख');
  String? get actualDuration => value('Actual Duration', 'वास्तविक अवधि');
  String? get agreedLoanTerm =>
      value('Original Loan Period', 'मूल ऋण अवधि') ??
      value('Pledged For', 'गिरवी रखने की अवधि') ??
      value('Agreed Loan Term', 'सहमति की ऋण अवधि');
  String originalLoanPeriodLabel(int? invoiceDurationMonths) {
    if (agreedLoanTerm != null) return agreedLoanTerm!;
    if (invoiceDurationMonths == null || invoiceDurationMonths <= 0) {
      return 'Not recorded';
    }
    return '$invoiceDurationMonths month${invoiceDurationMonths == 1 ? '' : 's'}';
  }

  String? get elapsedLoanPeriod =>
      value('Current Loan Period', 'वर्तमान ऋण अवधि') ??
      value('Time Since Pledge', 'गिरवी रखे हुए समय') ??
      value('Elapsed Loan Period', 'बीती हुई ऋण अवधि') ??
      calendarDuration ??
      actualDuration;
  String? get calendarDuration =>
      value('Total Calendar Duration', 'कुल कैलेंडर अवधि');
  String? get chargeablePeriod =>
      value('Chargeable Months', 'ब्याज योग्य महीने') ??
      value('Interest Charged For', 'ब्याज की गणना अवधि') ??
      value('Chargeable Interest Period', 'चार्जेबल ब्याज अवधि');
  String? get principalOutstanding =>
      value('Principal Outstanding', 'मूलधन बकाया');
  String? get interestOutstanding =>
      value('Interest Outstanding', 'ब्याज बकाया');
  String? get totalPayable =>
      value('Final Outstanding', 'अंतिम बकाया राशि') ??
      value('Final Total Payable', 'अंतिम कुल देय राशि');
  String? get totalAccountCharges =>
      value('Total Amount', 'कुल राशि') ??
      value('Total Account Charges', 'कुल खाता राशि') ??
      _sumAmounts(originalPrincipal, grossInterest, requireBoth: true);
  String? get principalPaidTotal =>
      value('Principal Paid Total', 'प्राप्त मूलधन कुल');
  String? get totalReceived =>
      value('Payments Received', 'प्राप्त भुगतान') ??
      value('Total Received', 'कुल प्राप्त राशि') ??
      _sumAmounts(principalPaidTotal, interestPaidTotal);
  String? get principalAdjustment =>
      value('Principal Adjustment', 'मूलधन समायोजन');
  String? get interestAdjustment =>
      value('Interest Adjustment', 'ब्याज समायोजन') ?? interestAdjustmentTotal;
  String? get totalAdjustments =>
      value('Approved Discount', 'स्वीकृत छूट') ??
      value('Total Adjustments', 'कुल समायोजन') ??
      _sumAmounts(principalAdjustment, interestAdjustment);

  String? _sumAmounts(String? first, String? second,
      {bool requireBoth = false}) {
    if (first == null && second == null) return null;
    if (requireBoth && (first == null || second == null)) return null;
    if (first == null) return second;
    if (second == null) return first;
    final left = double.tryParse(first.replaceAll(RegExp(r'[^0-9.-]'), ''));
    final right = double.tryParse(second.replaceAll(RegExp(r'[^0-9.-]'), ''));
    if (left == null || right == null) return null;
    final prefix = first.trimLeft().startsWith('₹') ? '₹' : 'Rs';
    return '$prefix ${NumberFormat('#,##,##0.##', 'en_IN').format(left + right)}';
  }

  String? get interestPeriodFrom =>
      value('Interest Period From', 'ब्याज अवधि शुरू') ??
      periods.firstOrNull
          ?.value('Period', 'अवधि', language)
          ?.split(' to ')
          .first;
  String? get interestPeriodTo {
    final recorded = value('Interest Period To', 'ब्याज अवधि समाप्त') ??
        periods.lastOrNull
            ?.value('Period', 'अवधि', language)
            ?.split(' to ')
            .last;
    final asOf =
        financialAsOf ?? NoticePeriodDisplay.parseNoticeDate(noticeDate);
    final recordedDate = NoticePeriodDisplay.parseNoticeDate(recorded);
    if (asOf != null && recordedDate != null && recordedDate.isAfter(asOf)) {
      return DateFormat('dd MMMM yyyy').format(asOf);
    }
    return recorded;
  }

  String? get compoundingCycle => value('Compounding Cycle', 'चक्रवृद्धि चक्र');
  String? get grossInterest {
    final recorded = value('Total Interest', 'कुल ब्याज') ??
        value('Gross Interest', 'कुल ब्याज');
    if (recorded != null || periods.isEmpty) return recorded;
    var total = 0.0;
    for (final period in periods) {
      final raw =
          period.value('Interest for Period', 'इस अवधि का ब्याज', language);
      if (raw == null) return null;
      final amount = double.tryParse(raw.replaceAll(RegExp(r'[^0-9.-]'), ''));
      if (amount == null) return null;
      total += amount;
    }
    final prefix = periods.first
                .value('Interest for Period', 'इस अवधि का ब्याज', language)
                ?.trimLeft()
                .startsWith('₹') ==
            true
        ? '₹'
        : 'Rs';
    return '$prefix ${NumberFormat('#,##,##0.##', 'en_IN').format(total)}';
  }

  String? get interestPaidTotal =>
      value('Interest Paid Total', 'प्राप्त ब्याज कुल');
  String? get interestAdjustmentTotal =>
      value('Interest Adjustment Total', 'ब्याज समायोजन कुल');
  bool get hasInterestPayment => _hasPositiveAmount(interestPaidTotal);
  bool get hasInterestAdjustment => _hasPositiveAmount(interestAdjustmentTotal);
  bool get hasPayments =>
      _hasPositiveAmount(principalPaidTotal) ||
      hasInterestPayment ||
      _hasPositiveAmount(totalReceived);
  bool get hasAdjustments =>
      _hasPositiveAmount(principalAdjustment) ||
      _hasPositiveAmount(interestAdjustment) ||
      _hasPositiveAmount(totalAdjustments);

  bool _hasPositiveAmount(String? formatted) {
    if (formatted == null) return false;
    final amount =
        double.tryParse(formatted.replaceAll(RegExp(r'[^0-9.-]'), ''));
    return amount != null && amount > 0;
  }

  String? get monthlyRate {
    final rates = periods
        .map((period) =>
            period.value('Monthly Interest Rate', 'मासिक ब्याज दर', language))
        .whereType<String>()
        .toSet();
    if (rates.length == 1) return rates.first;
    return rates.length > 1 ? 'Varies by period' : null;
  }

  bool get isCompound =>
      compoundOverride ??
      lines.any((line) =>
          line ==
          (isHindi ? 'चक्रवृद्धि ब्याज विवरण' : 'Compound Interest Breakdown'));
  bool get isSimple => compoundOverride == null
      ? lines.any((line) =>
          line ==
          (isHindi ? 'साधारण ब्याज विवरण' : 'Simple Interest Breakdown'))
      : !compoundOverride!;
  bool get hasInterestMethod => isSimple || isCompound;

  static NoticeStatementData parse(
    String text,
    GirviNoticeLanguage language,
  ) {
    final lines = text
        .replaceAll('\r\n', '\n')
        .split('\n')
        .map((line) => line.trim())
        .toList(growable: false);
    final values = <String, String>{};
    final periods = <NoticeInterestPeriod>[];
    final interestHeading = language == GirviNoticeLanguage.hindi
        ? {'साधारण ब्याज विवरण', 'चक्रवृद्धि ब्याज विवरण'}
        : {'Simple Interest Breakdown', 'Compound Interest Breakdown'};
    final interestEnd = language == GirviNoticeLanguage.hindi
        ? {
            'भुगतान और समायोजन',
            'प्राप्त भुगतान',
            'अंतिम बकाया सारांश',
            'खाते का सारांश',
            'आवश्यक कार्रवाई'
          }
        : {
            'Payments and Adjustments',
            'Payments Received',
            'Final Outstanding Summary',
            'Account Summary',
            'Required Action'
          };
    final periodKey = language == GirviNoticeLanguage.hindi ? 'अवधि' : 'Period';
    final closingKeys = language == GirviNoticeLanguage.hindi
        ? {'क्लोजिंग राशि', 'क्लोजिंग / बकाया राशि'}
        : {'Closing Amount', 'Closing / Outstanding Amount'};
    var inInterest = false;
    Map<String, String>? currentPeriod;

    for (final line in lines) {
      if (interestHeading.contains(line)) {
        inInterest = true;
        continue;
      }
      if (interestEnd.contains(line)) {
        inInterest = false;
        if (currentPeriod != null) {
          periods.add(NoticeInterestPeriod(Map.unmodifiable(currentPeriod)));
          currentPeriod = null;
        }
      }
      final separator = line.indexOf(':');
      if (separator < 1) continue;
      final key = line.substring(0, separator).trim();
      final value = line.substring(separator + 1).trim();
      if (value.isEmpty) continue;
      values.putIfAbsent(key, () => value);
      if (!inInterest) continue;
      if (key == periodKey) {
        if (currentPeriod != null) {
          periods.add(NoticeInterestPeriod(Map.unmodifiable(currentPeriod)));
        }
        currentPeriod = <String, String>{};
      }
      currentPeriod?[key] = value;
      if (closingKeys.contains(key) && currentPeriod != null) {
        periods.add(NoticeInterestPeriod(Map.unmodifiable(currentPeriod)));
        currentPeriod = null;
      }
    }
    if (currentPeriod != null) {
      periods.add(NoticeInterestPeriod(Map.unmodifiable(currentPeriod)));
    }
    return NoticeStatementData._(
      language: language,
      lines: lines,
      values: Map.unmodifiable(values),
      periods: periods,
    );
  }
}

class NoticeInterestPeriod {
  const NoticeInterestPeriod(this.values);

  final Map<String, String> values;

  String? value(String english, String hindi, GirviNoticeLanguage language) =>
      values[language == GirviNoticeLanguage.hindi ? hindi : english];
}
