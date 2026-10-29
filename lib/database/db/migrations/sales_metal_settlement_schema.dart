const createBillMetalPaymentAllocationsTableSql = '''
  CREATE TABLE IF NOT EXISTS bill_metal_payment_allocations (
    bill_id INTEGER NOT NULL REFERENCES bills(id) ON DELETE CASCADE,
    metal TEXT NOT NULL,
    gross_amount REAL NOT NULL DEFAULT 0,
    discount_amount REAL NOT NULL DEFAULT 0,
    gst_amount REAL NOT NULL DEFAULT 0,
    net_payable REAL NOT NULL,
    cash_paid REAL NOT NULL DEFAULT 0,
    upi_paid REAL NOT NULL DEFAULT 0,
    card_paid REAL NOT NULL DEFAULT 0,
    advance_paid REAL NOT NULL DEFAULT 0,
    settle_first INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (bill_id, metal)
  )
''';
