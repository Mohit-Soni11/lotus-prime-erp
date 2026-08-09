class PosNumberFormatter {
  const PosNumberFormatter._();

  static String compact(
    double value, {
    int maxFractionDigits = 2,
    bool blankWhenZero = true,
  }) {
    if (blankWhenZero && value.abs() < 0.0001) {
      return '';
    }

    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.0001) {
      return rounded.toStringAsFixed(0);
    }

    return value
        .toStringAsFixed(maxFractionDigits)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static String weight(
    double value, {
    bool blankWhenZero = true,
  }) {
    return compact(
      value,
      maxFractionDigits: 3,
      blankWhenZero: blankWhenZero,
    );
  }
}
