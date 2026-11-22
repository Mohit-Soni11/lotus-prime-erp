import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/backup_schedule.dart';
import 'backup_workspace_theme.dart';

class BackupSchedulePanel extends StatefulWidget {
  const BackupSchedulePanel({
    super.key,
    required this.schedule,
    required this.enabled,
    required this.onSave,
  });

  final BackupSchedule schedule;
  final bool enabled;
  final ValueChanged<BackupSchedule> onSave;

  @override
  State<BackupSchedulePanel> createState() => _BackupSchedulePanelState();
}

class _BackupSchedulePanelState extends State<BackupSchedulePanel> {
  late BackupFrequency _frequency = widget.schedule.frequency;
  late TimeOfDay _time =
      TimeOfDay(hour: widget.schedule.hour, minute: widget.schedule.minute);
  late int _weekday = widget.schedule.weekday;
  late int _monthDay = widget.schedule.monthDay;

  @override
  void didUpdateWidget(covariant BackupSchedulePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.schedule.frequency != widget.schedule.frequency ||
        oldWidget.schedule.hour != widget.schedule.hour ||
        oldWidget.schedule.minute != widget.schedule.minute ||
        oldWidget.schedule.weekday != widget.schedule.weekday ||
        oldWidget.schedule.monthDay != widget.schedule.monthDay) {
      _frequency = widget.schedule.frequency;
      _time =
          TimeOfDay(hour: widget.schedule.hour, minute: widget.schedule.minute);
      _weekday = widget.schedule.weekday;
      _monthDay = widget.schedule.monthDay;
    }
  }

  int get _hour12 => _time.hourOfPeriod == 0 ? 12 : _time.hourOfPeriod;
  bool get _isPm => _time.period == DayPeriod.pm;

  BackupSchedule get _draft => BackupSchedule(
      frequency: _frequency,
      hour: _time.hour,
      minute: _time.minute,
      weekday: _weekday,
      monthDay: _monthDay,
      lastCompletedAt: widget.schedule.lastCompletedAt,
      startedAt: DateTime.now());

  void _setTime({int? hour12, int? minute, bool? isPm}) {
    final selectedHour = hour12 ?? _hour12;
    final selectedPeriod = isPm ?? _isPm;
    setState(() {
      _time = TimeOfDay(
        hour: (selectedHour % 12) + (selectedPeriod ? 12 : 0),
        minute: minute ?? _time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final automatic = _frequency != BackupFrequency.manual;
    final next = automatic ? _draft.nextRun(DateTime.now()) : null;

    return BackupPanel(
      title: 'Backup Schedule',
      icon: Icons.calendar_month_rounded,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Frequency',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: BackupWorkspaceTheme.muted)),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<BackupFrequency>(
                isExpanded: true,
                key: const ValueKey('backup-frequency'),
                initialValue: _frequency,
                decoration: const InputDecoration(),
                items: BackupFrequency.values
                    .map((value) => DropdownMenuItem(
                        value: value, child: Text(_frequencyLabel(value))))
                    .toList(),
                onChanged: !widget.enabled
                    ? null
                    : (value) => setState(() => _frequency = value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: automatic
              ? _AutomaticScheduleCard(
                  key: ValueKey(_frequency),
                  frequency: _frequency,
                  hour12: _hour12,
                  minute: _time.minute,
                  isPm: _isPm,
                  weekday: _weekday,
                  monthDay: _monthDay,
                  enabled: widget.enabled,
                  onHourChanged: (value) => _setTime(hour12: value),
                  onMinuteChanged: (value) => _setTime(minute: value),
                  onPeriodChanged: (value) => _setTime(isPm: value),
                  onWeekdayChanged: (value) => setState(() => _weekday = value),
                  onMonthDayChanged: (value) =>
                      setState(() => _monthDay = value),
                )
              : const _ManualScheduleMessage(key: ValueKey('manual')),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: !widget.enabled ? null : () => widget.onSave(_draft),
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save Schedule'),
            ),
            if (next != null) _NextRunLabel(next: next),
          ],
        ),
      ]),
    );
  }

  String _frequencyLabel(BackupFrequency value) => switch (value) {
        BackupFrequency.manual => 'Manual only',
        BackupFrequency.daily => 'Daily',
        BackupFrequency.weekly => 'Weekly',
        BackupFrequency.monthly => 'Monthly',
      };
}

