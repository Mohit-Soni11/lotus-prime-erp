String soldCostBasisExpression({
  String itemAlias = 'i',
  String unitAlias = 'u',
  String stockAlias = 'si',
  String purchaseAlias = 'pvi',
}) {
  final fallback =
      'COALESCE(NULLIF($itemAlias.stock_unit_cost, 0.0), $unitAlias.unit_cost, 0.0)';
  final originalValuationFine =
      'COALESCE(NULLIF($purchaseAlias.valuation_fine_weight, 0.0), '
      'COALESCE($purchaseAlias.fine_weight, 0.0) + '
      'COALESCE($purchaseAlias.wastage_fine_weight, 0.0), 0.0)';
  final originalRate =
      'COALESCE(NULLIF($purchaseAlias.rate, 0.0), $unitAlias.rate_per_gram, 0.0)';
  final originalMaking = 'MAX(COALESCE($purchaseAlias.line_amount, 0.0) - '
      '($originalValuationFine * $originalRate), 0.0)';
  final lotOrBulkLine = '''
    $purchaseAlias.id IS NOT NULL
    AND (
      (
        LOWER(COALESCE($unitAlias.unit_code, '')) LIKE '%lot%'
        AND TRIM(COALESCE($unitAlias.huid, '')) = ''
      )
      OR LOWER(COALESCE(NULLIF(TRIM($stockAlias.quantity_mode), ''), '')) IN ('packet', 'pack', 'lot', 'bulk')
    )
  ''';
  final allocatedCost = '''
    (
      CASE
        WHEN COALESCE($purchaseAlias.net_weight, 0.0) > 0
          THEN COALESCE($itemAlias.net_weight, 0.0) *
               ($originalValuationFine / $purchaseAlias.net_weight) *
               $originalRate
        ELSE 0.0
      END
      +
      CASE
        WHEN COALESCE($purchaseAlias.quantity, 0) > 0
          THEN $originalMaking *
               COALESCE(NULLIF($itemAlias.quantity, 0), 1) /
               $purchaseAlias.quantity
        ELSE 0.0
      END
    )
  ''';

  return '''
    CASE
      WHEN $lotOrBulkLine
        THEN COALESCE(NULLIF($allocatedCost, 0.0), $fallback)
      ELSE $fallback
    END
  ''';
}
