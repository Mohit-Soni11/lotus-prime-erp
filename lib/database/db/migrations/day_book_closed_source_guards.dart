/// Immutable source fields used by a closed Day Book projection.
/// Date columns in older raw tables may contain seconds or milliseconds.
Map<String, List<String>> get dayBookClosedSourceGuards => {
      'bills': [
        '''CREATE TRIGGER IF NOT EXISTS day_book_bill_closed_update
           BEFORE UPDATE ON bills
           WHEN (EXISTS (SELECT 1 FROM finance_day_closures c
                        WHERE OLD.bill_date >= c.start_epoch
                          AND OLD.bill_date < c.end_epoch)
              OR EXISTS (SELECT 1 FROM finance_day_closures c
                         WHERE NEW.bill_date >= c.start_epoch
                           AND NEW.bill_date < c.end_epoch))
             AND (NEW.bill_date IS NOT OLD.bill_date
               OR NEW.bill_no IS NOT OLD.bill_no
               OR NEW.customer_id IS NOT OLD.customer_id
               OR NEW.customer_name IS NOT OLD.customer_name
               OR NEW.mobile IS NOT OLD.mobile
               OR NEW.customer_gstin_snapshot IS NOT OLD.customer_gstin_snapshot
               OR NEW.place_of_supply_snapshot IS NOT OLD.place_of_supply_snapshot
               OR NEW.customer_state_code_snapshot IS NOT OLD.customer_state_code_snapshot
               OR NEW.shop_gstin_snapshot IS NOT OLD.shop_gstin_snapshot
               OR NEW.shop_state_code_snapshot IS NOT OLD.shop_state_code_snapshot
               OR NEW.billing_mode IS NOT OLD.billing_mode
               OR NEW.bill_type IS NOT OLD.bill_type
               OR NEW.document_type IS NOT OLD.document_type
               OR NEW.gst_pricing_mode IS NOT OLD.gst_pricing_mode
               OR NEW.tax_treatment IS NOT OLD.tax_treatment
               OR NEW.total_amount IS NOT OLD.total_amount
               OR NEW.discount IS NOT OLD.discount
               OR NEW.final_amount IS NOT OLD.final_amount
               OR NEW.taxable_amount IS NOT OLD.taxable_amount
               OR NEW.cgst_amount IS NOT OLD.cgst_amount
               OR NEW.sgst_amount IS NOT OLD.sgst_amount
               OR NEW.igst_amount IS NOT OLD.igst_amount
               OR NEW.gst_amount IS NOT OLD.gst_amount
               OR NEW.gst_exclusive_sales_amount IS NOT OLD.gst_exclusive_sales_amount
               OR NEW.gst_inclusive_sales_amount IS NOT OLD.gst_inclusive_sales_amount
               OR NEW.output_gst_liability_snapshot IS NOT OLD.output_gst_liability_snapshot
               OR NEW.making_total IS NOT OLD.making_total
               OR NEW.round_off_amount IS NOT OLD.round_off_amount
               OR NEW.cash_paid IS NOT OLD.cash_paid
               OR NEW.upi_paid IS NOT OLD.upi_paid
               OR NEW.card_paid IS NOT OLD.card_paid
               OR NEW.advance_paid IS NOT OLD.advance_paid
               OR NEW.old_gold_deduction IS NOT OLD.old_gold_deduction
               OR NEW.old_gold_mode IS NOT OLD.old_gold_mode
               OR NEW.source_advance_order_id IS NOT OLD.source_advance_order_id
               OR NEW.source_advance_order_no IS NOT OLD.source_advance_order_no
               OR (NEW.status IS NOT OLD.status AND
                   (NEW.status NOT IN ('PARTIALLY_RETURNED', 'RETURNED')
                    OR OLD.status NOT IN ('ACTIVE', 'PARTIALLY_RETURNED'))))
           BEGIN SELECT RAISE(ABORT, 'Day Book source day is closed'); END''',
        '''CREATE TRIGGER IF NOT EXISTS day_book_bill_closed_insert
           BEFORE INSERT ON bills
           WHEN EXISTS (SELECT 1 FROM finance_day_closures c
                        WHERE NEW.bill_date >= c.start_epoch
                          AND NEW.bill_date < c.end_epoch)
           BEGIN SELECT RAISE(ABORT, 'Day Book source day is closed'); END''',
        '''CREATE TRIGGER IF NOT EXISTS day_book_bill_closed_delete
           BEFORE DELETE ON bills
           WHEN EXISTS (SELECT 1 FROM finance_day_closures c
                        WHERE OLD.bill_date >= c.start_epoch
                          AND OLD.bill_date < c.end_epoch)
           BEGIN SELECT RAISE(ABORT, 'Day Book source day is closed'); END''',
      ],
      'bill_items': [
        _billItemGuard('insert', 'NEW'),
        _billItemGuard('update', 'OLD', also: 'NEW'),
        _billItemGuard('delete', 'OLD'),
      ],
      'purchase_voucher_items': _childTimestampGuards(
        'purchase_voucher_items',
        'purchase_voucher_id',
        'purchase_vouchers',
        'created_at',
      ),
      'return_voucher_lines': _childTimestampGuards(
        'return_voucher_lines',
        'return_voucher_id',
        'return_vouchers',
        'created_at',
      ),
      'stock_movements': _timestampGuards('stock_movements', 'occurred_at'),
      'order_advances': _timestampGuards('order_advances', 'payment_date'),
      'purchase_vouchers': _timestampGuards(
        'purchase_vouchers',
        'created_at',
        mutableStatus: true,
      ),
      'return_vouchers': _timestampGuards('return_vouchers', 'created_at'),
      'girvi_loans': [
        '''CREATE TRIGGER IF NOT EXISTS day_book_girvi_closed_insert
           BEFORE INSERT ON girvi_loans
           WHEN EXISTS (SELECT 1 FROM finance_day_closures c
                        WHERE NEW.start_date >= c.start_epoch
                          AND NEW.start_date < c.end_epoch)
           BEGIN SELECT RAISE(ABORT, 'Day Book source day is closed'); END''',
        '''CREATE TRIGGER IF NOT EXISTS day_book_girvi_closed_update
           BEFORE UPDATE ON girvi_loans
           WHEN (EXISTS (SELECT 1 FROM finance_day_closures c
                         WHERE OLD.start_date >= c.start_epoch
                           AND OLD.start_date < c.end_epoch)
              OR EXISTS (SELECT 1 FROM finance_day_closures c
                         WHERE NEW.start_date >= c.start_epoch
                           AND NEW.start_date < c.end_epoch))
            AND (NEW.ticket_no IS NOT OLD.ticket_no
              OR NEW.customer_id IS NOT OLD.customer_id
              OR NEW.start_date IS NOT OLD.start_date
              OR NEW.item_description IS NOT OLD.item_description
              OR NEW.item_count IS NOT OLD.item_count
              OR NEW.metal_type IS NOT OLD.metal_type
              OR NEW.metal_purity IS NOT OLD.metal_purity
              OR NEW.gross_weight IS NOT OLD.gross_weight
              OR NEW.stone_weight IS NOT OLD.stone_weight
              OR NEW.net_weight IS NOT OLD.net_weight
              OR NEW.loan_amount IS NOT OLD.loan_amount)
           BEGIN SELECT RAISE(ABORT, 'Day Book source day is closed'); END''',
        '''CREATE TRIGGER IF NOT EXISTS day_book_girvi_closed_delete
           BEFORE DELETE ON girvi_loans
           WHEN EXISTS (SELECT 1 FROM finance_day_closures c
                        WHERE OLD.start_date >= c.start_epoch
                          AND OLD.start_date < c.end_epoch)
           BEGIN SELECT RAISE(ABORT, 'Day Book source day is closed'); END''',
      ],
      'girvi_loan_items': [
        _girviItemGuard('insert', 'NEW'),
        _girviItemGuard('update', 'OLD', also: 'NEW'),
        _girviItemGuard('delete', 'OLD'),
      ],
      'shop_profiles': [
        '''CREATE TRIGGER IF NOT EXISTS day_book_cash_opening_insert_guard
           BEFORE INSERT ON shop_profiles
           WHEN NEW.opening_cash_balance != 0
             AND EXISTS (SELECT 1 FROM finance_day_closures)
           BEGIN SELECT RAISE(ABORT, 'Day Book opening cash is locked'); END''',
        '''CREATE TRIGGER IF NOT EXISTS day_book_cash_opening_immutable
           BEFORE UPDATE ON shop_profiles
           WHEN NEW.opening_cash_balance IS NOT OLD.opening_cash_balance
             AND EXISTS (SELECT 1 FROM finance_day_closures)
           BEGIN SELECT RAISE(ABORT, 'Day Book opening cash is locked'); END''',
      ],
      'bank_accounts': [
        '''CREATE TRIGGER IF NOT EXISTS day_book_bank_opening_insert_guard
           BEFORE INSERT ON bank_accounts
           WHEN EXISTS (SELECT 1 FROM finance_day_closures c
                        WHERE NEW.active_since < c.end_epoch)
           BEGIN SELECT RAISE(ABORT, 'Day Book bank opening is locked'); END''',
        '''CREATE TRIGGER IF NOT EXISTS day_book_bank_opening_immutable
           BEFORE UPDATE ON bank_accounts
           WHEN (NEW.opening_balance IS NOT OLD.opening_balance
              OR NEW.active_since IS NOT OLD.active_since)
             AND EXISTS (SELECT 1 FROM finance_day_closures)
           BEGIN SELECT RAISE(ABORT, 'Day Book bank opening is locked'); END''',
        '''CREATE TRIGGER IF NOT EXISTS day_book_bank_opening_delete_guard
           BEFORE DELETE ON bank_accounts
           WHEN EXISTS (SELECT 1 FROM finance_day_closures c
                        WHERE OLD.active_since < c.end_epoch)
           BEGIN SELECT RAISE(ABORT, 'Day Book bank opening is locked'); END''',
      ],
      'finance_day_closures': [
        '''CREATE TRIGGER IF NOT EXISTS day_book_close_immutable_update
           BEFORE UPDATE ON finance_day_closures
           BEGIN SELECT RAISE(ABORT, 'Day Book close is immutable'); END''',
        '''CREATE TRIGGER IF NOT EXISTS day_book_close_immutable_delete
           BEFORE DELETE ON finance_day_closures
           BEGIN SELECT RAISE(ABORT, 'Day Book close is immutable'); END''',
      ],
    };

