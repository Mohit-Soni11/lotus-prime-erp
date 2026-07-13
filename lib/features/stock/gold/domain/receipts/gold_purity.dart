import 'gold_weight.dart';

final class GoldPurity implements Comparable<GoldPurity> {
  static const int pureGoldPartsPerThousand = 1000;

  final int partsPerThousand;

  const GoldPurity(this.partsPerThousand)
      : assert(partsPerThousand >= 0 && partsPerThousand <= 1000);

  factory GoldPurity.fromPercent(num percent) {
    return GoldPurity((percent * 10).round());
  }

  double get percent => partsPerThousand / 10;

  bool get isZero => partsPerThousand == 0;

  GoldWeight fineWeightOf(GoldWeight netWeight) {
    return GoldWeight.fromMilligrams(
      (netWeight.milligrams * partsPerThousand / pureGoldPartsPerThousand)
          .round(),
    );
  }

  @override
  int compareTo(GoldPurity other) =>
      partsPerThousand.compareTo(other.partsPerThousand);

  @override
  bool operator ==(Object other) {
    return other is GoldPurity && other.partsPerThousand == partsPerThousand;
  }

  @override
  int get hashCode => partsPerThousand.hashCode;
}
