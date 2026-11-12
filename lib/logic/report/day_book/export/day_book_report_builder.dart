import 'day_book_audit_sections.dart';
import 'day_book_export_data.dart';
import 'day_book_financial_sections.dart';
import 'day_book_report_model.dart';
import 'day_book_source_sections.dart';
import 'day_book_stock_sections.dart';

class DayBookReportBuilder {
  const DayBookReportBuilder._();

  static List<DayBookReportSection> build(DayBookExportData data) {
    final financial = DayBookFinancialSections.build(data.summary);
    final stock = DayBookStockSections.build(data.summary);
    final sources = DayBookSourceSections.build(data.summary);
    final audit = DayBookAuditSections.build(data);
    if (financial.length == 1) {
      return [...financial, ...stock, ...sources, ...audit];
    }
    return [
      financial.first,
      stock.first,
      ...financial.skip(1).take(financial.length - 2),
      ...sources,
      ...stock.skip(1),
      ...audit,
      financial.last,
    ];
  }
}