String _billItemGuard(String action, String row, {String? also}) {
  String closed(String alias) => '''EXISTS (
      SELECT 1 FROM bills b JOIN finance_day_closures c
      ON b.bill_date >= c.start_epoch AND b.bill_date < c.end_epoch
      WHERE b.id = $alias.bill_id)''';
  return '''CREATE TRIGGER IF NOT EXISTS day_book_bill_item_closed_$action
    BEFORE ${action.toUpperCase()} ON bill_items
    WHEN ${closed(row)}${also == null ? '' : ' OR ${closed(also)}'}
    BEGIN SELECT RAISE(ABORT, 'Day Book source day is closed'); END''';
}

String _girviItemGuard(String action, String row, {String? also}) {
  String closed(String alias) => '''EXISTS (
      SELECT 1 FROM girvi_loans l JOIN finance_day_closures c
      ON l.start_date >= c.start_epoch AND l.start_date < c.end_epoch
      WHERE l.id = $alias.girvi_id)''';
  final immutableFields = action == 'update'
      ? '''AND (NEW.girvi_id IS NOT OLD.girvi_id
          OR NEW.serial_no IS NOT OLD.serial_no
          OR NEW.item_name IS NOT OLD.item_name
          OR NEW.metal_type IS NOT OLD.metal_type
          OR NEW.purity IS NOT OLD.purity
          OR NEW.purity_factor IS NOT OLD.purity_factor
          OR NEW.pieces IS NOT OLD.pieces
          OR NEW.gross_weight IS NOT OLD.gross_weight
          OR NEW.less_weight IS NOT OLD.less_weight
          OR NEW.net_weight IS NOT OLD.net_weight)'''
      : '';
  return '''CREATE TRIGGER IF NOT EXISTS day_book_girvi_item_closed_$action
    BEFORE ${action.toUpperCase()} ON girvi_loan_items
    WHEN (${closed(row)}${also == null ? '' : ' OR ${closed(also)}'}) $immutableFields
    BEGIN SELECT RAISE(ABORT, 'Day Book source day is closed'); END''';
}

