enum BackupFrequency { manual, daily, weekly, monthly }

class BackupSchedule {
  const BackupSchedule({
    this.frequency = BackupFrequency.manual,
    this.hour = 18,
    this.minute = 0,
    this.weekday = DateTime.sunday,
    this.monthDay = 1,
    this.lastCompletedAt,
    this.startedAt,
  });

  final BackupFrequency frequency;
  final int hour;
  final int minute;
  final int weekday;
  final int monthDay;
  final DateTime? lastCompletedAt;
  final DateTime? startedAt;

  DateTime? dueAt(DateTime now) {
    if (frequency == BackupFrequency.manual) return null;
    if (frequency == BackupFrequency.daily) {
      final today = DateTime(now.year, now.month, now.day, hour, minute);
      return today.isAfter(now)
          ? DateTime(now.year, now.month, now.day - 1, hour, minute)
          : today;
    }
    if (frequency == BackupFrequency.weekly) {
      final day = DateTime(
          now.year, now.month, now.day - (now.weekday - weekday + 7) % 7);
      final due = DateTime(day.year, day.month, day.day, hour, minute);
      return due.isAfter(now)
          ? DateTime(day.year, day.month, day.day - 7, hour, minute)
          : due;
    }
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final current =
        DateTime(now.year, now.month, monthDay.clamp(1, lastDay), hour, minute);
    return current.isAfter(now)
        ? DateTime(
            now.year,
            now.month - 1,
            monthDay.clamp(1, DateTime(now.year, now.month, 0).day),
            hour,
            minute)
        : current;
  }

  bool isDue(DateTime now) {
    final due = dueAt(now);
    return due != null &&
        !now.isBefore(due) &&
        (startedAt == null || !due.isBefore(startedAt!)) &&
        (lastCompletedAt == null || lastCompletedAt!.isBefore(due));
  }

  DateTime? nextRun(DateTime now) {
    final due = dueAt(now);
    if (due == null || isDue(now)) return due;
    if (now.isBefore(due) &&
        (lastCompletedAt == null || lastCompletedAt!.isBefore(due))) {
      return due;
    }
    return switch (frequency) {
      BackupFrequency.daily =>
        DateTime(due.year, due.month, due.day + 1, hour, minute),
      BackupFrequency.weekly =>
        DateTime(due.year, due.month, due.day + 7, hour, minute),
      BackupFrequency.monthly => DateTime(
          due.year,
          due.month + 1,
          monthDay.clamp(1, DateTime(due.year, due.month + 2, 0).day),
          hour,
          minute),
      BackupFrequency.manual => null,
    };
  }

  BackupSchedule completed(DateTime at) => BackupSchedule(
        frequency: frequency,
        hour: hour,
        minute: minute,
        weekday: weekday,
        monthDay: monthDay,
        lastCompletedAt: at,
        startedAt: startedAt,
      );

  Map<String, dynamic> toJson() => {
        'frequency': frequency.name,
        'hour': hour,
        'minute': minute,
        'weekday': weekday,
        'monthDay': monthDay,
        'lastCompletedAt': lastCompletedAt?.toIso8601String(),
        'startedAt': startedAt?.toIso8601String(),
      };

  factory BackupSchedule.fromJson(Map<String, dynamic> json) => BackupSchedule(
        frequency: BackupFrequency.values.firstWhere(
            (value) => value.name == json['frequency'],
            orElse: () => BackupFrequency.manual),
        hour: ((json['hour'] as num?)?.toInt() ?? 18).clamp(0, 23),
        minute: ((json['minute'] as num?)?.toInt() ?? 0).clamp(0, 59),
        weekday: ((json['weekday'] as num?)?.toInt() ?? 7).clamp(1, 7),
        monthDay: ((json['monthDay'] as num?)?.toInt() ?? 1).clamp(1, 31),
        lastCompletedAt:
            DateTime.tryParse(json['lastCompletedAt'] as String? ?? ''),
        startedAt: DateTime.tryParse(json['startedAt'] as String? ?? ''),
      );
}
