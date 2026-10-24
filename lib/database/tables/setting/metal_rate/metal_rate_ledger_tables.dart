import 'package:drift/drift.dart';

import '../../base_table.dart';

/// Authoritative current configuration for each supported metal.
///
/// The JSON payload keeps the pricing policy and purity matrix versioned as one
/// coherent aggregate, rather than scattering it across preferences and
/// ad-hoc SQLite tables.
@DataClassName('MetalRateProfileRecord')
class MetalRateProfiles extends Table with BaseTable {
  TextColumn get metalKey => text().unique()();
  TextColumn get profileJson => text()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  TextColumn get source => text().withDefault(const Constant('Manual'))();
}

/// Append-only audit log for every rate profile revision.
@DataClassName('MetalRateRevisionRecord')
class MetalRateRevisions extends Table with BaseTable {
  TextColumn get metalKey => text()();
  IntColumn get revision => integer()();
  TextColumn get profileJson => text()();
  TextColumn get source => text()();
  TextColumn get changeReason => text().nullable()();
  DateTimeColumn get effectiveAt => dateTime()();
}
