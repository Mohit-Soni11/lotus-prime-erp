final class Money implements Comparable<Money> {
  static const String inr = 'INR';
  static const int paisePerRupee = 100;

  final int paise;
  final String currencyCode;

  const Money({
    required this.paise,
    this.currencyCode = inr,
  });

  const Money.zero({this.currencyCode = inr}) : paise = 0;

  factory Money.fromRupees(num value, {String currencyCode = inr}) {
    return Money(
      paise: (value * paisePerRupee).round(),
      currencyCode: currencyCode,
    );
  }

  double get rupees => paise / paisePerRupee;

  bool get isNegative => paise < 0;

  Money operator +(Money other) {
    _ensureSameCurrency(other);
    return Money(paise: paise + other.paise, currencyCode: currencyCode);
  }

  Money operator -(Money other) {
    _ensureSameCurrency(other);
    return Money(paise: paise - other.paise, currencyCode: currencyCode);
  }

  Money multiplyByQuantity(int quantity) {
    if (quantity < 0) {
      throw ArgumentError.value(quantity, 'quantity', 'must not be negative');
    }
    return Money(paise: paise * quantity, currencyCode: currencyCode);
  }

  Money percentageFromBasisPoints(int basisPoints) {
    if (basisPoints < 0) {
      throw ArgumentError.value(
        basisPoints,
        'basisPoints',
        'must not be negative',
      );
    }
    return Money(
      paise: (paise * basisPoints / 10000).round(),
      currencyCode: currencyCode,
    );
  }

  @override
  int compareTo(Money other) {
    _ensureSameCurrency(other);
    return paise.compareTo(other.paise);
  }

  void _ensureSameCurrency(Money other) {
    if (currencyCode != other.currencyCode) {
      throw ArgumentError('Currency codes must match.');
    }
  }

  @override
  bool operator ==(Object other) {
    return other is Money &&
        other.paise == paise &&
        other.currencyCode == currencyCode;
  }

  @override
  int get hashCode => Object.hash(paise, currencyCode);
}
