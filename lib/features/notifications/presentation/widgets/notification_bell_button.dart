import 'package:flutter/material.dart';

class NotificationBellButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onPressed;
  const NotificationBellButton(
      {super.key, required this.unreadCount, required this.onPressed});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: unreadCount == 0
            ? 'Notifications · all read'
            : 'Notifications · $unreadCount unread',
        child: Semantics(
          button: true,
          label: 'Notifications, $unreadCount unread',
          child: SizedBox(
            width: 52,
            height: 52,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(
                  child: IconButton(
                onPressed: onPressed,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.07),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.13)),
                ),
                icon: const Icon(Icons.notifications_none_rounded,
                    color: Colors.white, size: 25),
              )),
              if (unreadCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: IgnorePointer(
                      child: Container(
                    key: const ValueKey('notification-unread-count'),
                    constraints:
                        const BoxConstraints(minWidth: 23, minHeight: 23),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: const Color(0xFFD92D20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF111827), width: 2)),
                    child: Text('$unreadCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  )),
                ),
            ]),
          ),
        ),
      );
}
