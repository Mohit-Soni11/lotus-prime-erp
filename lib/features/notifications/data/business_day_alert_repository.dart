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
        title: 'Business day $label is still open',
        description:
            'Complete its opening verification, physical cash and bank matching, then Verify & Close Day.',
        routeId: AppRoutes.dayBookRoute,
        location: dayBookLocation(day, 'close'),
      ));
    } else if (await repo.closingRequested(day)) {
      alerts.add(OperationalAlert(
        key: 'business:closing:$key',
        category: 'Day Book',
        priority: 0,
        title: 'Complete Day Book closing',
        description:
            '$label · match physical cash and bank, then Verify & Close Day. Business exit is pending.',
        routeId: AppRoutes.dayBookRoute,
        location: dayBookLocation(day, 'close'),
      ));
    }
    if (!await repo.openingVerified(day)) {
      alerts.add(OperationalAlert(
        key: 'business:opening:$key',
        category: 'Day Book',
        priority: 0,
        title: 'Verify opening cash and bank balance',
        description:
            '$label · compare available cash and bank with the last business closing. Save Daily Balance Verification.',
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
        title: 'Update today’s metal rates',
        description:
            '${DateFormat('dd MMM yyyy').format(now)} · save rates for ${metals.map((m) => '${m[0].toUpperCase()}${m.substring(1)}').join(', ')} in Metal Rate Master.',
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
