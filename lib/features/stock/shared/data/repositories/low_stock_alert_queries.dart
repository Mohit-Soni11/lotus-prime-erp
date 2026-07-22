part of 'low_stock_alert_repository.dart';

const String _lowStockMetalExpression = '''
CASE
  WHEN LOWER(u.metal_type) = 'gold' THEN 'Gold'
  WHEN LOWER(u.metal_type) = 'silver' THEN 'Silver'
  WHEN LOWER(u.metal_type) = 'diamond' THEN 'Diamond'
  WHEN LOWER(u.metal_type) = 'platinum' THEN 'Platinum'
  ELSE COALESCE(NULLIF(TRIM(u.metal_type), ''), 'Other')
END
''';

const String _lowStockGradeExpression = '''
CASE
  WHEN LOWER(u.metal_type) = 'gold' THEN
    CASE
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 91.6) <= 0.6 THEN '22KT (91.6%)'
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 92.0) <= 0.6 THEN '22KT (91.6%)'
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 75.0) <= 0.6 THEN '18KT (75%)'
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 99.9) <= 0.6 THEN '24KT (99.9%)'
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 58.5) <= 0.6 THEN '14KT (58.5%)'
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 37.5) <= 0.6 THEN '9KT (37.5%)'
      ELSE printf('%.2f%% Gold', COALESCE(u.purity_percent, 0.0))
    END
  WHEN LOWER(u.metal_type) = 'silver' THEN printf('%.0f%% Silver', COALESCE(u.purity_percent, 0.0))
  ELSE printf('%.2f%% Purity', COALESCE(u.purity_percent, 0.0))
END
''';

const String _lowStockLotUnitExpression = '''
LOWER(COALESCE(u.unit_code, '')) LIKE '%lot%'
  AND TRIM(COALESCE(u.huid, '')) = ''
''';

const String _lowStockTotalQuantityExpression = '''
CASE
  WHEN $_lowStockLotUnitExpression THEN COALESCE(NULLIF(pvi.quantity, 0), NULLIF(s.quantity, 0), 1)
  WHEN lower(COALESCE(s.quantity_mode, '')) = 'pair'
    THEN 1.0 / COALESCE(NULLIF(s.pieces_per_packet, 0), 2)
  ELSE 1
END
''';

const String _lowStockAvailableQuantityExpression = '''
CASE
  WHEN LOWER(u.status) = 'available' THEN
    CASE
      WHEN $_lowStockLotUnitExpression THEN COALESCE(NULLIF(s.quantity, 0), 0)
      WHEN lower(COALESCE(s.quantity_mode, '')) = 'pair'
        THEN 1.0 / COALESCE(NULLIF(s.pieces_per_packet, 0), 2)
      ELSE 1
    END
  ELSE 0
END
''';

const String _lowStockSoldQuantityExpression = '''
CASE
  WHEN $_lowStockLotUnitExpression THEN
    CASE
      WHEN LOWER(u.status) = 'sold' THEN COALESCE(NULLIF(pvi.quantity, 0), 1)
      WHEN COALESCE(NULLIF(pvi.quantity, 0), NULLIF(s.quantity, 0), 1) - COALESCE(s.quantity, 0) > 0
        THEN COALESCE(NULLIF(pvi.quantity, 0), NULLIF(s.quantity, 0), 1) - COALESCE(s.quantity, 0)
      ELSE 0
    END
  WHEN lower(COALESCE(s.quantity_mode, '')) = 'pair' THEN
    CASE
      WHEN LOWER(u.status) = 'sold'
        THEN 1.0 / COALESCE(NULLIF(s.pieces_per_packet, 0), 2)
      ELSE 0
    END
  WHEN LOWER(u.status) = 'sold' THEN 1
  ELSE 0
END
''';
