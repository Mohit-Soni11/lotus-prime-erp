import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../due_receipt_history/due_receipt_history_screen.dart';
import '../../../logic/finance/due_collection_entry/due_collection_entry_controller.dart';
import '../../../models/finance/due_collection_entry/due_collection_entry_model.dart';
import '../../../theme/finance/due_collection_entry/due_collection_entry_theme.dart';
import '../../shared/system_status_badge.dart';
import 'due_collection_app_bar.dart';
import 'due_collection_empty_state.dart';
import 'due_collection_summary.dart';

part 'due_collection_notice.dart';
part 'due_collection_customer_list.dart';
part 'due_collection_customer_detail.dart';
part 'due_collection_form.dart';
part 'due_collection_receipt_widgets.dart';
part 'due_collection_payment_fields.dart';
part 'due_collection_payment_setup.dart';
part 'due_collection_save_actions.dart';

enum _PremiumNoticeType { success, warning, error }

class DueCollectionEntryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final int? initialCustomerId;
  final String? initialCustomerName;
  final String? initialMobile;
  final String? initialBillNo;

  const DueCollectionEntryScreen({
    super.key,
    this.onBack,
    this.initialCustomerId,
    this.initialCustomerName,
    this.initialMobile,
    this.initialBillNo,
  });

  @override
  State<DueCollectionEntryScreen> createState() =>
      _DueCollectionEntryScreenState();
}

class _DueCollectionEntryScreenState extends State<DueCollectionEntryScreen> {
  late final DueCollectionEntryController _ctrl;
  OverlayEntry? _noticeEntry;
  Timer? _noticeTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = DueCollectionEntryController();
    _ctrl.openDueProfile(
      customerId: widget.initialCustomerId,
      customerName: widget.initialCustomerName,
      mobile: widget.initialMobile,
      billNo: widget.initialBillNo,
    );
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    _noticeEntry?.remove();
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

  Future<void> _handleSave({bool printReceipt = false}) async {
    final receiptBill = _ctrl.selectedBill;
    final result = await _ctrl.saveCollection();
    if (!mounted) return;
    if (!result.success && _ctrl.needsPaymentSetup) {
      final configured = await _showPaymentSetupDialog();
      if (configured && mounted) {
        await _handleSave(printReceipt: printReceipt);
      }
      return;
    }
    _showPremiumNotice(
      result.message,
      type: result.success
          ? _PremiumNoticeType.success
          : _PremiumNoticeType.error,
    );

    if (result.success && printReceipt && receiptBill != null) {
      await _printDueReceipt(receiptBill);
    }
  }

