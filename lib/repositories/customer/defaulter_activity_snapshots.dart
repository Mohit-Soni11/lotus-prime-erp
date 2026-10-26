part of 'defaulter_repository.dart';

class _PledgedItemSnapshot {
  final int itemCount;
  final String itemName;
  final String metalType;
  final String purity;
  final int pieces;
  final double grossWeight;
  final double lessWeight;
  final double netWeight;
  final String? recoveryDispositionStatus;

  const _PledgedItemSnapshot({
    required this.itemCount,
    required this.itemName,
    required this.metalType,
    required this.purity,
    required this.pieces,
    required this.grossWeight,
    required this.lessWeight,
    required this.netWeight,
    this.recoveryDispositionStatus,
  });

  factory _PledgedItemSnapshot.fromItems(List<GirviLoanItem> items) {
    if (items.isEmpty) {
      return const _PledgedItemSnapshot(
        itemCount: 0,
        itemName: 'Pledged item',
        metalType: 'Not specified',
        purity: 'Not specified',
        pieces: 0,
        grossWeight: 0,
        lessWeight: 0,
        netWeight: 0,
      );
    }

    final sorted = List<GirviLoanItem>.from(items)
      ..sort((a, b) => a.serialNo.compareTo(b.serialNo));
    final first = sorted.first;
    final itemName = _itemDisplayName(first.itemName, fallback: 'Pledged item');
    final suffix = sorted.length > 1 ? ' + ${sorted.length - 1} more' : '';
    final dispositions = sorted
        .map((item) => item.recoveryDispositionStatus?.trim().toUpperCase())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet();

    return _PledgedItemSnapshot(
      itemCount: sorted.length,
      itemName: '$itemName$suffix',
      metalType: _singleOrMixed(sorted.map((item) => item.metalType)),
      purity: _singleOrMixed(sorted.map((item) => item.purity)),
      pieces: sorted.fold(0, (sum, item) => sum + item.pieces),
      grossWeight: sorted.fold(0.0, (sum, item) => sum + item.grossWeight),
      lessWeight: sorted.fold(0.0, (sum, item) => sum + item.lessWeight),
      netWeight: sorted.fold(0.0, (sum, item) => sum + item.netWeight),
      recoveryDispositionStatus: dispositions.length == 1
          ? dispositions.single
          : dispositions.isNotEmpty
              ? 'MIXED'
              : null,
    );
  }

  factory _PledgedItemSnapshot.fromLoan(GirviLoan loan) {
    final itemName = _fallbackItemName(loan);
    final pieces = loan.itemCount <= 0 ? 1 : loan.itemCount;

    return _PledgedItemSnapshot(
      itemCount: pieces,
      itemName: itemName,
      metalType: _readableText(loan.metalType, fallback: 'Not specified'),
      purity: _readableText(loan.metalPurity, fallback: 'Not specified'),
      pieces: pieces,
      grossWeight: loan.grossWeight,
      lessWeight: loan.stoneWeight,
      netWeight: loan.netWeight,
    );
  }

  String get summary {
    final parts = <String>[
      itemName,
      metalType,
      purity,
      '$pieces pc${pieces == 1 ? '' : 's'}',
      'Net ${netWeight.toStringAsFixed(3)} g',
    ];
    return parts.join(' | ');
  }

  static String _fallbackItemName(GirviLoan loan) {
    final raw = loan.itemDescription.trim();
    if (raw.isEmpty) return _readableText(loan.metalType, fallback: 'Item');
    final firstLine = raw.split(RegExp(r'\r?\n')).first.trim();
    final firstSegment = firstLine.split('|').first.trim();
    final withoutSerial = firstSegment
        .replaceFirst(RegExp(r'^#?\d+\s*'), '')
        .replaceFirst(RegExp(r'^-\s*'), '')
        .trim();
    return _itemDisplayName(withoutSerial, fallback: 'Pledged item');
  }

  static String _singleOrMixed(Iterable<String> values) {
    final cleanValues = values
        .map((value) => _readableText(value, fallback: ''))
        .where((value) => value.isNotEmpty)
        .toSet();
    if (cleanValues.isEmpty) return 'Not specified';
    if (cleanValues.length == 1) return cleanValues.first;
    return 'Mixed';
  }

  static String _itemDisplayName(String value, {required String fallback}) {
    final text = _readableText(value, fallback: fallback);
    if (text.length <= 36) return text;
    return '${text.substring(0, 33).trimRight()}...';
  }

  static String _readableText(String? value, {required String fallback}) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return fallback;
    return trimmed;
  }
}

