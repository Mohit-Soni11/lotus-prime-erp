const dayBookBillIssueSnapshotSchemaSql = <String>[
  '''CREATE TABLE IF NOT EXISTS bill_issue_snapshots (
    bill_id INTEGER PRIMARY KEY REFERENCES bills(id) ON DELETE RESTRICT,
    final_amount REAL NOT NULL,
    taxable_amount REAL NOT NULL,
    cgst_amount REAL NOT NULL,
    sgst_amount REAL NOT NULL,
    igst_amount REAL NOT NULL,
    issued_due REAL NOT NULL,
    issued_at INTEGER NOT NULL
  )''',
  '''CREATE TRIGGER IF NOT EXISTS bill_issue_snapshot_closed_insert
    BEFORE INSERT ON bill_issue_snapshots
    WHEN EXISTS (SELECT 1 FROM bills b JOIN finance_day_closures c
      ON b.bill_date < c.end_epoch WHERE b.id = NEW.bill_id)
    BEGIN SELECT RAISE(ABORT, 'Day Book invoice issue is closed'); END''',
  '''CREATE TRIGGER IF NOT EXISTS bill_issue_snapshot_closed_update
    BEFORE UPDATE ON bill_issue_snapshots
    WHEN EXISTS (SELECT 1 FROM bills b JOIN finance_day_closures c
      ON b.bill_date < c.end_epoch
      WHERE b.id = OLD.bill_id)
    BEGIN SELECT RAISE(ABORT, 'Day Book invoice issue is closed'); END''',
  '''CREATE TRIGGER IF NOT EXISTS bill_issue_snapshot_closed_delete
    BEFORE DELETE ON bill_issue_snapshots
    WHEN EXISTS (SELECT 1 FROM bills b JOIN finance_day_closures c
      ON b.bill_date < c.end_epoch
      WHERE b.id = OLD.bill_id)
    BEGIN SELECT RAISE(ABORT, 'Day Book invoice issue is closed'); END''',
];