class _AutomaticScheduleCard extends StatelessWidget {
  const _AutomaticScheduleCard({
    super.key,
    required this.frequency,
    required this.hour12,
    required this.minute,
    required this.isPm,
    required this.weekday,
    required this.monthDay,
    required this.enabled,
    required this.onHourChanged,
    required this.onMinuteChanged,
    required this.onPeriodChanged,
    required this.onWeekdayChanged,
    required this.onMonthDayChanged,
  });

  final BackupFrequency frequency;
  final int hour12;
  final int minute;
  final bool isPm;
  final int weekday;
  final int monthDay;
  final bool enabled;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;
  final ValueChanged<bool> onPeriodChanged;
  final ValueChanged<int> onWeekdayChanged;
  final ValueChanged<int> onMonthDayChanged;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: BackupWorkspaceTheme.surfaceLow,
          border: Border.all(color: BackupWorkspaceTheme.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Wrap(
          spacing: 14,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            const _ScheduleFieldLabel(
                label: 'Backup time', icon: Icons.access_time_rounded),
            _ScheduleDropdown<int>(
              label: 'Hour',
              width: 104,
              value: hour12,
              enabled: enabled,
              items: [
                for (var hour = 1; hour <= 12; hour++)
                  DropdownMenuItem(value: hour, child: Text('$hour')),
              ],
              onChanged: onHourChanged,
            ),
            _ScheduleDropdown<int>(
              label: 'Minute',
              width: 112,
              value: minute,
              enabled: enabled,
              items: [
                for (var value = 0; value < 60; value++)
                  DropdownMenuItem(
                      value: value,
                      child: Text(value.toString().padLeft(2, '0'))),
              ],
              onChanged: onMinuteChanged,
            ),
            _ScheduleDropdown<bool>(
              label: 'AM / PM',
              width: 124,
              value: isPm,
              enabled: enabled,
              items: const [
                DropdownMenuItem(value: false, child: Text('AM')),
                DropdownMenuItem(value: true, child: Text('PM')),
              ],
              onChanged: onPeriodChanged,
            ),
            if (frequency == BackupFrequency.weekly)
              _ScheduleDropdown<int>(
                label: 'Every',
                width: 180,
                value: weekday,
                enabled: enabled,
                items: [
                  for (var index = 0; index < 7; index++)
                    DropdownMenuItem(
                        value: index + 1, child: Text(_weekdayName(index + 1))),
                ],
                onChanged: onWeekdayChanged,
              ),
            if (frequency == BackupFrequency.monthly)
              _ScheduleDropdown<int>(
                label: 'On day',
                width: 150,
                value: monthDay,
                enabled: enabled,
                items: [
                  for (var day = 1; day <= 31; day++)
                    DropdownMenuItem(value: day, child: Text('Day $day')),
                ],
                onChanged: onMonthDayChanged,
              ),
          ],
        ),
      );

  static String _weekdayName(int weekday) => const [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ][weekday - 1];
}

class _ScheduleFieldLabel extends StatelessWidget {
  const _ScheduleFieldLabel({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 130,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: BackupWorkspaceTheme.amber, size: 20),
          const SizedBox(width: 8),
          Flexible(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: BackupWorkspaceTheme.ink))),
        ]),
      );
}

class _ScheduleDropdown<T> extends StatelessWidget {
  const _ScheduleDropdown({
    required this.label,
    required this.width,
    required this.value,
    required this.enabled,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final double width;
  final T value;
  final bool enabled;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: DropdownButtonFormField<T>(
          isExpanded: true,
          initialValue: value,
          decoration: InputDecoration(labelText: label),
          items: items,
          onChanged: !enabled
              ? null
              : (value) {
                  if (value != null) onChanged(value);
                },
        ),
      );
}

class _ManualScheduleMessage extends StatelessWidget {
  const _ManualScheduleMessage({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BackupWorkspaceTheme.surfaceLow,
          border: Border.all(color: BackupWorkspaceTheme.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(children: [
          Icon(Icons.info_outline_rounded, color: BackupWorkspaceTheme.muted),
          SizedBox(width: 10),
          Expanded(
              child: Text(
                  'Automatic backups are off. Choose Daily, Weekly or Monthly to set a backup time.')),
        ]),
      );
}

class _NextRunLabel extends StatelessWidget {
  const _NextRunLabel({required this.next});

  final DateTime next;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: BackupWorkspaceTheme.gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Next automatic backup: ${DateFormat('d MMM yyyy, h:mm a').format(next)}',
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: BackupWorkspaceTheme.ink),
        ),
      );
}
