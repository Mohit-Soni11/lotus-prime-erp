import 'package:flutter/material.dart';
import '../notification_theme.dart';

class NotificationSectionHeader extends StatelessWidget {
  final bool daily;
  final int count;

  const NotificationSectionHeader(
      {super.key, required this.daily, required this.count});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: NotificationTheme.gold.withValues(alpha: 0.22)),
          gradient: LinearGradient(colors: [
            NotificationTheme.gold.withValues(alpha: 0.14),
            NotificationTheme.surface.withValues(alpha: 0.55)
          ]),
        ),
        child: Row(children: [
          Icon(
              daily
                  ? Icons.layers_outlined
                  : Icons.notifications_active_outlined,
              color: NotificationTheme.gold,
              size: 22),
          const SizedBox(width: 10),
          Expanded(
              child: Text(daily ? 'Daily Essentials' : 'Activity & Alerts',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
                color: NotificationTheme.gold.withValues(alpha: 0.1),
                border: Border.all(
                    color: NotificationTheme.gold.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(20)),
            child: Text('$count ${count == 1 ? 'message' : 'messages'}',
                style: const TextStyle(
                    fontSize: 11, color: NotificationTheme.goldInk)),
          ),
        ]),
      );
}
