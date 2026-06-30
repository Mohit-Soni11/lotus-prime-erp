import 'package:drift/drift.dart';

import '../../base_table.dart';

@DataClassName('ShopPrintInformationSetting')
@TableIndex(
  name: 'idx_shop_print_information_tenant',
  columns: {#tenantId},
  unique: true,
)
class ShopPrintInformationSettings extends Table with BaseTable {
  TextColumn get tenantId => text()();

  TextColumn get enabledFieldIdsJson =>
      text().withDefault(const Constant('[]'))();
}
