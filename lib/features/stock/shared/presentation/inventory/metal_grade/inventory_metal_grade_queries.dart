part of '../inventory_screen.dart';

const String _inventoryLotUnitExpression = '''
lower(COALESCE(u.unit_code, '')) LIKE '%lot%'
  AND TRIM(COALESCE(u.huid, '')) = ''
''';

const String _inventorySummaryRawQuantityExpression = '''
CASE
  WHEN $_inventoryLotUnitExpression THEN COALESCE(NULLIF(pvi.quantity, 0), NULLIF(s.quantity, 0), 1)
  ELSE 1
END
''';

const String _inventorySummaryAvailableRawQuantityExpression = '''
CASE
  WHEN lower(u.status) = 'available' THEN
    CASE
      WHEN $_inventoryLotUnitExpression THEN COALESCE(NULLIF(s.quantity, 0), 0)
      ELSE 1
    END
  ELSE 0
END
''';

const String _inventorySummarySoldRawQuantityExpression = '''
CASE
  WHEN $_inventoryLotUnitExpression THEN
    CASE
      WHEN lower(u.status) = 'sold' THEN COALESCE(NULLIF(pvi.quantity, 0), 1)
      WHEN COALESCE(NULLIF(pvi.quantity, 0), NULLIF(s.quantity, 0), 1) - COALESCE(s.quantity, 0) > 0
        THEN COALESCE(NULLIF(pvi.quantity, 0), NULLIF(s.quantity, 0), 1) - COALESCE(s.quantity, 0)
      ELSE 0
    END
  WHEN lower(u.status) = 'sold' THEN 1
  ELSE 0
END
''';

const String _inventorySummaryUnitLabelExpression = '''
CASE
  WHEN lower(COALESCE(NULLIF(TRIM(s.quantity_mode), ''), '')) IN ('packet', 'pack') THEN 'packet'
  WHEN lower(COALESCE(NULLIF(TRIM(s.quantity_mode), ''), '')) = 'pair' THEN 'pair'
  WHEN lower(COALESCE(NULLIF(TRIM(s.quantity_mode), ''), '')) = 'set' THEN 'set'
  WHEN lower(COALESCE(NULLIF(TRIM(s.quantity_mode), ''), '')) IN ('lot', 'bulk') THEN 'lot'
  WHEN lower(COALESCE(u.item_type, '') || ' ' || COALESCE(u.item_name, '')) LIKE '%packet%' THEN 'packet'
  WHEN lower(COALESCE(u.item_type, '') || ' ' || COALESCE(u.item_name, '')) LIKE '%pack%' THEN 'packet'
  WHEN lower(COALESCE(u.item_type, '') || ' ' || COALESCE(u.item_name, '')) LIKE '%payal%' THEN 'pair'
  WHEN lower(COALESCE(u.item_type, '') || ' ' || COALESCE(u.item_name, '')) LIKE '%anklet%' THEN 'pair'
  WHEN lower(COALESCE(u.item_type, '') || ' ' || COALESCE(u.item_name, '')) LIKE '%jhumka%' THEN 'pair'
  WHEN lower(COALESCE(u.item_type, '') || ' ' || COALESCE(u.item_name, '')) LIKE '%earring%' THEN 'pair'
  WHEN lower(COALESCE(u.item_type, '') || ' ' || COALESCE(u.item_name, '')) LIKE '%tops%' THEN 'pair'
  WHEN lower(COALESCE(u.item_type, '') || ' ' || COALESCE(u.item_name, '')) LIKE '%bali%' THEN 'pair'
  WHEN lower(COALESCE(u.item_type, '') || ' ' || COALESCE(u.item_name, '')) LIKE '%kundal%' THEN 'pair'
  WHEN lower(COALESCE(u.item_type, '') || ' ' || COALESCE(u.item_name, '')) LIKE '%bichhiya%' THEN 'pair'
  WHEN lower(COALESCE(u.item_type, '') || ' ' || COALESCE(u.item_name, '')) LIKE '%toe ring%' THEN 'pair'
  WHEN lower(COALESCE(u.item_type, '') || ' ' || COALESCE(u.item_name, '')) LIKE '%set%' THEN 'set'
  WHEN lower(COALESCE(u.item_type, '') || ' ' || COALESCE(u.item_name, '')) LIKE '%necklace%' THEN 'set'
  WHEN lower(COALESCE(u.item_type, '') || ' ' || COALESCE(u.item_name, '')) LIKE '%haar%' THEN 'set'
  WHEN lower(COALESCE(u.item_type, '') || ' ' || COALESCE(u.item_name, '')) LIKE '%har%' THEN 'set'
  WHEN lower(COALESCE(u.item_type, '') || ' ' || COALESCE(u.item_name, '')) LIKE '%chudi%' THEN 'set'
  ELSE 'pcs'
END
''';

