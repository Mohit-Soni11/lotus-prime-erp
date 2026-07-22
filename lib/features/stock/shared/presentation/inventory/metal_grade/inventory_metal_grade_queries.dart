part of '../inventory_screen.dart';

const String _inventoryLotUnitExpression = '''
lower(COALESCE(u.unit_code, '')) LIKE '%lot%'
  AND TRIM(COALESCE(u.huid, '')) = ''
''';

const String _inventoryAvailableGrossWeightExpression = '''
CASE
  WHEN lower(u.status) = 'available' THEN
    CASE
      WHEN $_inventoryLotUnitExpression THEN
        COALESCE(s.gross_weight, u.gross_weight, 0.0)
      ELSE COALESCE(u.gross_weight, 0.0)
    END
  ELSE 0.0
END
''';

const String _inventoryAvailableNetWeightExpression = '''
CASE
  WHEN lower(u.status) = 'available' THEN
    CASE
      WHEN $_inventoryLotUnitExpression THEN
        COALESCE(s.net_weight, u.net_weight, 0.0)
      ELSE COALESCE(u.net_weight, 0.0)
    END
  ELSE 0.0
END
''';

const String _inventoryAvailableActualFineExpression = '''
CASE
  WHEN lower(u.status) = 'available' THEN
    CASE
      WHEN $_inventoryLotUnitExpression THEN
        COALESCE(u.actual_fine_weight, 0.0)
      ELSE COALESCE(u.actual_fine_weight, 0.0)
    END
  ELSE 0.0
END
''';

const String _inventoryAvailableValuationFineExpression = '''
CASE
  WHEN lower(u.status) = 'available' THEN
    CASE
      WHEN $_inventoryLotUnitExpression THEN
        COALESCE(u.valuation_fine_weight, 0.0)
      ELSE COALESCE(u.valuation_fine_weight, 0.0)
    END
  ELSE 0.0
END
''';

const String _inventoryAvailableStockValueExpression = '''
CASE
  WHEN lower(u.status) = 'available' THEN
    CASE
      WHEN $_inventoryLotUnitExpression THEN
        COALESCE(u.unit_cost, 0.0)
      ELSE COALESCE(u.unit_cost, 0.0)
    END
  ELSE 0.0
END
''';

const String _inventorySoldWeightExpression = '''
CASE
  WHEN u.id = (
    SELECT MIN(first_unit.id)
    FROM stock_item_units first_unit
    WHERE first_unit.stock_item_id = s.id
  ) THEN
    CASE
      WHEN COALESCE(sm.sold_net_weight, 0) > 0
        THEN COALESCE(sm.sold_net_weight, 0)
      ELSE 0
    END
  ELSE 0
END
''';

const String _inventorySoldWeightJoin = '''
LEFT JOIN (
  SELECT
    source.stock_item_id,
    COALESCE(bill_weight.sold_net_weight, movement_weight.sold_net_weight, 0.0) AS sold_net_weight
  FROM (
    SELECT stock_item_id
    FROM stock_movements
    WHERE movement_type IN ('SALE', 'SALE_RESTORE')
    UNION
    SELECT linked_stock_item_id AS stock_item_id
    FROM bill_items
    WHERE linked_stock_item_id IS NOT NULL
  ) source
  LEFT JOIN (
    SELECT
      bi.linked_stock_item_id AS stock_item_id,
      SUM(COALESCE(bi.net_weight, 0.0)) AS sold_net_weight
    FROM bill_items bi
    INNER JOIN bills b ON b.id = bi.bill_id
    WHERE bi.linked_stock_item_id IS NOT NULL
      AND UPPER(COALESCE(b.status, 'ACTIVE')) <> 'VOID'
    GROUP BY bi.linked_stock_item_id
  ) bill_weight ON bill_weight.stock_item_id = source.stock_item_id
  LEFT JOIN (
    SELECT
      stock_item_id,
      SUM(
        CASE
          WHEN movement_type = 'SALE' THEN ABS(net_weight_delta)
          WHEN movement_type = 'SALE_RESTORE' THEN -ABS(net_weight_delta)
          ELSE 0
        END
      ) AS sold_net_weight
    FROM stock_movements
    WHERE movement_type IN ('SALE', 'SALE_RESTORE')
    GROUP BY stock_item_id
  ) movement_weight ON movement_weight.stock_item_id = source.stock_item_id
) sm ON sm.stock_item_id = s.id
''';
