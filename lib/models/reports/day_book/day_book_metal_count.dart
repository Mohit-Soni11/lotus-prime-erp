class DayBookMetalCountLine {
  const DayBookMetalCountLine({
    required this.key,
    required this.metal,
    required this.item,
    required this.purity,
    required this.pieces,
    required this.grossGrams,
    required this.netGrams,
    this.fineGrams,
  });

  final String key;
  final String metal;
  final String item;
  final String purity;
  final int pieces;
  final double grossGrams;
  final double netGrams;
  final double? fineGrams;

  Map<String, Object?> toJson() => {
        'key': key,
        'metal': metal,
        'item': item,
        'purity': purity,
        'pieces': pieces,
        'grossGrams': grossGrams,
        'netGrams': netGrams,
        'fineGrams': fineGrams,
      };
}

class DayBookPhysicalMetalCount {
  const DayBookPhysicalMetalCount({
    required this.key,
    required this.pieces,
    required this.grossGrams,
    required this.netGrams,
    required this.fineGrams,
  });

  final String key;
  final int pieces;
  final double grossGrams;
  final double netGrams;
  final double fineGrams;

  Map<String, Object> toJson() => {
        'key': key,
        'pieces': pieces,
        'grossGrams': grossGrams,
        'netGrams': netGrams,
        'fineGrams': fineGrams,
      };
}

class DayBookMetalVerification {
  const DayBookMetalVerification({
    required this.sourceHash,
    required this.verifiedAt,
    required this.verifiedBy,
    required this.physicalCounts,
    required this.expectedLines,
  });

  final String sourceHash;
  final DateTime verifiedAt;
  final String verifiedBy;
  final List<DayBookPhysicalMetalCount> physicalCounts;
  final List<DayBookMetalCountLine> expectedLines;
}
