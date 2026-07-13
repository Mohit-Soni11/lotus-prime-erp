import 'package:drift/drift.dart';
import 'package:lotus_erp/database/tables/base_table.dart';

// ============================================================
// 📦 DAILY RATES TABLE
// Python ke daily_rates table ka 1:1 Flutter/Drift version
// Future mein Settings se rate set karne par ye table update hogi
// ============================================================

@DataClassName('DailyRate')
class DailyRates extends Table with BaseTable {
  // Date (Unique — ek din ka ek hi rate hoga)
  // .unique() lagaya hai taaki insertOnConflictUpdate kaam kare
  DateTimeColumn get rateDate => dateTime().unique()();

  // Gold Rates (per 10gm, stored as text for decimal safety)
  TextColumn get gold24k => text().withDefault(const Constant('0'))();
  TextColumn get gold22k => text().withDefault(const Constant('0'))();
  TextColumn get gold18k => text().withDefault(const Constant('0'))();

  // Silver Rate (per kg)
  TextColumn get silverRateKg => text().withDefault(const Constant('0'))();

  // Silver per 10gm (Jewellery / Idols)
  TextColumn get silverJewellery => text().withDefault(const Constant('0'))();
  TextColumn get silverIdols => text().withDefault(const Constant('0'))();

  // Old Gold Purchase Rates (buy rate from customer)
  TextColumn get oldGold24kBuy => text().withDefault(const Constant('0'))();
  TextColumn get oldGold22kBuy => text().withDefault(const Constant('0'))();
  TextColumn get oldGold18kBuy => text().withDefault(const Constant('0'))();
  TextColumn get oldSilverBuy => text().withDefault(const Constant('0'))();

  // Change Percentage (vs yesterday)
  TextColumn get goldChangePercent =>
      text().withDefault(const Constant('+0.0'))();
  TextColumn get silverChangePercent =>
      text().withDefault(const Constant('+0.0'))();

  // Source / Notes
  TextColumn get source => text().withDefault(const Constant('Manual'))();
}
