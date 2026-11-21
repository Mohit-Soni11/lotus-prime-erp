import 'notification_item.dart';

/// Stable choices stay visible even when a category has no active reminders.
abstract final class NotificationFilters {
  static const _builtIn = [
    'All',
    'Unread',
    'Important',
    'Daily Tasks',
    'Day Book',
    'Metal Rates',
    'Inventory',
    'Due Invoices',
    'Orders & Advances',
    'Girvi',
    'Messages',
  ];
  static const _categories = {
    'Day Book',
    'Metal Rates',
    'Inventory',
    'Collections',
    'Orders',
    'Girvi',
  };

  static List<String> options(Iterable<NotificationItem> items) {
    final custom = items.map((item) => item.type).toSet()
      ..removeAll(_categories)
      ..removeAll(_builtIn);
    final sorted = custom.toList()..sort();
    return [..._builtIn, ...sorted];
  }

  static bool matches(String filter, NotificationItem item) => switch (filter) {
        'All' => true,
        'Unread' => !item.isRead,
        'Important' => item.isProtected,
        'Daily Tasks' => item.isDailyEssential,
        'Due Invoices' => item.type == 'Collections' ||
            item.billId != null ||
            (item.eventKey?.startsWith('due:') ?? false),
        'Orders & Advances' => item.type == 'Orders' ||
            (item.eventKey?.startsWith('order:') ?? false),
        'Messages' => !item.isOperational,
        _ => item.type == filter,
      };
}
