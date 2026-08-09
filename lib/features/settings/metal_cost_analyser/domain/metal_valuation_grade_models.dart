import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_models.dart';

class MetalValuationGradeSnapshot {
  final String metalType;
  final List<MetalValuationGradeRow> grades;

  const MetalValuationGradeSnapshot({
    required this.metalType,
    required this.grades,
  });

  static MetalValuationGradeSnapshot empty(String metalType) {
    return MetalValuationGradeSnapshot(
      metalType: metalType,
      grades: const [],
    );
  }

  int get gradeCount => grades.length;

  int get availableUnits =>
      grades.fold(0, (sum, grade) => sum + grade.availableUnits);

  int get soldUnits => grades.fold(0, (sum, grade) => sum + grade.soldUnits);

  double get availableNetWeight =>
      grades.fold(0, (sum, grade) => sum + grade.availableNetWeight);

  double get soldNetWeight =>
      grades.fold(0, (sum, grade) => sum + grade.soldNetWeight);

  double get availableCost =>
      grades.fold(0, (sum, grade) => sum + grade.availableCost);

  double get soldCost => grades.fold(0, (sum, grade) => sum + grade.soldCost);

  double get saleValue => grades.fold(0, (sum, grade) => sum + grade.saleValue);

  double get profit => grades.fold(0, (sum, grade) => sum + grade.profit);

  double get marginPercent => saleValue == 0 ? 0 : profit / saleValue * 100;
}

class MetalValuationGradeBatchRow {
  final String gradeLabel;
  final BatchValuationRow batch;

  const MetalValuationGradeBatchRow({
    required this.gradeLabel,
    required this.batch,
  });
}

class MetalValuationGradeRow {
  final String gradeLabel;
  final int availableUnits;
  final int soldUnits;
  final double availableNetWeight;
  final double soldNetWeight;
  final double availableCost;
  final double soldCost;
  final double saleValue;
  final double profit;

  const MetalValuationGradeRow({
    required this.gradeLabel,
    required this.availableUnits,
    required this.soldUnits,
    required this.availableNetWeight,
    required this.soldNetWeight,
    required this.availableCost,
    required this.soldCost,
    required this.saleValue,
    required this.profit,
  });

  int get totalUnits => availableUnits + soldUnits;

  double get totalNetWeight => availableNetWeight + soldNetWeight;

  double get marginPercent => saleValue == 0 ? 0 : profit / saleValue * 100;

  String get statusLabel {
    if (soldUnits > 0 && availableUnits > 0) return 'Movement';
    if (soldUnits > 0) return 'Sold';
    return 'Live Stock';
  }
}
