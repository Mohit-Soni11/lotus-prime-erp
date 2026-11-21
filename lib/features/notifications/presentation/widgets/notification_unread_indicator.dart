import 'dart:async';
import 'package:flutter/material.dart';
import '../notification_theme.dart';

class NotificationUnreadIndicator extends StatefulWidget {
  const NotificationUnreadIndicator({super.key});

  @override
  State<NotificationUnreadIndicator> createState() =>
      _NotificationUnreadIndicatorState();
}

class _NotificationUnreadIndicatorState
    extends State<NotificationUnreadIndicator> {
  Timer? _timer;
  bool _bright = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    _bright = true;
    if (TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context)) {
      _timer = Timer.periodic(const Duration(milliseconds: 900), (_) {
        if (mounted) setState(() => _bright = !_bright);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Unread notification',
        child: AnimatedOpacity(
          opacity: _bright ? 1 : 0.35,
          duration: const Duration(milliseconds: 300),
          child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: NotificationTheme.red, shape: BoxShape.circle)),
        ),
      );
}
