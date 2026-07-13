final class GoldWeight implements Comparable<GoldWeight> {
  static const int milligramsPerGram = 1000;

  final int milligrams;

  const GoldWeight.fromMilligrams(this.milligrams);

  factory GoldWeight.fromGrams(num grams) {
    return GoldWeight.fromMilligrams((grams * milligramsPerGram).round());
  }

  static const GoldWeight zero = GoldWeight.fromMilligrams(0);

  double get grams => milligrams / milligramsPerGram;

  bool get isNegative => milligrams < 0;

  bool get isZero => milligrams == 0;

  GoldWeight operator +(GoldWeight other) {
    return GoldWeight.fromMilligrams(milligrams + other.milligrams);
  }

  GoldWeight operator -(GoldWeight other) {
    return GoldWeight.fromMilligrams(milligrams - other.milligrams);
  }

  @override
  int compareTo(GoldWeight other) => milligrams.compareTo(other.milligrams);

  @override
  bool operator ==(Object other) {
    return other is GoldWeight && other.milligrams == milligrams;
  }

  @override
  int get hashCode => milligrams.hashCode;
}
