import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/notifications/data/notification_state_repository.dart';
import 'package:lotus_erp/features/notifications/domain/notification_item.dart';

void main() {
  late AppDatabase db;
  late NotificationStateRepository repo;
  NotificationItem alert(String key, {String desc = 'Pending'}) =>
      NotificationItem(
        id: -1,
        type: 'Inventory',
        title: key,
        desc: desc,
        targetRole: 'all',
        eventKey: key,
        isOperational: true,
      );
  NotificationItem message(int id) => NotificationItem(
        id: id,
        type: 'General',
        title: 'Message $id',
        desc: 'Information',
        targetRole: 'all',
      );
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = NotificationStateRepository(db);
  });
  tearDown(() => db.close());

  test('business tasks always precede stock and other activity', () async {
    final result = await repo.apply('owner', [
      message(5),
      alert('stock:gold:ring'),
      alert('business:closing:20261121'),
      alert('business:rates:20261121'),
      alert('business:opening:20261121')
    ]);
    expect(result.take(3).map((i) => i.eventKey), [
      'business:opening:20261121',
      'business:rates:20261121',
      'business:closing:20261121',
    ]);
  });
  test('read status persists and does not remove protected alerts', () async {
    final items = [alert('stock:gold:ring'), message(1)];
    await repo.markRead('owner', items);
    final result = await NotificationStateRepository(db).apply('OWNER', items);
    expect(result, hasLength(2));
    expect(result.every((i) => i.isRead), isTrue);
    expect((await repo.apply('staff', items)).every((i) => !i.isRead), isTrue);
  });
  test(
      'clear suppresses ordinary messages across reloads and protects active alerts',
      () async {
    final items = [
      alert('business:opening:20261121'),
      alert('stock:gold:ring'),
      message(1)
    ];
    await repo.clearMessages('owner', items);
    final result = await NotificationStateRepository(db).apply('owner', items);
    expect(result, hasLength(2));
    expect(result.every((i) => i.isProtected), isTrue);
    expect(result.every((i) => !i.isRead), isTrue);
    expect((await repo.apply('owner', [...items, message(2)])).last.id, 2);
  });
  test('changed due or inventory details become unread again', () async {
    final original = alert('due:1', desc: 'Collect 100');
    await repo.markRead('owner', [original]);
    expect((await repo.apply('owner', [original])).single.isRead, isTrue);
    expect(
        (await repo.apply('owner', [original.copyWith(desc: 'Collect 50')]))
            .single
            .isRead,
        isFalse);
  });
  test('a resolved stock alert recurring later becomes unread', () async {
    final item = alert('stock:gold:ring');
    await repo.markRead('owner', [item]);
    await repo.apply('owner', []);
    expect((await repo.apply('owner', [item])).single.isRead, isFalse);
  });
}
