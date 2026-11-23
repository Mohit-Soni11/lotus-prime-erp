class PosMetalTaxBreakdown {
  const PosMetalTaxBreakdown({
    required this.metalTaxable,
    required this.labourTaxable,
    required this.metalTax,
    required this.labourTax,
  });

  static const zero = PosMetalTaxBreakdown(
    metalTaxable: 0,
    labourTaxable: 0,
    metalTax: 0,
    labourTax: 0,
  );

  final double metalTaxable;
  final double labourTaxable;
  final double metalTax;
  final double labourTax;
}
