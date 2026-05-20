import 'package:drift/drift.dart';

// Yeh ek "Mixin" hai. Jo bhi table isse "mix" karegi, usme ye columns auto-add honge.
mixin BaseTable on Table {
  // Primary Key: Auto Increment ID
  IntColumn get id => integer().autoIncrement()();

  // Audit Trail: Record kab bana (Important for Syncing later)
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // Optional: Record kab update hua
  DateTimeColumn get updatedAt => dateTime().nullable()();
}
