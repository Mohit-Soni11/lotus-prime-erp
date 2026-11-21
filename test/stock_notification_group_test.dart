import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/notifications/domain/notification_item.dart';
import 'package:lotus_erp/features/notifications/domain/stock_group_alert_policy.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/low_stock_alert/stock_alert_group.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/formatting/stock_alert_item_text.dart';
import 'helpers/stock_alert_fixtures.dart';

void main() {
  test('one hundred affected items produce exactly two stock notifications',
      () {
    final alerts = StockGroupAlertPolicy.build([
      for (var i = 0; i < 50; i++) stockAlertCard(item: 'Gold item $i'),
      for (var i = 0; i < 50; i++)
        stockAlertCard(
            metal: 'Silver', item: 'Silver item $i', grade: '925 (92.5%)'),
      stockAlertCard(item: 'Healthy item', available: 10),
      stockAlertCard(metal: 'Diamond'),
    ]);
    expect(alerts.map((alert) => alert.key), ['stock:GOLD', 'stock:SILVER']);
    expect(alerts.first.title, 'Gold stock alert');
    for (final alert in alerts) {
      expect(alert.description, '50 item groups are out of stock.');
      expect(alert.title, isNot(contains('(')));
      expect(Uri.parse(alert.location!).queryParameters['metal'],
          alert.title.split(' ').first);
      expect(alert.sourceRevision, isNotEmpty);
    }
  });

  test('mixed stock conditions remain accurate and resolved groups disappear',
      () {
    final alerts = StockGroupAlertPolicy.build([
      stockAlertCard(),
      stockAlertCard(item: 'Chain', available: 2),
    ]);
    expect(alerts.single.description,
        '2 item groups need replenishment: 1 out of stock and 1 low on stock.');
    expect(
        StockGroupAlertPolicy.build([stockAlertCard(available: 10)]), isEmpty);
  });

  test(
      'group membership changes the fingerprint even when counts are unchanged',
      () {
    final initial = StockAlertGroup.fromCards(
        [stockAlertCard(), stockAlertCard(item: 'Chain')]).single;
    final reordered = StockAlertGroup.fromCards(
        [stockAlertCard(item: 'Chain'), stockAlertCard()]).single;
    final changed = StockAlertGroup.fromCards(
        [stockAlertCard(), stockAlertCard(item: 'Necklace')]).single;
    expect(initial.revision, reordered.revision);
    expect(initial.description, changed.description);
    final item = NotificationItem(
        id: 1,
        type: 'Inventory',
        title: 'Gold stock alert',
        desc: initial.description,
        targetRole: 'all',
        eventKey: 'stock:GOLD',
        isOperational: true,
        sourceRevision: initial.revision);
    expect(item.copyWith(sourceRevision: changed.revision).fingerprint,
        isNot(item.fingerprint));
    expect(
        NotificationItem.fromJson(item.toJson()).fingerprint, item.fingerprint);
  });

  test('purity and available quantities use clean readable labels', () {
    expect(StockAlertItemText.grade('18KT (75%)'), '18KT · 75%');
    expect(StockAlertItemText.grade('925 (92.5%)'), '925 · 92.5%');
    expect(StockAlertItemText.availability(stockAlertCard(available: 1)),
        '1 piece available');
    expect(StockAlertItemText.availability(stockAlertCard(available: 2)),
        '2 pieces available');
  });
}
