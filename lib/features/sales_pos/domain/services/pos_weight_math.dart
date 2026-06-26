class PosWeightMath {
  const PosWeightMath._();

  static double roundToThreeDecimals(double value) {
    if (value == 0) {
      return 0;
    }
    final rounded = (value * 1000).roundToDouble() / 1000;
    return rounded == -0.0 ? 0 : rounded;
  }
}
