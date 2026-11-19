import '../../constants/app_routes.dart';

abstract final class PaymentStatusNavigation {
  static String customer(int customerId) =>
      RoutePaths.customerProfileFor(customerId);

  static String invoice(int billId, int? customerId) => Uri(
        path: customerId == null
            ? RoutePaths.salesPos
            : RoutePaths.customerProfileFor(customerId),
        queryParameters: customerId == null
            ? {'editBillId': '$billId'}
            : {'billId': '$billId'},
      ).toString();
}