  Future<bool> _showPaymentSetupDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PaymentSetupDialog(ctrl: _ctrl),
    );
    return result == true;
  }

  void _showPremiumNotice(String message, {required _PremiumNoticeType type}) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    _dismissPremiumNotice();
    final entry = OverlayEntry(
      builder: (_) => _PremiumNoticeToast(
        message: message,
        type: type,
        onClose: _dismissPremiumNotice,
      ),
    );
    _noticeEntry = entry;
    overlay.insert(entry);
    _noticeTimer = Timer(
      const Duration(milliseconds: 3400),
      _dismissPremiumNotice,
    );
  }

  void _dismissPremiumNotice() {
    _noticeTimer?.cancel();
    _noticeTimer = null;
    _noticeEntry?.remove();
    _noticeEntry = null;
  }

  Future<void> _printDueReceipt(DueCollectionBillModel bill) async {
    final receiptNo = _ctrl.lastReceiptNo ?? 'DUE-RECEIPT';
    final received = _ctrl.lastCollectedAmount;
    final discount = _ctrl.lastDiscountAmount;
    final balance = _ctrl.lastBalanceDue;
    final mode = _ctrl.lastPaymentModeLabel ?? _ctrl.paymentMode.label;
    final promiseDate = _ctrl.lastPromiseDate;
    final receiptDate = DateTime.now();
    final status = balance <= 0.5 ? 'Due Cleared' : 'Partial Due';
    final pdf = pw.Document();

    String amount(double value) =>
        DueCollectionEntryController.formatAmount(value);
    String date(DateTime value) =>
        DueCollectionEntryController.formatDate(value);

    pw.Widget receiptMeta(String label, String value, {bool bold = false}) {
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      );
    }

    pw.Widget summaryLine(String label, String value,
        {bool total = false, PdfColor? color}) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: total ? 11 : 9,
                color: PdfColors.grey700,
                fontWeight: total ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: total ? 14 : 10,
                color: color ?? PdfColors.black,
                fontWeight: total ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget infoCell(String label, String value) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label.toUpperCase(),
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
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

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey500, width: 0.8),
          ),
          padding: const pw.EdgeInsets.all(18),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'LOTUS ERP',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Jewellery Billing & Accounts',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Customer payment receipt against an outstanding invoice.',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    width: 190,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey900,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        pw.Text(
                          'PAYMENT RECEIPT',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Due Collection | $receiptNo',
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(
                            color: PdfColors.amber200,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 18),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius:
                            pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'RECEIVED FROM',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            bill.customerName.trim().isEmpty
                                ? 'Walk-in Customer'
                                : bill.customerName,
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if (bill.mobile.trim().isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 3),
                              child: pw.Text(
                                'Mobile: ${bill.mobile}',
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                            ),
                          if (bill.city.trim().isNotEmpty ||
                              bill.address.trim().isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 3),
                              child: pw.Text(
                                [
                                  bill.address.trim(),
                                  bill.city.trim(),
                                ].where((part) => part.isNotEmpty).join(', '),
                                style: const pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      children: [
                        receiptMeta('Receipt Date', date(receiptDate),
                            bold: true),
                        pw.SizedBox(height: 7),
                        receiptMeta('Invoice No', bill.billNo, bold: true),
                        pw.SizedBox(height: 7),
                        receiptMeta('Bill Date', date(bill.billDate)),
                        pw.SizedBox(height: 7),
                        receiptMeta('Status', status, bold: true),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 18),
              pw.Table(
                border:
                    pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.1),
                  1: pw.FlexColumnWidth(1.2),
                  2: pw.FlexColumnWidth(1.4),
                  3: pw.FlexColumnWidth(1.4),
                  4: pw.FlexColumnWidth(1.4),
                  5: pw.FlexColumnWidth(1.4),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey900),
                    children: [
                      'Invoice',
                      'Bill Date',
                      'Bill Amount',
                      'Previous Due',
                      'Received',
                      'Balance',
                    ]
                        .map(
                          (text) => pw.Padding(
                            padding: const pw.EdgeInsets.all(7),
                            child: pw.Text(
                              text,
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  pw.TableRow(
                    children: [
                      bill.billNo,
                      date(bill.billDate),
                      amount(bill.finalAmount),
                      amount(bill.dueAmount),
                      amount(received),
                      amount(balance),
                    ]
                        .map(
                          (text) => pw.Padding(
                            padding: const pw.EdgeInsets.all(7),
                            child: pw.Text(text,
                                style: const pw.TextStyle(fontSize: 8.5)),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              pw.SizedBox(height: 18),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        infoCell('Payment Mode', mode.toUpperCase()),
                        pw.SizedBox(height: 8),
                        infoCell(
                          'Next Promise',
                          promiseDate != null && balance > 0.5
                              ? date(promiseDate)
                              : '-',
                        ),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.all(10),
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.grey100,
                            borderRadius: pw.BorderRadius.all(
                              pw.Radius.circular(5),
                            ),
                          ),
                          child: pw.Text(
                            'Narration: Received ${amount(received)} against invoice ${bill.billNo}${discount > 0.5 ? ' with ${amount(discount)} discount / waiver' : ''}.',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 18),
                  pw.Container(
                    width: 220,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border:
                          pw.Border.all(color: PdfColors.grey300, width: 0.7),
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Column(
                      children: [
                        summaryLine('Bill Amount', amount(bill.finalAmount)),
                        summaryLine('Previous Due', amount(bill.dueAmount)),
                        summaryLine('Received', amount(received),
                            color: PdfColors.green800),
                        if (discount > 0.5)
                          summaryLine('Discount / Waiver', amount(discount),
                              color: PdfColors.amber800),
                        summaryLine('Balance Due', amount(balance),
                            total: true,
                            color: balance <= 0.5
                                ? PdfColors.green800
                                : PdfColors.amber800),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      'This receipt is generated from Lotus ERP against the above invoice payment.',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 40),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 150,
                        height: 1,
                        color: PdfColors.grey500,
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Authorized Signature',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await Printing.layoutPdf(onLayout: (_) async => pdf.save());
    } catch (_) {
      if (!mounted) return;
      _showPremiumNotice(
        'Receipt saved, but print preview could not open.',
        type: _PremiumNoticeType.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          return Scaffold(
            backgroundColor: DueCollectionEntryColors.bodyBg,
            appBar: DueCollectionAppBar(
              onBack: _handleBack,
              status: _ctrl.isLoading
                  ? SystemStatus.loading
                  : _ctrl.isDataUnavailable
                      ? SystemStatus.unavailable
                      : SystemStatus.online,
              onReset: _ctrl.selectedCustomer != null || _ctrl.hasSearchQuery
                  ? _ctrl.resetEntry
                  : null,
            ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 980;
                  final empty = !_ctrl.isLoading &&
                      (_ctrl.isDataUnavailable || _ctrl.allBillCount == 0);
                  final summary = DueCollectionSummary(
                    stats: _ctrl.stats,
                    isLoading: _ctrl.isLoading,
                  );
                  final messages = <Widget>[
                    if (_ctrl.errorMessage != null && !_ctrl.isDataUnavailable)
                      _MessageBox(message: _ctrl.errorMessage!, isError: true),
                    if (_ctrl.successMessage != null)
                      _MessageBox(
                          message: _ctrl.successMessage!, isError: false),
                  ];
                  if (wide) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          summary,
                          for (final message in messages) ...[
                            const SizedBox(height: 12),
                            message,
                          ],
                          const SizedBox(height: 16),
                          if (empty || _ctrl.isLoading)
                            DueCollectionEmptyState(
                              isLoading: _ctrl.isLoading,
                              errorMessage: _ctrl.isDataUnavailable
                                  ? _ctrl.errorMessage
                                  : null,
                            )
                          else
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                      flex: 7,
                                      child:
                                          _BillList(ctrl: _ctrl, inset: false)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 4,
                                    child: _CollectionPanel(
                                      ctrl: _ctrl,
                                      inset: false,
                                      onSave: () => _handleSave(),
                                      onSaveAndPrint: () =>
                                          _handleSave(printReceipt: true),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        summary,
                        for (final message in messages) ...[
                          const SizedBox(height: 12),
                          message,
                        ],
                        const SizedBox(height: 14),
                        if (empty || _ctrl.isLoading)
                          DueCollectionEmptyState(
                            isLoading: _ctrl.isLoading,
                            errorMessage: _ctrl.isDataUnavailable
                                ? _ctrl.errorMessage
                                : null,
                          )
                        else ...[
                          SizedBox(
                              height: 520,
                              child: _BillList(ctrl: _ctrl, inset: false)),
                          const SizedBox(height: 14),
                          _CollectionPanel(
                            ctrl: _ctrl,
                            inset: false,
                            embedded: true,
                            onSave: () => _handleSave(),
                            onSaveAndPrint: () =>
                                _handleSave(printReceipt: true),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