const String _inventorySummaryTotalDisplayQuantityExpression = '''
CASE
  WHEN $_inventorySummaryUnitLabelExpression = 'packet' THEN
    CASE
      WHEN COALESCE(NULLIF(s.packet_count, 0), 0) > 0 THEN COALESCE(NULLIF(s.packet_count, 0), 0)
      ELSE ($_inventorySummaryRawQuantityExpression * 1.0) / CASE WHEN COALESCE(NULLIF(s.pieces_per_packet, 0), 1) <= 0 THEN 1 ELSE COALESCE(NULLIF(s.pieces_per_packet, 0), 1) END
    END
  WHEN $_inventorySummaryUnitLabelExpression = 'pair' THEN ($_inventorySummaryRawQuantityExpression * 1.0) / 2.0
  ELSE $_inventorySummaryRawQuantityExpression * 1.0
END
''';

const String _inventorySummaryAvailableDisplayQuantityExpression = '''
CASE
  WHEN $_inventorySummaryUnitLabelExpression = 'packet' THEN
    CASE
      WHEN COALESCE(NULLIF(s.packet_count, 0), 0) > 0 THEN MAX(COALESCE(NULLIF(s.packet_count, 0), 0) - COALESCE(sm.sold_quantity, 0), 0)
      ELSE ($_inventorySummaryAvailableRawQuantityExpression * 1.0) / CASE WHEN COALESCE(NULLIF(s.pieces_per_packet, 0), 1) <= 0 THEN 1 ELSE COALESCE(NULLIF(s.pieces_per_packet, 0), 1) END
    END
  WHEN $_inventorySummaryUnitLabelExpression = 'pair' THEN ($_inventorySummaryAvailableRawQuantityExpression * 1.0) / 2.0
  ELSE $_inventorySummaryAvailableRawQuantityExpression * 1.0
END
''';

const String _inventorySummarySoldDisplayQuantityExpression = '''
CASE
  WHEN $_inventorySummaryUnitLabelExpression = 'packet' THEN
    CASE
      WHEN COALESCE(NULLIF(s.packet_count, 0), 0) > 0 THEN MIN(COALESCE(sm.sold_quantity, 0), COALESCE(NULLIF(s.packet_count, 0), 0))
      ELSE ($_inventorySummarySoldRawQuantityExpression * 1.0) / CASE WHEN COALESCE(NULLIF(s.pieces_per_packet, 0), 1) <= 0 THEN 1 ELSE COALESCE(NULLIF(s.pieces_per_packet, 0), 1) END
    END
  WHEN $_inventorySummaryUnitLabelExpression = 'pair' THEN ($_inventorySummarySoldRawQuantityExpression * 1.0) / 2.0
  ELSE $_inventorySummarySoldRawQuantityExpression * 1.0
END
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
    COALESCE(bill_weight.sold_net_weight, movement_weight.sold_net_weight, 0.0) AS sold_net_weight,
    COALESCE(reconcile_weight.reconciled_net_weight, 0.0) AS reconciled_net_weight,
    CASE
      WHEN movement_weight.stock_item_id IS NOT NULL
        THEN COALESCE(movement_weight.sold_quantity, 0)
      ELSE COALESCE(bill_weight.sold_quantity, 0)
    END AS sold_quantity
  FROM (
    SELECT stock_item_id
    FROM stock_movements
    WHERE movement_type IN ('SALE', 'SALE_RESTORE')
    UNION
    SELECT stock_item_id
    FROM stock_movements
    WHERE movement_type = 'WEIGHT_RECONCILIATION'
    UNION
    SELECT linked_stock_item_id AS stock_item_id
    FROM bill_items
    WHERE linked_stock_item_id IS NOT NULL
  ) source
  LEFT JOIN (
    SELECT
      bi.linked_stock_item_id AS stock_item_id,
      SUM(COALESCE(bi.quantity, 0)) AS sold_quantity,
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
          WHEN movement_type = 'SALE' THEN ABS(quantity_delta)
          WHEN movement_type = 'SALE_RESTORE' THEN -ABS(quantity_delta)
          ELSE 0
        END
      ) AS sold_quantity,
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
  LEFT JOIN (
    SELECT
      stock_item_id,
      SUM(COALESCE(net_weight_delta, 0.0)) AS reconciled_net_weight
    FROM stock_movements
    WHERE movement_type = 'WEIGHT_RECONCILIATION'
      AND source_type = 'STOCK_RECONCILIATION'
    GROUP BY stock_item_id
  ) reconcile_weight ON reconcile_weight.stock_item_id = source.stock_item_id
) sm ON sm.stock_item_id = s.id
''';
