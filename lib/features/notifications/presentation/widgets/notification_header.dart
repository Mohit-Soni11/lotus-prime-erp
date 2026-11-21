import 'package:flutter/material.dart';
import '../../domain/notification_item.dart';
import '../notification_theme.dart';

class NotificationHeader extends StatelessWidget {
  final List<NotificationItem> items;
  final VoidCallback onClose;

  const NotificationHeader(
      {super.key, required this.items, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final unread = items.where((item) => !item.isRead).length;
    final important = items.where((item) => item.isProtected).length;
    return ColoredBox(
        color: NotificationTheme.shell,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
          child: Row(children: [
            IconButton(
                tooltip: 'Back',
                onPressed: onClose,
                icon: const Icon(Icons.arrow_back_rounded,
                    color: NotificationTheme.shellInk)),
            Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    gradient: NotificationTheme.goldGradient,
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.notifications_none_rounded,
                    color: NotificationTheme.onGold, size: 27)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Notifications',
                      style: TextStyle(
                          color: NotificationTheme.shellInk,
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 8, runSpacing: 3, children: [
                    Text('${items.length} notifications', style: _summaryStyle),
                    Text('· $unread unread', style: _summaryStyle),
                    Text('· $important important', style: _summaryStyle),
                  ]),
                ])),
            IconButton(
                tooltip: 'Close',
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded,
                    color: NotificationTheme.shellInk)),
          ]),
        ));
  }

  static const _summaryStyle =
      TextStyle(color: NotificationTheme.shellMuted, fontSize: 12);
}
