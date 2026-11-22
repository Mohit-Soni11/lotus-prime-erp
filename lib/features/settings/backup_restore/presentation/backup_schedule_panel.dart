import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/backup_schedule.dart';
import 'backup_workspace_theme.dart';

class BackupSchedulePanel extends StatefulWidget {
  const BackupSchedulePanel(
      {super.key,
      required this.schedule,
      required this.enabled,
      required this.onSave});
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
  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  @override
  Widget build(BuildContext context) {
    final next = widget.schedule.nextRun(DateTime.now());
    return BackupPanel(
        title: 'Backup Schedule',
        icon: Icons.schedule_rounded,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(
              spacing: 14,
              runSpacing: 14,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                    width: 210,
                    child: DropdownButtonFormField<BackupFrequency>(
                        isExpanded: true,
                        key: const ValueKey('backup-frequency'),
                        initialValue: _frequency,
                        decoration:
                            const InputDecoration(labelText: 'Frequency'),
                        items: BackupFrequency.values
                            .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(switch (value) {
                                  BackupFrequency.manual => 'Manual only',
                                  BackupFrequency.daily => 'Daily',
                                  BackupFrequency.weekly => 'Weekly',
                                  BackupFrequency.monthly => 'Monthly'
                                })))
                            .toList(),
                        onChanged: !widget.enabled
                            ? null
                            : (value) => setState(() => _frequency = value!))),
                if (_frequency != BackupFrequency.manual)
                  OutlinedButton.icon(
                      onPressed: !widget.enabled
                          ? null
                          : () async {
                              final result = await showTimePicker(
                                  context: context, initialTime: _time);
                              if (mounted && result != null) {
                                setState(() => _time = result);
                              }
                            },
                      icon: const Icon(Icons.access_time_rounded),
                      label: Text(_time.format(context))),
                if (_frequency == BackupFrequency.weekly)
                  SizedBox(
                      width: 210,
                      child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: _weekday,
                          decoration:
                              const InputDecoration(labelText: 'Day of week'),
                          items: [
                            for (var index = 0; index < _days.length; index++)
                              DropdownMenuItem(
                                  value: index + 1, child: Text(_days[index]))
                          ],
                          onChanged: !widget.enabled
                              ? null
                              : (value) => setState(() => _weekday = value!))),
                if (_frequency == BackupFrequency.monthly)
                  SizedBox(
                      width: 210,
                      child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: _monthDay,
                          decoration:
                              const InputDecoration(labelText: 'Day of month'),
                          items: [
                            for (var day = 1; day <= 31; day++)
                              DropdownMenuItem(
                                  value: day, child: Text('Day $day'))
                          ],
                          onChanged: !widget.enabled
                              ? null
                              : (value) => setState(() => _monthDay = value!))),
                FilledButton.icon(
                    onPressed: !widget.enabled
                        ? null
                        : () => widget.onSave(BackupSchedule(
                            frequency: _frequency,
                            hour: _time.hour,
                            minute: _time.minute,
                            weekday: _weekday,
                            monthDay: _monthDay,
                            lastCompletedAt: widget.schedule.lastCompletedAt,
                            startedAt: DateTime.now())),
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Save Schedule')),
              ]),
          if (next != null) ...[
            const SizedBox(height: 14),
            Text('Scheduled: ${DateFormat('d MMM yyyy, h:mm a').format(next)}',
                style: const TextStyle(
                    fontSize: 13, color: BackupWorkspaceTheme.muted)),
          ],
        ]));
  }
}
