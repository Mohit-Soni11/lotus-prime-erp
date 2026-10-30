/// Keep booking lookup and dashboard counts aligned with cancellation rules.
const cancellableBookingPredicate = '''
  UPPER(TRIM(o.status)) IN ('PENDING', 'READY')
  AND NOT EXISTS (
    SELECT 1 FROM bills b
    WHERE b.source_advance_order_id = o.id
  )
  AND NOT EXISTS (
    SELECT 1 FROM return_vouchers v
    WHERE v.source_type = 'ADVANCE_BOOKING'
      AND v.source_id = o.id
      AND v.status <> 'VOIDED'
  )
''';
