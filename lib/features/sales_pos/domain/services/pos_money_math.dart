class PosMoneyMath {
  const PosMoneyMath._();

  static const double paisaTolerance = 0.005;
  static const double _roundingEpsilon = 0.0000001;

  static double roundToPaisa(double value) {
    final scaled = value * 100;
    final adjusted =
        scaled >= 0 ? scaled + _roundingEpsilon : scaled - _roundingEpsilon;
    final rounded = adjusted.roundToDouble() / 100;
    return rounded == -0.0 ? 0 : rounded;
  }

  static double settlePaisa(
    double value, {
    double tolerance = paisaTolerance,
  }) {
    final rounded = roundToPaisa(value);
    return rounded.abs() <= tolerance ? 0 : rounded;
  }
}
