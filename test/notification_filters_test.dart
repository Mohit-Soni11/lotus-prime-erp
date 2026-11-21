import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/notifications/domain/notification_filters.dart';
import 'package:lotus_erp/features/notifications/domain/notification_item.dart';

void main() {
  test('due and delivery filters remain available without active reminders',
      () {
    expect(NotificationFilters.options([]),
        containsAll(['Due Invoices', 'Orders & Advances']));
  });

  test('due invoices and advance delivery have separate filters', () {
    final due = NotificationItem(
        id: 1,
        type: 'Collections',
        title: 'Due today',
        desc: '',
        targetRole: 'all',
        billId: 10,
        isOperational: true,
        eventKey: 'due:10');
    final order = NotificationItem(
        id: 2,
        type: 'Orders',
        title: 'Deliver advance',
        desc: '',
        targetRole: 'all',
        isOperational: true,
        eventKey: 'order:20');
    expect(NotificationFilters.matches('Due Invoices', due), isTrue);
    expect(NotificationFilters.matches('Due Invoices', order), isFalse);
    expect(NotificationFilters.matches('Orders & Advances', order), isTrue);
    expect(NotificationFilters.matches('Orders & Advances', due), isFalse);
    expect(due.isProtected, isFalse);
    expect(order.isProtected, isFalse);
  });
}
