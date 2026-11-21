import 'package:flutter/material.dart';
import '../../domain/notification_item.dart';
import '../notification_theme.dart';
import 'notification_unread_indicator.dart';

class NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback? onOpen;
  final VoidCallback? onMarkRead;

  const NotificationCard(
      {super.key, required this.item, this.onOpen, this.onMarkRead});

  @override
  Widget build(BuildContext context) {
    final accent = NotificationTheme.accent(item.type);
    return Material(
      color: NotificationTheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: NotificationTheme.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: onOpen,
          hoverColor: NotificationTheme.gold.withValues(alpha: 0.05),
          child: Stack(children: [
            Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: ColoredBox(
                    color: NotificationTheme.gold
                        .withValues(alpha: item.isRead ? 0.5 : 1))),
            Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                child: Row(children: [
                  Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                              color: accent.withValues(alpha: 0.35))),
                      child: Icon(NotificationTheme.icon(item.type),
                          color: accent, size: 25)),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  child: Text(item.title,
                                      style: TextStyle(
                                          color: NotificationTheme.ink,
                                          fontSize: 15,
                                          height: 1.35,
                                          fontWeight: item.isRead
                                              ? FontWeight.w600
                                              : FontWeight.w700))),
                              if (!item.isRead)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 8, top: 6),
                                  child: NotificationUnreadIndicator(
                                      key: ValueKey(
                                          'notification-unread:${item.storageKey}')),
                                ),
                            ]),
                        if (item.desc.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(item.desc,
                              style: const TextStyle(
                                  color: NotificationTheme.muted,
                                  fontSize: 12.5,
                                  height: 1.5)),
                        ],
                        if (item.isProtected)
                          Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: NotificationTheme.gold
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: NotificationTheme.gold
                                              .withValues(alpha: 0.35))),
                                  child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.schedule_rounded,
                                            size: 13,
                                            color: NotificationTheme.goldInk),
                                        SizedBox(width: 5),
                                        Flexible(
                                            child: Text(
                                                'Retained until resolved',
                                                style: TextStyle(
                                                    color: NotificationTheme
                                                        .goldInk,
                                                    fontSize: 10.5))),
                                      ]))),
                      ])),
                  const SizedBox(width: 6),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    if (!item.isRead && onMarkRead != null)
                      IconButton(
                          tooltip: 'Mark as read',
                          onPressed: onMarkRead,
                          constraints:
                              const BoxConstraints(minWidth: 36, minHeight: 36),
                          icon: const Icon(Icons.done_all_rounded,
                              color: NotificationTheme.goldInk, size: 18)),
                    if (item.canOpen)
                      const Icon(Icons.chevron_right_rounded,
                          color: NotificationTheme.ink, size: 24),
                  ]),
                ])),
          ])),
    );
  }
}
