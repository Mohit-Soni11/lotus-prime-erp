import '../../../constants/app_routes.dart';
import '../../stock/shared/domain/models/low_stock_alert/low_stock_alert_models.dart';
import '../../stock/shared/domain/models/low_stock_alert/stock_alert_group.dart';
import 'operational_alert.dart';

abstract final class StockGroupAlertPolicy {
  static List<OperationalAlert> build(Iterable<LowStockStockCard> cards) => [
        for (final group in StockAlertGroup.fromCards(cards))
          OperationalAlert(
            key: 'stock:${group.metalType.toUpperCase()}',
            category: 'Inventory',
            title: '${group.metalType} stock alert',
            description: group.description,
            routeId: AppRoutes.lowStockAlertRoute,
            location: Uri(
                path: RoutePaths.stockLowAlert,
                queryParameters: {'metal': group.metalType}).toString(),
            priority: group.stockoutCount > 0 ? 0 : 1,
            sourceRevision: group.revision,
          ),
      ];
}
