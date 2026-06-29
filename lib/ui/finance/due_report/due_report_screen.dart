import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../logic/finance/due_report/due_report_controller.dart';
import '../../../models/finance/due_report/due_report_model.dart';
import '../../../theme/finance/due_report/due_report_theme.dart';
import '../due_collection_entry/due_collection_entry_screen.dart';
import 'due_report_app_bar.dart';
import 'due_report_bill_panel.dart';
import 'due_report_customer_list.dart';
import 'due_report_filter_bar.dart';
import 'due_report_summary_panel.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

class DueReportScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const DueReportScreen({super.key, this.onBack});

  @override
  State<DueReportScreen> createState() => _DueReportScreenState();
}

class _DueReportScreenState extends State<DueReportScreen> {
  late final DueReportController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = DueReportController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (!mounted) return;
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _openDueCollection(DueCustomerGroupModel group) {
    final firstBill = group.bills.isEmpty ? null : group.bills.first;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DueCollectionEntryScreen(
          initialCustomerId: group.customerId,
          initialCustomerName: group.customerName,
          initialMobile: group.mobile,
          initialBillNo: firstBill?.billNo,
        ),
      ),
    );
  }

  Future<void> _handlePrint() async {
    final groups = _ctrl.visibleGroups;
    if (groups.isEmpty) {
      _showNotice('No due report data to print.');
      return;
    }
    final stats = DueReportStatsModel.fromGroups(groups);
    final billRows = groups.expand((group) => group.bills).toList();
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(26),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (_) => [
          _pdfHeader('Due Report', 'Customer-wise outstanding bill register'),
          pw.SizedBox(height: 12),
          pw.Text(
            'Filter: ${_ctrl.filter.label}   Sort: ${_ctrl.sort.label}   Generated: ${DueReportController.formatDate(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 12),
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pdfMetric('Total Due',
                  DueReportController.formatAmount(stats.totalDue)),
              _pdfMetric('Overdue',
                  DueReportController.formatAmount(stats.overdueAmount)),
              _pdfMetric('Customers', stats.customerCount.toString()),
              _pdfMetric('Due Bills', stats.billCount.toString()),
              _pdfMetric(
                'Highest Customer Due',
                DueReportController.formatAmount(stats.highestCustomerDue),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          _pdfSectionTitle('Customer Summary'),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Customer',
              'Mobile',
              'City',
              'Bills',
              'Total Due',
              'Overdue',
              'Latest Bill',
              'Promise',
            ],
            data: groups
                .map(
                  (group) => [
                    group.customerName,
                    group.mobile,
                    group.city,
                    group.billCount.toString(),
                    DueReportController.formatAmount(group.totalDue),
                    DueReportController.formatAmount(group.overdueAmount),
                    DueReportController.formatDate(group.latestBillDate),
                    _formatOptionalDate(group.nearestPromiseDate),
                  ],
                )
                .toList(),
            headerStyle:
                pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 7.5),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF1EDE4),
            ),
          ),
          pw.SizedBox(height: 16),
          _pdfSectionTitle('Bill Detail'),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Customer',
              'Bill No',
              'Bill Date',
              'Bill Amount',
              'Paid',
              'Due',
              'Promise',
              'Status',
            ],
            data: billRows
                .map(
                  (bill) => [
                    bill.customerName,
                    bill.billNo,
                    DueReportController.formatDate(bill.billDate),
                    DueReportController.formatAmount(bill.finalAmount),
                    DueReportController.formatAmount(bill.paidAmount),
                    DueReportController.formatAmount(bill.dueAmount),
                    _formatOptionalDate(bill.promiseDate),
                    bill.statusLabel,
                  ],
                )
                .toList(),
            headerStyle:
                pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 7.2),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF1EDE4),
            ),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  Future<void> _handleExportCsv() async {
    final groups = _ctrl.visibleGroups;
    if (groups.isEmpty) {
      _showNotice('No due report data to export.');
      return;
    }
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Due Report',
      fileName: _datedFileName('due_report', 'csv'),
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      lockParentWindow: true,
    );
    if (path == null) return;
    final exportPath = path.toLowerCase().endsWith('.csv') ? path : '$path.csv';
    await File(exportPath).writeAsString(_buildDueReportCsv(groups));
    _showNotice('Due report exported.');
  }

  String _buildDueReportCsv(List<DueCustomerGroupModel> groups) {
    final stats = DueReportStatsModel.fromGroups(groups);
    final rows = <List<String>>[
      ['Section', 'Metric', 'Value'],
      ['Summary', 'Total Due', stats.totalDue.toStringAsFixed(2)],
      ['Summary', 'Overdue Due', stats.overdueAmount.toStringAsFixed(2)],
      ['Summary', 'Customers', stats.customerCount.toString()],
      ['Summary', 'Due Bills', stats.billCount.toString()],
      [
        'Summary',
        'Highest Customer Due',
        stats.highestCustomerDue.toStringAsFixed(2),
      ],
      [],
      [
        'Section',
        'Customer',
        'Mobile',
        'City',
        'Bills',
        'Total Due',
        'Overdue Due',
        'Latest Bill Date',
        'Nearest Promise',
      ],
      ...groups.map(
        (group) => [
          'Customer Summary',
          group.customerName,
          group.mobile,
          group.city,
          group.billCount.toString(),
          group.totalDue.toStringAsFixed(2),
          group.overdueAmount.toStringAsFixed(2),
          DueReportController.formatDate(group.latestBillDate),
          group.nearestPromiseDate == null
              ? ''
              : DueReportController.formatDate(group.nearestPromiseDate!),
        ],
      ),
      [],
      [
        'Section',
        'Customer',
        'Mobile',
        'Bill No',
        'Bill Date',
        'Bill Amount',
        'Paid Amount',
        'Due Amount',
        'Promise Date',
        'Status',
        'Billing Mode',
        'Bill Type',
      ],
      ...groups.expand(
        (group) => group.bills.map(
          (bill) => [
            'Bill Detail',
            bill.customerName,
            bill.mobile,
            bill.billNo,
            DueReportController.formatDate(bill.billDate),
            bill.finalAmount.toStringAsFixed(2),
            bill.paidAmount.toStringAsFixed(2),
            bill.dueAmount.toStringAsFixed(2),
            bill.promiseDate == null
                ? ''
                : DueReportController.formatDate(bill.promiseDate!),
            bill.statusLabel,
            bill.billingMode,
            bill.billType,
          ],
        ),
      ),
    ];
    return rows.map((row) => row.map(_csvCell).join(',')).join('\r\n');
  }

  String _formatOptionalDate(DateTime? date) {
    return date == null ? '-' : DueReportController.formatDate(date);
  }

  pw.Widget _pdfHeader(String title, String subtitle) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1F2937)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'LOTUS ERP',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey300,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                title.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                subtitle,
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: PdfColors.grey300,
                ),
              ),
            ],
          ),
          pw.Text(
            DueReportController.formatDate(DateTime.now()),
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfMetric(String label, String value) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFBF7ED),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE8D9A7)),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSectionTitle(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        value,
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _datedFileName(String prefix, String ext) {
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return '${prefix}_$stamp.$ext';
  }

  void _showNotice(String message) {
    if (!mounted) return;
    AppFeedback.show(
      context,
      type: AppFeedbackType.info,
      message: message,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          return Scaffold(
            backgroundColor: DueReportColors.bodyBg,
            appBar: DueReportAppBar(
              onBack: _handleBack,
              onRefresh: _ctrl.refresh,
              isLoading: _ctrl.isLoading,
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DueReportSummaryPanel(
                      stats: _ctrl.stats,
                      isLoading: _ctrl.isLoading,
                    ),
                    const SizedBox(height: 12),
                    DueReportFilterBar(
                      ctrl: _ctrl,
                      onPrint: _handlePrint,
                      onExport: _handleExportCsv,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final stacked = constraints.maxWidth < 1040;
                          if (stacked) {
                            return Column(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: DueReportCustomerList(ctrl: _ctrl),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  flex: 4,
                                  child: DueReportBillPanel(
                                    group: _ctrl.selectedGroup,
                                    onCollectDue: _openDueCollection,
                                  ),
                                ),
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 7,
                                child: DueReportCustomerList(ctrl: _ctrl),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 5,
                                child: DueReportBillPanel(
                                  group: _ctrl.selectedGroup,
                                  onCollectDue: _openDueCollection,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
