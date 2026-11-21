import 'package:drift/drift.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import '../domain/notification_item.dart';

/// Read and clear are acknowledgements, independent of the business condition.
/// A changed reminder becomes unread; clearing never hides a protected alert.
class NotificationStateRepository {
  final AppDatabase db;
  const NotificationStateRepository(this.db);

  Future<void> _ensureSchema() => db.customStatement('''
    CREATE TABLE IF NOT EXISTS notification_acknowledgements (
      recipient TEXT NOT NULL,
      event_key TEXT NOT NULL,
      fingerprint TEXT NOT NULL,
      is_read INTEGER NOT NULL DEFAULT 0,
      is_cleared INTEGER NOT NULL DEFAULT 0,
      updated_at INTEGER NOT NULL,
      PRIMARY KEY (recipient, event_key)
    )''');

  Future<List<NotificationItem>> apply(
      String recipient, List<NotificationItem> items) async {
    await _ensureSchema();
    final rows = await db.customSelect(
      'SELECT * FROM notification_acknowledgements WHERE recipient = ?',
      variables: [Variable.withString(recipient.toLowerCase())],
    ).get();
    final states = {for (final row in rows) row.read<String>('event_key'): row};
    final activeKeys = items.map((item) => item.storageKey).toSet();
    for (final key in states.keys) {
      if (!key.startsWith('message:') && !activeKeys.contains(key)) {
        await db.customStatement(
          'DELETE FROM notification_acknowledgements WHERE recipient = ? AND event_key = ?',
          [recipient.toLowerCase(), key],
        );
      }
    }
    final visible = <NotificationItem>[];
    for (final item in items) {
      final state = states[item.storageKey];
      final matches = state != null &&
          state.read<String>('fingerprint') == item.fingerprint;
      if (matches && !item.isProtected && state.read<int>('is_cleared') == 1) {
        continue;
      }
      visible.add(item.copyWith(
          isRead: state == null
              ? item.isRead
              : matches && state.read<int>('is_read') == 1));
    }
    visible.sort(NotificationItem.compare);
    return visible;
  }

  Future<void> markRead(String recipient, Iterable<NotificationItem> items) =>
      _save(recipient, items, clear: false);

  Future<void> clearMessages(
          String recipient, Iterable<NotificationItem> items) =>
      _save(recipient, items.where((item) => !item.isProtected), clear: true);

  Future<void> _save(String recipient, Iterable<NotificationItem> items,
      {required bool clear}) async {
    await _ensureSchema();
    await db.transaction(() async {
      for (final item in items) {
        await db.customStatement(
            '''INSERT INTO notification_acknowledgements
          (recipient, event_key, fingerprint, is_read, is_cleared, updated_at)
          VALUES (?, ?, ?, 1, ?, ?)
          ON CONFLICT(recipient, event_key) DO UPDATE SET
            fingerprint = excluded.fingerprint, is_read = 1,
            is_cleared = excluded.is_cleared, updated_at = excluded.updated_at''',
            [
              recipient.toLowerCase(),
              item.storageKey,
              item.fingerprint,
              clear ? 1 : 0,
              DateTime.now().millisecondsSinceEpoch
            ]);
      }
    });
  }
}
