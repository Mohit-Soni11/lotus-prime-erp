part of 'metal_rate_model.dart';

class MetalRateBrandBenchmark {
  final String brandName;
  final double referenceRatePer10g;
  final double makingLowPercent;
  final double makingHighPercent;
  final Map<String, double> rateByPurity;
  final Map<String, double> makingByPurity;
  final String notes;

  const MetalRateBrandBenchmark({
    required this.brandName,
    required this.referenceRatePer10g,
    required this.makingLowPercent,
    required this.makingHighPercent,
    this.rateByPurity = const {},
    this.makingByPurity = const {},
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'brandName': brandName,
        'referenceRatePer10g': referenceRatePer10g,
        'makingLowPercent': makingLowPercent,
        'makingHighPercent': makingHighPercent,
        'rateByPurity': rateByPurity,
        'makingByPurity': makingByPurity,
        'notes': notes,
      };

  factory MetalRateBrandBenchmark.fromJson(Map<String, dynamic> json) {
    return MetalRateBrandBenchmark(
      brandName: json['brandName'] as String? ?? 'Brand',
      referenceRatePer10g: _toDouble(json['referenceRatePer10g']),
      makingLowPercent: _toDouble(json['makingLowPercent']),
      makingHighPercent: _toDouble(json['makingHighPercent']),
      rateByPurity: _toDoubleMap(json['rateByPurity']),
      makingByPurity: _toDoubleMap(json['makingByPurity']),
      notes: json['notes'] as String? ?? '',
    );
  }
}
