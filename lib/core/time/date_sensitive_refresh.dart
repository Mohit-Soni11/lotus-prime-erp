import 'dart:async';

import 'package:flutter/widgets.dart';

/// Refreshes date-sensitive screens after a calendar rollover, a due event,
/// or a return to the app. Database streams remain responsible for data edits.
class DateSensitiveRefresh with WidgetsBindingObserver {
  DateSensitiveRefresh({
    required Future<void> Function() onRefresh,
    bool Function(DateTime now)? hasDueEvent,
  })  : _onRefresh = onRefresh,
        _hasDueEvent = hasDueEvent,
        _observedDay = DateTime.now() {
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _checkClock());
  }

  final Future<void> Function() _onRefresh;
  final bool Function(DateTime now)? _hasDueEvent;
  DateTime _observedDay;
  late final Timer _timer;
  bool _refreshing = false;
  bool _refreshRequested = false;
  bool _disposed = false;

  void _checkClock() {
    final now = DateTime.now();
    final dayChanged = now.year != _observedDay.year ||
        now.month != _observedDay.month ||
        now.day != _observedDay.day;
    if (dayChanged || (_hasDueEvent?.call(now) ?? false)) {
      _observedDay = now;
      _refresh();
    }
  }

  Future<void> _refresh() async {
    if (_disposed) return;
    if (_refreshing) {
      _refreshRequested = true;
      return;
    }
    _refreshing = true;
    try {
      await _onRefresh();
    } finally {
      _refreshing = false;
      if (_refreshRequested && !_disposed) {
        _refreshRequested = false;
        _refresh();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _observedDay = DateTime.now();
      _refresh();
    }
  }

  void dispose() {
    _disposed = true;
    _timer.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
