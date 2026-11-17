import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/dashboard/live_rates/live_rates_theme.dart';

class RatesHeader extends StatefulWidget {
  const RatesHeader({super.key});

  @override
  State<RatesHeader> createState() => _RatesHeaderState();
}

class _RatesHeaderState extends State<RatesHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _dateTimer;
  DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.45,
      upperBound: 1,
    )..repeat(reverse: true);
    _scheduleNextDay();
  }

  void _scheduleNextDay() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _dateTimer = Timer(tomorrow.difference(now), () {
      if (!mounted) return;
      setState(() => _today = DateTime.now());
      _scheduleNextDay();
    });
  }

  @override
  void dispose() {
    _dateTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd MMM yyyy').format(_today);
    const title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.view_agenda_outlined, color: LiveRatesColors.gold, size: 27),
        SizedBox(width: 11),
        Flexible(
          child: Text(
            LiveRatesStrings.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LiveRatesStyles.title,
          ),
        ),
      ],
    );
    final status = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: LiveRatesColors.muted, size: 16),
            const SizedBox(width: 6),
            Text(date, style: LiveRatesStyles.date),
          ],
        ),
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) =>
              Opacity(opacity: _pulse.value, child: child),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: LiveRatesColors.green, size: 9),
              SizedBox(width: 6),
              Text(
                LiveRatesStrings.live,
                style: LiveRatesStyles.live,
              ),
            ],
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 570
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 9), status],
            )
          : Row(
              children: [
                const Expanded(child: title),
                const SizedBox(width: 12),
                status,
              ],
            ),
    );
  }
}
