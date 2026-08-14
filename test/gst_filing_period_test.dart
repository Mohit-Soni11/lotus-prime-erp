import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/reports/gst_report/domain/gst_filing_period.dart';

void main() {
  test('GST filing period resets quarter cycle every financial year', () {
    final march = GstFilingPeriod.fromMonth(DateTime(2027, 3, 12));
    final april = GstFilingPeriod.fromMonth(DateTime(2027, 4, 1));

    expect(march.financialYearLabel, 'FY 2026-27');
    expect(march.quarter, 4);
    expect(march.monthPositionInQuarter, 3);
    expect(march.quarterRangeLabel, 'Jan-Mar');

    expect(april.financialYearLabel, 'FY 2027-28');
    expect(april.quarter, 1);
    expect(april.monthPositionInQuarter, 1);
    expect(april.quarterRangeLabel, 'Apr-Jun');
  });

  test('GST filing period calculates QRMP due dates for selected month', () {
    final august = GstFilingPeriod.fromMonth(DateTime(2026, 8, 14));

    expect(august.financialYearLabel, 'FY 2026-27');
    expect(august.quarter, 2);
    expect(august.monthPositionInQuarter, 2);
    expect(august.monthlyTaxPaymentDueDate, DateTime(2026, 9, 25));
    expect(august.iffDueDate, DateTime(2026, 9, 13));
    expect(august.gstr1QuarterDueDate, DateTime(2026, 10, 13));
    expect(august.gstr3bDueDateForStateCode('10'), DateTime(2026, 10, 24));
    expect(august.gstr3bDueDateForStateCode('27'), DateTime(2026, 10, 22));
  });

  test('quarter close month skips IFF and keeps final return dates', () {
    final september = GstFilingPeriod.fromMonth(DateTime(2026, 9, 30));

    expect(september.isQuarterClosingMonth, isTrue);
    expect(september.iffDueDate, isNull);
    expect(september.gstr1QuarterDueDate, DateTime(2026, 10, 13));
    expect(september.gstr3bQuarterDueDate24, DateTime(2026, 10, 24));
  });
}
