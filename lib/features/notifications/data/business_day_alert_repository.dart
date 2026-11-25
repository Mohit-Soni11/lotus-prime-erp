import 'package:intl/intl.dart';
import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/business_day/data/business_day_repository.dart';
import 'package:lotus_erp/features/notifications/domain/operational_alert.dart';

class BusinessDayAlertRepository {
  final AppDatabase db;
  const BusinessDayAlertRepository(this.db);

  Future<List<OperationalAlert>> load(DateTime now) async {
    final repo = BusinessDayRepository(db);
    final day = await repo.activeDay(now);
    if (await repo.isClosed(day)) return const [];
    final key = BusinessDayRepository.key(day);
    final label = DateFormat('dd MMM yyyy').format(day);
    final alerts = <OperationalAlert>[];
    if (day.isBefore(BusinessDayRepository.date(now))) {
      alerts.add(OperationalAlert(
        key: 'business:unfinished:$key',
        category: 'Day Book',
        priority: 0,
        title: 'Previous business day is still open',
        description:
            '$label · Reconcile cash and bank balances, then verify day closing.',
        routeId: AppRoutes.dayBookRoute,
        location: dayBookLocation(day, 'close'),
      ));
    } else if (await repo.closingRequested(day)) {
      alerts.add(OperationalAlert(
        key: 'business:closing:$key',
        category: 'Day Book',
        priority: 0,
        title: 'Day closing required',
        description:
            '$label · Reconcile cash and bank balances, then select Verify Day Closing.',
        routeId: AppRoutes.dayBookRoute,
        location: dayBookLocation(day, 'close'),
      ));
    }
    if (!await repo.openingVerified(day)) {
      alerts.add(OperationalAlert(
        key: 'business:opening:$key',
        category: 'Day Book',
        priority: 0,
        title: 'Opening balance verification',
        description:
            '$label · Verify cash and bank balances against the previous business day’s closing.',
        routeId: AppRoutes.dayBookRoute,
        location: dayBookLocation(day, 'verify'),
      ));
    }
    final metals = await repo.pendingRateMetals(now);
    if (metals.isNotEmpty) {
      alerts.add(OperationalAlert(
        key: 'business:rates:${BusinessDayRepository.key(now)}',
        category: 'Metal Rates',
        priority: 1,
        title: 'Today’s metal rates require an update',
        description:
            '${DateFormat('dd MMM yyyy').format(now)} · Update rates for ${metals.map((m) => '${m[0].toUpperCase()}${m.substring(1)}').join(', ')} in Metal Rate Master.',
        routeId: AppRoutes.settingsRoute,
        location: RoutePaths.metalRateMaster,
      ));
    }
    return alerts;
  }

  static String dayBookLocation(DateTime day, String action,
          {bool exitAfterClose = false}) =>
      Uri(
        path: RoutePaths.reportDayBook,
        queryParameters: {
          'date': BusinessDayRepository.date(day).toIso8601String(),
          'action': action,
          if (exitAfterClose) 'exitAfterClose': 'true',
        },
      ).toString();
}
