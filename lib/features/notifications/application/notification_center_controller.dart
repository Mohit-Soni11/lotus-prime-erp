import 'dart:async';
import 'package:drift/drift.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import '../data/notification_state_repository.dart';
import '../data/operational_alert_repository.dart';
import '../domain/notification_item.dart';

class NotificationCenterController {
  final AppDatabase db;
  NotificationCenterController(this.db);
  final _controller = StreamController<List<NotificationItem>>.broadcast();
  Stream<List<NotificationItem>> get stream => _controller.stream;
  List<NotificationItem> _items = const [];
  StreamSubscription<void>? _changes;
  Timer? _clock;
  String? _role;
  int _generation = 0;

  Future<void> start(String role) {
    _role = role.trim().toLowerCase();
    _changes ??= OperationalAlertRepository(db).watchChanges().listen(
      (_) => refresh(),
      onError: (Object error) {
        if (!_controller.isClosed) _controller.addError(error);
      },
    );
    // Raw SQL stock and Day Book tables do not publish Drift updates.
    _clock ??= Timer.periodic(const Duration(minutes: 1), (_) => refresh());
    return refresh();
  }

  Future<void> refresh() async {
    final role = _role;
    if (role == null || _controller.isClosed) return;
    final generation = ++_generation;
    try {
      final messages = await db.customSelect(
        '''SELECT id, type, title, desc, role, is_read
        FROM notifications WHERE LOWER(role) IN (?, 'all') ORDER BY id DESC''',
        variables: [Variable.withString(role)],
      ).get();
      final operational =
          await OperationalAlertRepository(db).load(DateTime.now());
      final items = [
        for (var i = 0; i < operational.length; i++)
          NotificationItem(
              id: -i - 1,
              type: operational[i].category,
              title: operational[i].title,
              desc: operational[i].description,
              targetRole: 'all',
              eventKey: operational[i].key,
              routeId: operational[i].routeId,
              location: operational[i].location,
              billId: operational[i].billId,
              customerId: operational[i].customerId,
              loanId: operational[i].loanId,
              isOperational: true,
              priority: operational[i].priority),
        for (final row in messages)
          NotificationItem(
              id: row.read<int>('id'),
              type: row.read<String>('type'),
              title: row.read<String>('title'),
              desc: row.read<String>('desc'),
              targetRole: row.read<String>('role'),
              isRead: row.read<int>('is_read') == 1),
      ];
      if (_controller.isClosed || generation != _generation) return;
      final visible = await NotificationStateRepository(db).apply(role, items);
      if (!_controller.isClosed && generation == _generation) {
        _items = visible;
        _controller.add(List.unmodifiable(visible));
      }
    } catch (error, stack) {
      if (!_controller.isClosed && generation == _generation) {
        _controller.addError(error, stack);
      }
    }
  }

  Future<void> markAllRead() => _acknowledge(_items);
  Future<void> markRead(NotificationItem item) => _acknowledge([item]);
  Future<void> _acknowledge(Iterable<NotificationItem> items) async {
    if (_role == null) return;
    await NotificationStateRepository(db).markRead(_role!, items);
    await refresh();
  }

  Future<void> clearMessages() async {
    if (_role == null) return;
    await NotificationStateRepository(db).clearMessages(_role!, _items);
    await refresh();
  }

  void dispose() {
    _generation++;
    _changes?.cancel();
    _clock?.cancel();
    _controller.close();
  }
}
