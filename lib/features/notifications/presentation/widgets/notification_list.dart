import 'package:flutter/material.dart';
import '../../domain/notification_item.dart';
import 'notification_card.dart';
import 'notification_section_header.dart';

/// Builds cards lazily while keeping section counts tied to the current view.
class NotificationList extends StatelessWidget {
  final List<NotificationItem> items;
  final bool enabled;
  final ValueChanged<NotificationItem> onOpen;
  final ValueChanged<NotificationItem>? onMarkRead;

  const NotificationList(
      {super.key,
      required this.items,
      required this.enabled,
      required this.onOpen,
      this.onMarkRead});

  @override
  Widget build(BuildContext context) {
    final dailyCount = items.where((item) => item.sortRank < 10).length;
    return SliverPadding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        sliver: SliverList.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final item = items[index];
            final daily = item.sortRank < 10;
            final startsSection =
                index == 0 || (items[index - 1].sortRank < 10) != daily;
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (startsSection) ...[
                    if (index > 0) const SizedBox(height: 8),
                    NotificationSectionHeader(
                        daily: daily,
                        count: daily ? dailyCount : items.length - dailyCount),
                    const SizedBox(height: 12),
                  ],
                  NotificationCard(
                      item: item,
                      onOpen:
                          enabled && item.canOpen ? () => onOpen(item) : null,
                      onMarkRead: enabled && onMarkRead != null
                          ? () => onMarkRead!(item)
                          : null),
                ]);
          },
        ));
  }
}