List<String> _childTimestampGuards(
  String table,
  String foreignKey,
  String parentTable,
  String parentDate,
) {
  String closed(String alias) => '''EXISTS (
    SELECT 1 FROM $parentTable p JOIN finance_day_closures c
      ON (p.$parentDate >= c.start_epoch AND p.$parentDate < c.end_epoch)
      OR (p.$parentDate >= c.start_epoch * 1000
          AND p.$parentDate < c.end_epoch * 1000)
    WHERE p.id = $alias.$foreignKey)''';
  return [
    '''CREATE TRIGGER IF NOT EXISTS day_book_${table}_closed_insert
       BEFORE INSERT ON $table WHEN ${closed('NEW')}
       BEGIN SELECT RAISE(ABORT, 'Day Book source day is closed'); END''',
    '''CREATE TRIGGER IF NOT EXISTS day_book_${table}_closed_update
       BEFORE UPDATE ON $table WHEN ${closed('OLD')} OR ${closed('NEW')}
       BEGIN SELECT RAISE(ABORT, 'Day Book source day is closed'); END''',
    '''CREATE TRIGGER IF NOT EXISTS day_book_${table}_closed_delete
       BEFORE DELETE ON $table WHEN ${closed('OLD')}
       BEGIN SELECT RAISE(ABORT, 'Day Book source day is closed'); END''',
  ];
}

