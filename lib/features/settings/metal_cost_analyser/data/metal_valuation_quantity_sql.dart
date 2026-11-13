String valuationQuantityUnitLabelExpression({
  required String unitAlias,
  required String stockAlias,
}) {
  final itemText =
      "lower(COALESCE($unitAlias.item_type, '') || ' ' || COALESCE($unitAlias.item_name, '') || ' ' || COALESCE($stockAlias.sub_category, '') || ' ' || COALESCE($stockAlias.item_name, ''))";
  final mode = "lower(COALESCE(NULLIF(TRIM($stockAlias.quantity_mode), ''), ''))";
  return '''
    CASE
      WHEN $mode IN ('packet', 'pack') THEN 'packet'
      WHEN $mode = 'pair' THEN 'pair'
      WHEN $mode = 'set' THEN 'set'
      WHEN $mode IN ('lot', 'bulk') THEN 'lot'
      WHEN $mode IN ('pieces', 'piece', 'pcs') THEN 'pcs'
      WHEN $itemText LIKE '%payal%' THEN 'pair'
      WHEN $itemText LIKE '%anklet%' THEN 'pair'
      WHEN $itemText LIKE '%jhumka%' THEN 'pair'
      WHEN $itemText LIKE '%earring%' THEN 'pair'
      WHEN $itemText LIKE '%tops%' THEN 'pair'
      WHEN $itemText LIKE '%bali%' THEN 'pair'
      WHEN $itemText LIKE '%kundal%' THEN 'pair'
      WHEN $itemText LIKE '%bichhiya%' THEN 'pair'
      WHEN $itemText LIKE '%bichiya%' THEN 'pair'
      WHEN $itemText LIKE '%toe ring%' THEN 'pair'
      WHEN $itemText LIKE '%set%' THEN 'set'
      WHEN $itemText LIKE '%necklace%' THEN 'set'
      WHEN $itemText LIKE '%haar%' THEN 'set'
      WHEN $itemText LIKE '%har%' THEN 'set'
      WHEN $itemText LIKE '%chudi%' THEN 'set'
      WHEN $itemText LIKE '%packet%' THEN 'packet'
      WHEN $itemText LIKE '%pack%' THEN 'packet'
      ELSE 'pcs'
    END
  ''';
}

String valuationAvailableDisplayQuantityExpression({
  required String unitAlias,
  required String stockAlias,
}) {
  final balanceUnit = '''
    lower(COALESCE($unitAlias.unit_code, '')) LIKE '%lot%'
      AND TRIM(COALESCE($unitAlias.huid, '')) = ''
  ''';
  final packetBalanceUnit = '''
    lower(COALESCE(NULLIF(TRIM($stockAlias.quantity_mode), ''), '')) IN ('packet', 'pack')
  ''';
  return '''
    CASE
      WHEN ($balanceUnit) OR ($packetBalanceUnit)
        THEN COALESCE($stockAlias.quantity, 0) * 1.0
      ELSE 1
    END
  ''';
}

String valuationSoldDisplayQuantityExpression({required String billAlias}) {
  return "COALESCE(NULLIF($billAlias.quantity, 0), 1)";
}
