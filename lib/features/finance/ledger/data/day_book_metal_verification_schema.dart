const dayBookMetalVerificationSchemaSql = <String>[
  '''CREATE TABLE IF NOT EXISTS day_book_metal_verifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    day_key TEXT NOT NULL,
    source_hash TEXT NOT NULL,
    snapshot_json TEXT NOT NULL,
    verified_at INTEGER NOT NULL,
    verified_by TEXT NOT NULL
  )''',
  '''CREATE INDEX IF NOT EXISTS idx_day_book_metal_verification_day
    ON day_book_metal_verifications (day_key, id DESC)''',
  '''CREATE TRIGGER IF NOT EXISTS day_book_metal_verification_closed_insert
    BEFORE INSERT ON day_book_metal_verifications
    WHEN EXISTS (SELECT 1 FROM finance_day_closures
      WHERE day_key = NEW.day_key)
    BEGIN SELECT RAISE(ABORT, 'Day Book metal count is closed'); END''',
  '''CREATE TRIGGER IF NOT EXISTS day_book_metal_verification_immutable_update
    BEFORE UPDATE ON day_book_metal_verifications
    BEGIN SELECT RAISE(ABORT, 'Day Book metal count is immutable'); END''',
  '''CREATE TRIGGER IF NOT EXISTS day_book_metal_verification_immutable_delete
    BEFORE DELETE ON day_book_metal_verifications
    BEGIN SELECT RAISE(ABORT, 'Day Book metal count is immutable'); END''',
];