class _PaymentSummary {
  final double totalReceived;
  final double currentMonthReceived;
  final double interestPaid;
  final double principalPaid;
  final double interestDiscount;
  final List<GirviInterestAdjustment> interestAdjustments;
  final double principalDiscount;
  final double legacyPrincipalRepaid;
  final int coveredInterestMonths;
  final DateTime? lastPaymentDate;
  final DateTime? firstInterestPaymentDate;

  bool get hasCollectionHistory => totalReceived > 0 || lastPaymentDate != null;

  const _PaymentSummary({
    required this.totalReceived,
    required this.currentMonthReceived,
    required this.interestPaid,
    required this.principalPaid,
    required this.interestDiscount,
    required this.interestAdjustments,
    required this.principalDiscount,
    required this.legacyPrincipalRepaid,
    required this.coveredInterestMonths,
    required this.lastPaymentDate,
    required this.firstInterestPaymentDate,
  });

  factory _PaymentSummary.empty() {
    return const _PaymentSummary(
      totalReceived: 0,
      currentMonthReceived: 0,
      interestPaid: 0,
      principalPaid: 0,
      interestDiscount: 0,
      interestAdjustments: [],
      principalDiscount: 0,
      legacyPrincipalRepaid: 0,
      coveredInterestMonths: 0,
      lastPaymentDate: null,
      firstInterestPaymentDate: null,
    );
  }

  bool hasInterestPaidOnOrBefore(DateTime date) {
    final paidOn = firstInterestPaymentDate;
    if (paidOn == null) return false;
    final paidDay = DateTime(paidOn.year, paidOn.month, paidOn.day);
    final dueDay = DateTime(date.year, date.month, date.day);
    return !paidDay.isAfter(dueDay);
  }

  _PaymentSummary add(
    GirviPayment payment, {
    required DateTime currentMonthStart,
  }) {
    final type = GirviPaymentType.fromDb(payment.paymentType);
    var nextInterestPaid = interestPaid;
    var nextPrincipalPaid = principalPaid;
    var nextInterestDiscount = interestDiscount;
    final adjustment = GirviInterestPaymentAdjustments.fromPayment(payment);
    var nextPrincipalDiscount = principalDiscount;
    var nextLegacyPrincipalRepaid = legacyPrincipalRepaid;
    var nextCoveredInterestMonths = coveredInterestMonths;
    var nextFirstInterestPaymentDate = firstInterestPaymentDate;

    if (type == GirviPaymentType.interest ||
        type == GirviPaymentType.partialInterest) {
      nextInterestPaid += payment.amount;
      nextCoveredInterestMonths += payment.monthsCovered ?? 0;
      nextFirstInterestPaymentDate =
          _earliestDate(nextFirstInterestPaymentDate, payment.paymentDate);
    } else if (type == GirviPaymentType.fullRelease) {
      nextInterestPaid += payment.interestComponent;
      nextPrincipalPaid += payment.principalComponent;
      nextInterestDiscount += payment.interestDiscountComponent;
      nextPrincipalDiscount += payment.principalDiscountComponent;
      nextCoveredInterestMonths += payment.monthsCovered ?? 0;
      if (payment.interestComponent > 0) {
        nextFirstInterestPaymentDate =
            _earliestDate(nextFirstInterestPaymentDate, payment.paymentDate);
      }
    } else if (type == GirviPaymentType.partialPrincipal) {
      nextLegacyPrincipalRepaid += payment.amount;
    }

    final nextLastPaymentDate =
        lastPaymentDate == null || payment.paymentDate.isAfter(lastPaymentDate!)
            ? payment.paymentDate
            : lastPaymentDate;
    final paymentMonth = DateTime(
      payment.paymentDate.year,
      payment.paymentDate.month,
    );
    final nextCurrentMonthReceived = paymentMonth == currentMonthStart
        ? currentMonthReceived + payment.amount
        : currentMonthReceived;

    return _PaymentSummary(
      totalReceived: totalReceived + payment.amount,
      currentMonthReceived: nextCurrentMonthReceived,
      interestPaid: nextInterestPaid,
      principalPaid: nextPrincipalPaid,
      interestDiscount: nextInterestDiscount,
      interestAdjustments: adjustment == null
          ? interestAdjustments
          : [...interestAdjustments, adjustment],
      principalDiscount: nextPrincipalDiscount,
      legacyPrincipalRepaid: nextLegacyPrincipalRepaid,
      coveredInterestMonths: nextCoveredInterestMonths,
      lastPaymentDate: nextLastPaymentDate,
      firstInterestPaymentDate: nextFirstInterestPaymentDate,
    );
  }

  DateTime _earliestDate(DateTime? current, DateTime candidate) {
    if (current == null || candidate.isBefore(current)) return candidate;
    return current;
  }
}
