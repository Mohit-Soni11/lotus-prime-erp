import 'package:flutter/material.dart';
import '../../domain/notification_item.dart';
import '../notification_theme.dart';

class NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback? onOpen;
  final VoidCallback? onMarkRead;
  const NotificationCard(
      {super.key, required this.item, this.onOpen, this.onMarkRead});

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        leading: Icon(NotificationTheme.icon(item.type),
            color:
                item.isRead ? NotificationTheme.muted : NotificationTheme.gold,
            size: 23),
        title: Text(item.title,
            style: TextStyle(
                color: NotificationTheme.ink,
                fontSize: 14,
                fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700)),
        subtitle:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 5),
          Text(item.desc,
              style: const TextStyle(
                  color: NotificationTheme.muted, fontSize: 12, height: 1.4)),
          if (item.isProtected)
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text('Retained until resolved',
                  style:
                      TextStyle(color: NotificationTheme.muted, fontSize: 10)),
            ),
        ]),
        trailing: !item.isRead && onMarkRead != null
            ? IconButton(
                tooltip: 'Mark as read',
                onPressed: onMarkRead,
                icon: const Icon(Icons.done_all_rounded,
                    color: NotificationTheme.gold, size: 18))
            : item.canOpen
                ? const Icon(Icons.chevron_right_rounded,
                    color: NotificationTheme.muted, size: 18)
                : null,
        onTap: onOpen,
      );
}
