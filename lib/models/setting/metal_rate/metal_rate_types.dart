part of 'metal_rate_model.dart';

enum MetalRateMetal { gold, silver, diamond, platinum }

extension MetalRateMetalX on MetalRateMetal {
  String get key => name;

  String get label {
    switch (this) {
      case MetalRateMetal.gold:
        return 'Gold';
      case MetalRateMetal.silver:
        return 'Silver';
      case MetalRateMetal.diamond:
        return 'Diamond';
      case MetalRateMetal.platinum:
        return 'Platinum';
    }
  }

  String get assetPath {
    switch (this) {
      case MetalRateMetal.gold:
        return 'lib/logo/gold.jpeg';
      case MetalRateMetal.silver:
      case MetalRateMetal.platinum:
        return 'lib/logo/silver and platinum .jpeg';
      case MetalRateMetal.diamond:
        return 'lib/logo/diamond .jpeg';
    }
  }

  static MetalRateMetal fromKey(String key) {
    return MetalRateMetal.values.firstWhere(
      (metal) => metal.key == key.toLowerCase(),
      orElse: () => MetalRateMetal.gold,
    );
  }
}

enum PricingPosture { defensive, balanced, growth }

extension PricingPostureX on PricingPosture {
  String get label {
    switch (this) {
      case PricingPosture.defensive:
        return 'Defensive';
      case PricingPosture.balanced:
        return 'Balanced';
      case PricingPosture.growth:
        return 'Growth';
    }
  }

  static PricingPosture fromName(String value) {
    return PricingPosture.values.firstWhere(
      (posture) => posture.name == value,
      orElse: () => PricingPosture.balanced,
    );
  }
}
