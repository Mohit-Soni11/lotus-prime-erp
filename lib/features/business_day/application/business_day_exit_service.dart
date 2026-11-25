import '../data/business_day_repository.dart';

class BusinessDayExitService {
  final BusinessDayRepository repository;
  const BusinessDayExitService(this.repository);

  /// Window close never calls this service. Only the explicit business-exit
  /// action can request closing and then terminate the application.
  Future<bool> requestExit({
    required DateTime now,
    required Future<void> Function(DateTime day) openClosing,
    required Future<void> Function() exitApplication,
  }) async {
    final days = await repository.pendingDays(now);
    for (final day in days) {
      final closingVersion = await repository.closingVersion(day);
      await repository.requestClosing(day);
      await openClosing(day);
      // Trust newly persisted close evidence, never the UI/dialog return.
      if (await repository.closingVersion(day) <= closingVersion) return false;
      await repository.completeClosingRequest(day);
    }
    await exitApplication();
    return true;
  }
}
