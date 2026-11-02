const financeDayClosureSchemaSql = <String>[
  '''CREATE TABLE IF NOT EXISTS finance_day_closures (
    day_key TEXT PRIMARY KEY,
    start_epoch INTEGER NOT NULL,
    end_epoch INTEGER NOT NULL,
    closing_cash REAL NOT NULL,
    closed_at INTEGER NOT NULL,
    closed_by TEXT
  )''',
  '''CREATE TRIGGER IF NOT EXISTS cash_day_closed_insert
    BEFORE INSERT ON cash_transactions
    WHEN EXISTS (SELECT 1 FROM finance_day_closures
      WHERE NEW.txn_date >= start_epoch AND NEW.txn_date < end_epoch)
    BEGIN SELECT RAISE(ABORT, 'Finance day is closed'); END''',
  '''CREATE TRIGGER IF NOT EXISTS cash_day_closed_update
    BEFORE UPDATE ON cash_transactions
    WHEN EXISTS (SELECT 1 FROM finance_day_closures
      WHERE (OLD.txn_date >= start_epoch AND OLD.txn_date < end_epoch)
         OR (NEW.txn_date >= start_epoch AND NEW.txn_date < end_epoch))
    BEGIN SELECT RAISE(ABORT, 'Finance day is closed'); END''',
  '''CREATE TRIGGER IF NOT EXISTS cash_day_closed_delete
    BEFORE DELETE ON cash_transactions
    WHEN EXISTS (SELECT 1 FROM finance_day_closures
      WHERE OLD.txn_date >= start_epoch AND OLD.txn_date < end_epoch)
    BEGIN SELECT RAISE(ABORT, 'Finance day is closed'); END''',
  '''CREATE TRIGGER IF NOT EXISTS bank_day_closed_insert
    BEFORE INSERT ON bank_transactions
    WHEN EXISTS (SELECT 1 FROM finance_day_closures
      WHERE NEW.txn_date >= start_epoch AND NEW.txn_date < end_epoch)
    BEGIN SELECT RAISE(ABORT, 'Finance day is closed'); END''',
  '''CREATE TRIGGER IF NOT EXISTS bank_day_closed_update
    BEFORE UPDATE ON bank_transactions
    WHEN EXISTS (SELECT 1 FROM finance_day_closures
      WHERE (OLD.txn_date >= start_epoch AND OLD.txn_date < end_epoch)
         OR (NEW.txn_date >= start_epoch AND NEW.txn_date < end_epoch))
      AND (OLD.txn_date != NEW.txn_date
        OR OLD.account_id != NEW.account_id
        OR OLD.type != NEW.type
        OR OLD.category != NEW.category
        OR OLD.amount != NEW.amount
        OR OLD.payment_mode != NEW.payment_mode
        OR OLD.reference_id IS NOT NEW.reference_id
        OR OLD.reference_type IS NOT NEW.reference_type
        OR OLD.is_voided != NEW.is_voided)
    BEGIN SELECT RAISE(ABORT, 'Finance day is closed'); END''',
  '''CREATE TRIGGER IF NOT EXISTS bank_day_closed_delete
    BEFORE DELETE ON bank_transactions
    WHEN EXISTS (SELECT 1 FROM finance_day_closures
      WHERE OLD.txn_date >= start_epoch AND OLD.txn_date < end_epoch)
    BEGIN SELECT RAISE(ABORT, 'Finance day is closed'); END''',
];
