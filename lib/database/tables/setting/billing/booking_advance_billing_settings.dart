import 'package:drift/drift.dart';

import '../../base_table.dart';

@DataClassName('BookingAdvanceBillingSetting')
class BookingAdvanceBillingSettings extends Table with BaseTable {
  TextColumn get documentPrefix => text().withDefault(const Constant('BK'))();

  TextColumn get defaultBookingType =>
      text().withDefault(const Constant('OPEN'))();

  IntColumn get defaultDeliveryDays =>
      integer().withDefault(const Constant(15))();

  RealColumn get minimumAdvancePercent =>
      real().withDefault(const Constant(0.0))();

  RealColumn get minimumAdvanceAmount =>
      real().withDefault(const Constant(0.0))();

  BoolColumn get allowZeroAdvance =>
      boolean().withDefault(const Constant(true))();

  TextColumn get defaultPrintFormat =>
      text().withDefault(const Constant('a4'))();

  TextColumn get selectedTemplate =>
      text().withDefault(const Constant('default'))();

  IntColumn get printCopies => integer().withDefault(const Constant(1))();

  BoolColumn get includeCustomerAddress =>
      boolean().withDefault(const Constant(true))();

  BoolColumn get includeRateColumn =>
      boolean().withDefault(const Constant(true))();

  BoolColumn get printTermsAndConditions =>
      boolean().withDefault(const Constant(true))();

  BoolColumn get printFooterMessage =>
      boolean().withDefault(const Constant(true))();

  TextColumn get termsAndConditions => text().withDefault(const Constant(''))();

  TextColumn get footerMessage => text().withDefault(const Constant(''))();
}
