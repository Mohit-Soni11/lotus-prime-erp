import '../sales_pos_enums/sales_pos_enums.dart';

class PosQuickStockIntakeModel {
  final int rowIndex;
  final String itemName;
  final MetalType metal;
  final String purityLabel;
  final double grossWeight;
  final double lessWeight;
  final double netWeight;
  final double wastagePercent;
  final double purchaseRate;
  final String huid;
  final int? supplierId;
  final String supplierName;

  const PosQuickStockIntakeModel({
    required this.rowIndex,
    required this.itemName,
    required this.metal,
    required this.purityLabel,
    required this.grossWeight,
    required this.lessWeight,
    required this.netWeight,
    required this.wastagePercent,
    required this.purchaseRate,
    required this.huid,
    required this.supplierId,
    required this.supplierName,
  });

  double get purityPercent => _purityLabelToPercent(purityLabel);
  double get fineWeight => netWeight * (purityPercent / 100);
  double get wastageFineWeight => netWeight * (wastagePercent / 100);
  double get valuationFineWeight => fineWeight + wastageFineWeight;
  double get unitCost => purchaseRate * netWeight;
}

double _purityLabelToPercent(String label) {
  final normalized = label.trim().toUpperCase().replaceAll(' ', '');
  const known = <String, double>{
    '24KT': 99.9,
    '24K': 99.9,
    '999': 99.9,
    '22KT': 91.67,
    '22K': 91.67,
    '916': 91.67,
    '18KT': 75.0,
    '18K': 75.0,
    '750': 75.0,
    '14KT': 58.3,
    '14K': 58.3,
    '585': 58.3,
    '925': 92.5,
    '950PT': 95.0,
    '900PT': 90.0,
    '850PT': 85.0,
  };
  final mapped = known[normalized];
  if (mapped != null) return mapped;
  final numeric = double.tryParse(normalized.replaceAll(RegExp('[^0-9.]'), ''));
  return (numeric ?? 0).clamp(0.0, 100.0).toDouble();
}
