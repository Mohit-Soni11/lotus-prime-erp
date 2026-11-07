const dayBookBalanceVerificationSchemaSql = <String>[
  '''CREATE TABLE IF NOT EXISTS day_book_balance_verifications (
    day_key TEXT PRIMARY KEY,
    verified_at INTEGER NOT NULL,
    expected_cash REAL NOT NULL,
    actual_cash REAL NOT NULL CHECK (actual_cash >= 0),
    cash_variance REAL NOT NULL,
    expected_bank REAL NOT NULL,
    actual_bank REAL NOT NULL,
    bank_variance REAL NOT NULL,
    cash_category TEXT,
    cash_reason TEXT,
    bank_reason TEXT,
    cash_adjustment_txn_id TEXT UNIQUE,
    verified_by TEXT
  )''',
  '''CREATE TRIGGER IF NOT EXISTS day_book_balance_verified_day_insert
    BEFORE INSERT ON day_book_balance_verifications
    WHEN EXISTS (SELECT 1 FROM finance_day_closures
      WHERE day_key = NEW.day_key)
    BEGIN SELECT RAISE(ABORT, 'Finance day is closed'); END''',
  '''CREATE TRIGGER IF NOT EXISTS day_book_balance_verification_immutable_update
    BEFORE UPDATE ON day_book_balance_verifications
    BEGIN SELECT RAISE(ABORT, 'Balance verification is immutable'); END''',
  '''CREATE TRIGGER IF NOT EXISTS day_book_balance_verification_immutable_delete
    BEFORE DELETE ON day_book_balance_verifications
    BEGIN SELECT RAISE(ABORT, 'Balance verification is immutable'); END''',
];
