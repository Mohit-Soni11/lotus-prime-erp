import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../logic/finance/due_report/due_report_controller.dart';
import '../../../models/finance/due_report/due_report_model.dart';
import '../../../theme/finance/due_report/due_report_theme.dart';
import 'due_report_app_bar.dart';
import 'due_report_bill_panel.dart';
import 'due_report_customer_list.dart';
import 'due_report_filter_bar.dart';
import 'due_report_summary_panel.dart';

class DueReportScreen extends StatefulWidget {
  const DueReportScreen({super.key});

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
    Navigator.of(context).maybePop();
  }

  Future<void> _handlePrint() async {
    final groups = _ctrl.visibleGroups;
    if (groups.isEmpty) {
      _showNotice('No due report data to print.');
      return;
    }
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => [
          pw.Text(
            'LOTUS ERP - DUE REPORT',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Filter: ${_ctrl.filter.label}   Sort: ${_ctrl.sort.label}   Generated: ${DueReportController.formatDate(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Customer',
              'Mobile',
              'Bills',
              'Total Due',
              'Overdue',
              'Latest Bill',
            ],
            data: groups
                .map(
                  (group) => [
                    group.customerName,
                    group.mobile,
                    group.billCount.toString(),
                    DueReportController.formatAmount(group.totalDue),
                    DueReportController.formatAmount(group.overdueAmount),
                    DueReportController.formatDate(group.latestBillDate),
                  ],
                )
                .toList(),
            headerStyle:
                pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
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
    );
    if (path == null) return;
    final exportPath = path.toLowerCase().endsWith('.csv') ? path : '$path.csv';
    await File(exportPath).writeAsString(_buildDueReportCsv(groups));
    _showNotice('Due report exported.');
  }

  String _buildDueReportCsv(List<DueCustomerGroupModel> groups) {
    final rows = <List<String>>[
      [
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
    ];
    return rows.map((row) => row.map(_csvCell).join(',')).join('\r\n');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: const TextStyle(fontWeight: FontWeight.w700)),
        behavior: SnackBarBehavior.floating,
        width: 360,
        backgroundColor: DueReportColors.appBarBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
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
