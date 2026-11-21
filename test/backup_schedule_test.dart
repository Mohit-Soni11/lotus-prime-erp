import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/settings/backup_restore/domain/backup_schedule.dart';

void main() {
  test('manual backup never schedules a job', () {
    expect(const BackupSchedule().isDue(DateTime(2026, 11, 21)), isFalse);
    expect(const BackupSchedule().nextRun(DateTime(2026, 11, 21)), isNull);
  });
  test('daily schedule catches a missed evening backup on morning startup', () {
    final schedule = BackupSchedule(
        frequency: BackupFrequency.daily,
        hour: 18,
        lastCompletedAt: DateTime(2026, 11, 19, 18));
    final morning = DateTime(2026, 11, 21, 8);
    expect(schedule.isDue(morning), isTrue);
    final completed = schedule.completed(morning);
    expect(completed.isDue(morning), isFalse);
    expect(completed.nextRun(morning), DateTime(2026, 11, 21, 18));
  });
  test('new schedule does not backfill periods before it was enabled', () {
    final schedule = BackupSchedule(
        frequency: BackupFrequency.daily,
        hour: 18,
        startedAt: DateTime(2026, 11, 21, 8));
    expect(schedule.isDue(DateTime(2026, 11, 21, 9)), isFalse);
    expect(schedule.isDue(DateTime(2026, 11, 21, 18)), isTrue);
  });
  test('weekly schedule runs once and carries across month boundaries', () {
    final schedule = BackupSchedule(
        frequency: BackupFrequency.weekly,
        weekday: DateTime.monday,
        hour: 10,
        lastCompletedAt: DateTime(2026, 11, 23, 10));
    expect(schedule.isDue(DateTime(2026, 11, 29, 12)), isFalse);
    expect(schedule.nextRun(DateTime(2026, 11, 29, 12)),
        DateTime(2026, 11, 30, 10));
    expect(schedule.isDue(DateTime(2026, 12, 1, 9)), isTrue);
  });
  test('monthly day 31 clamps to the actual last day, including leap years',
      () {
    final schedule = BackupSchedule(
        frequency: BackupFrequency.monthly,
        monthDay: 31,
        hour: 18,
        lastCompletedAt: DateTime(2028, 1, 31, 18));
    expect(schedule.isDue(DateTime(2028, 2, 29, 17)), isFalse);
    expect(
        schedule.nextRun(DateTime(2028, 2, 29, 17)), DateTime(2028, 2, 29, 18));
    expect(schedule.isDue(DateTime(2028, 2, 29, 18)), isTrue);
  });
}