List<String> _timestampGuards(String table, String column,
    {bool mutableStatus = false}) {
  final immutablePurchaseFields = [
    'voucher_no',
    'sequence_no',
    'supplier_invoice_no',
    'source_type',
    'customer_id',
    'supplier_id',
    'party_name',
    'contact_name',
    'mobile',
    'city',
    'pan_number',
    'gst_number',
    'tax_type',
    'discount_type',
    'discount_value',
    'discount_amount',
    'gross_amount',
    'taxable_amount',
    'gst_amount',
    'cgst_amount',
    'sgst_amount',
    'grand_total',
    'cash_paid',
    'upi_paid',
    'bank_paid',
    'card_paid',
    'total_paid',
    'balance_due',
    'rate_per_kg',
    'metal_paid_gross_weight',
    'metal_paid_purity',
    'metal_paid_fine',
    'metal_paid_value',
    'due_mode',
    'excess_mode',
    'promise_date',
    'payment_meta',
    'seller_photo_path',
    'payment_status',
    'stock_entry_count',
    'created_at',
  ];
  final immutablePurchaseChanges = immutablePurchaseFields
      .map((field) => 'NEW.$field IS NOT OLD.$field')
      .join(' OR ');
  String closed(String alias) => '''EXISTS (
    SELECT 1 FROM finance_day_closures c
    WHERE ($alias.$column >= c.start_epoch AND $alias.$column < c.end_epoch)
       OR ($alias.$column >= c.start_epoch * 1000
           AND $alias.$column < c.end_epoch * 1000))''';
  return [
    '''CREATE TRIGGER IF NOT EXISTS day_book_${table}_closed_insert
       BEFORE INSERT ON $table WHEN ${closed('NEW')}
       BEGIN SELECT RAISE(ABORT, 'Day Book source day is closed'); END''',
    '''CREATE TRIGGER IF NOT EXISTS day_book_${table}_closed_update
       BEFORE UPDATE ON $table WHEN (${closed('OLD')} OR ${closed('NEW')})
         ${mutableStatus ? "AND (($immutablePurchaseChanges) OR (NEW.status IS NOT OLD.status AND (NEW.status NOT IN ('PARTIALLY_RETURNED', 'RETURNED') OR OLD.status NOT IN ('SAVED', 'PARTIALLY_RETURNED'))))" : ''}
       BEGIN SELECT RAISE(ABORT, 'Day Book source day is closed'); END''',
    '''CREATE TRIGGER IF NOT EXISTS day_book_${table}_closed_delete
       BEFORE DELETE ON $table WHEN ${closed('OLD')}
       BEGIN SELECT RAISE(ABORT, 'Day Book source day is closed'); END''',
  ];
}
