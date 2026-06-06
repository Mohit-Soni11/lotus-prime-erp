import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../due_receipt_history/due_receipt_history_screen.dart';
import '../../../logic/finance/due_collection_entry/due_collection_entry_controller.dart';
import '../../../models/finance/due_collection_entry/due_collection_entry_model.dart';
import '../../../theme/finance/due_collection_entry/due_collection_entry_theme.dart';

enum _PremiumNoticeType { success, warning, error }

class DueCollectionEntryScreen extends StatefulWidget {
  final int? initialCustomerId;
  final String? initialCustomerName;
  final String? initialMobile;
  final String? initialBillNo;

  const DueCollectionEntryScreen({
    super.key,
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
            appBar: _DueCollectionAppBar(
              onBack: _handleBack,
              onRefresh: _ctrl.refresh,
              onReset: _ctrl.resetEntry,
              isLoading: _ctrl.isLoading,
            ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 1180;
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: 330, child: _LeftPanel(ctrl: _ctrl)),
                        Container(
                            width: 1,
                            color: DueCollectionEntryColors.bodyBorder),
                        Expanded(child: _BillList(ctrl: _ctrl)),
                        Container(
                            width: 1,
                            color: DueCollectionEntryColors.bodyBorder),
                        SizedBox(
                            width: 430,
                            child: _CollectionPanel(
                                ctrl: _ctrl,
                                onSave: () => _handleSave(),
                                onSaveAndPrint: () =>
                                    _handleSave(printReceipt: true))),
                      ],
                    );
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LeftPanel(ctrl: _ctrl, embedded: true),
                        const SizedBox(height: 12),
                        SizedBox(height: 460, child: _BillList(ctrl: _ctrl)),
                        const SizedBox(height: 12),
                        _CollectionPanel(
                            ctrl: _ctrl,
                            onSave: () => _handleSave(),
                            onSaveAndPrint: () =>
                                _handleSave(printReceipt: true),
                            embedded: true),
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

class _PremiumNoticeToast extends StatelessWidget {
  final String message;
  final _PremiumNoticeType type;
  final VoidCallback onClose;

  const _PremiumNoticeToast({
    required this.message,
    required this.type,
    required this.onClose,
  });

  Color get _accent {
    return switch (type) {
      _PremiumNoticeType.success => DueCollectionEntryColors.brandGold,
      _PremiumNoticeType.warning => DueCollectionEntryColors.warning,
      _PremiumNoticeType.error => DueCollectionEntryColors.danger,
    };
  }

  Color get _surface {
    return switch (type) {
      _PremiumNoticeType.success => const Color(0xFFFFFCF2),
      _PremiumNoticeType.warning => DueCollectionEntryColors.warningBg,
      _PremiumNoticeType.error => DueCollectionEntryColors.dangerBg,
    };
  }

  IconData get _icon {
    return switch (type) {
      _PremiumNoticeType.success => DueCollectionEntryIcons.verified,
      _PremiumNoticeType.warning => DueCollectionEntryIcons.warning,
      _PremiumNoticeType.error => DueCollectionEntryIcons.warning,
    };
  }

  String get _title {
    return switch (type) {
      _PremiumNoticeType.success => 'Receipt Saved',
      _PremiumNoticeType.warning => 'Print Notice',
      _PremiumNoticeType.error => 'Action Needed',
    };
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    return Positioned(
      top: 86,
      right: 24,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(28 * (1 - value), -8 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 410,
            constraints: const BoxConstraints(maxWidth: 410),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: accent.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: DueCollectionEntryColors.bodyPanel,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: accent.withValues(alpha: 0.22)),
                        ),
                        child: Icon(_icon, color: accent, size: 19),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _title,
                              style: DueCollectionEntryStyles.rowTitle.copyWith(
                                color: DueCollectionEntryColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message,
                              style: DueCollectionEntryStyles.rowSub.copyWith(
                                color: DueCollectionEntryColors.textSecondary,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: onClose,
                        borderRadius: BorderRadius.circular(18),
                        child: const Padding(
                          padding: EdgeInsets.all(5),
                          child: Icon(
                            DueCollectionEntryIcons.clear,
                            size: 16,
                            color: DueCollectionEntryColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SizedBox(
                    height: 3,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1, end: 0),
                      duration: const Duration(milliseconds: 3300),
                      curve: Curves.linear,
                      builder: (context, value, _) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: value.clamp(0, 1),
                            child: Container(
                              color: accent.withValues(alpha: 0.86),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DueCollectionAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback onReset;
  final bool isLoading;

  const _DueCollectionAppBar(
      {required this.onBack,
      required this.onRefresh,
      required this.onReset,
      required this.isLoading});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<_DueCollectionAppBar> createState() => _DueCollectionAppBarState();
}

class _DueCollectionAppBarState extends State<_DueCollectionAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blinkCtrl;

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: DueCollectionEntryColors.shellPanel,
        border: Border(
            bottom: BorderSide(
                color: DueCollectionEntryColors.shellBorder, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _ShellIconButton(
                icon: DueCollectionEntryIcons.back,
                tooltip: 'Back',
                onTap: widget.onBack),
            const SizedBox(width: 16),
            Container(
                width: 1,
                height: 30,
                color: DueCollectionEntryColors.shellBorder),
            const SizedBox(width: 16),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: DueCollectionEntryColors.brandGoldLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: DueCollectionEntryColors.brandGold
                        .withValues(alpha: 0.3)),
              ),
              child: const Icon(DueCollectionEntryIcons.module,
                  color: DueCollectionEntryColors.brandGold, size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DueCollectionEntryStrings.title,
                      style: DueCollectionEntryStyles.appBarTitle),
                  SizedBox(height: 3),
                  Text(DueCollectionEntryStrings.subtitle,
                      style: DueCollectionEntryStyles.appBarSub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: _blinkCtrl,
              builder: (_, __) => Opacity(
                opacity: 0.35 + (_blinkCtrl.value * 0.65),
                child: const Row(
                  children: [
                    _LiveDot(),
                    SizedBox(width: 6),
                    Text(DueCollectionEntryStrings.live,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: DueCollectionEntryColors.success,
                            letterSpacing: 1.2)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 18),
            _ShellIconButton(
                icon: widget.isLoading
                    ? Icons.hourglass_top_rounded
                    : DueCollectionEntryIcons.refresh,
                tooltip: DueCollectionEntryStrings.refresh,
                onTap: widget.isLoading ? null : widget.onRefresh),
            const SizedBox(width: 8),
            _ShellIconButton(
                icon: DueCollectionEntryIcons.reset,
                tooltip: DueCollectionEntryStrings.reset,
                onTap: widget.onReset),
          ],
        ),
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
            color: DueCollectionEntryColors.success, shape: BoxShape.circle));
  }
}

class _ShellIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _ShellIconButton(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  State<_ShellIconButton> createState() => _ShellIconButtonState();
}

class _ShellIconButtonState extends State<_ShellIconButton> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (!mounted || _hovered == value) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered && !disabled
                  ? DueCollectionEntryColors.brandGoldLight
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _hovered && !disabled
                      ? DueCollectionEntryColors.brandGold
                          .withValues(alpha: 0.4)
                      : DueCollectionEntryColors.shellBorder),
            ),
            child: Icon(widget.icon,
                size: 16,
                color: disabled
                    ? DueCollectionEntryColors.shellBorder
                    : _hovered
                        ? DueCollectionEntryColors.brandGold
                        : DueCollectionEntryColors.shellMuted),
          ),
        ),
      ),
    );
  }
}

class _LeftPanel extends StatelessWidget {
  final DueCollectionEntryController ctrl;
  final bool embedded;

  const _LeftPanel({required this.ctrl, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final child = SingleChildScrollView(
      padding: EdgeInsets.all(embedded ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryCard(
            icon: DueCollectionEntryIcons.amount,
            label: 'Total Due',
            value:
                DueCollectionEntryController.formatCompact(ctrl.stats.totalDue),
            color: DueCollectionEntryColors.warning,
            bg: DueCollectionEntryColors.warningBg,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _MiniSummary(
                      label: 'Bills',
                      value: ctrl.stats.billCount.toString(),
                      icon: DueCollectionEntryIcons.bill)),
              const SizedBox(width: 10),
              Expanded(
                  child: _MiniSummary(
                      label: 'Customers',
                      value: ctrl.stats.customerCount.toString(),
                      icon: DueCollectionEntryIcons.customer)),
            ],
          ),
          const SizedBox(height: 10),
          _SummaryCard(
            icon: DueCollectionEntryIcons.warning,
            label: 'Overdue Due',
            value: DueCollectionEntryController.formatCompact(
                ctrl.stats.overdueDue),
            color: DueCollectionEntryColors.danger,
            bg: DueCollectionEntryColors.dangerBg,
          ),
          if (ctrl.errorMessage != null) ...[
            const SizedBox(height: 12),
            _MessageBox(message: ctrl.errorMessage!, isError: true),
          ],
          if (ctrl.successMessage != null) ...[
            const SizedBox(height: 12),
            _MessageBox(message: ctrl.successMessage!, isError: false),
          ],
        ],
      ),
    );
    if (embedded) return child;
    return Container(color: DueCollectionEntryColors.bodyBg, child: child);
  }
}

class _SearchBox extends StatelessWidget {
  final DueCollectionEntryController ctrl;

  const _SearchBox({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: DueCollectionEntryStyles.flatPanel(
          color: DueCollectionEntryColors.bodyPanel),
      child: TextField(
        controller: ctrl.searchCtrl,
        style: DueCollectionEntryStyles.rowTitle,
        decoration: InputDecoration(
          prefixIcon: const Icon(DueCollectionEntryIcons.search,
              size: 18, color: DueCollectionEntryColors.textMuted),
          suffixIcon: ctrl.searchQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  onPressed: ctrl.clearSearch,
                  icon: const Icon(DueCollectionEntryIcons.clear, size: 17)),
          hintText: DueCollectionEntryStrings.searchHint,
          hintStyle: DueCollectionEntryStyles.muted,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bg;

  const _SummaryCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color,
      required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: DueCollectionEntryStyles.panel(),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: color.withValues(alpha: 0.18))),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: DueCollectionEntryStyles.label, maxLines: 1),
                const SizedBox(height: 4),
                Text(value,
                    style: DueCollectionEntryStyles.amount
                        .copyWith(color: color, fontSize: 18),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSummary extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniSummary(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: DueCollectionEntryStyles.flatPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: DueCollectionEntryColors.brandGold),
          const SizedBox(height: 8),
          Text(value,
              style: DueCollectionEntryStyles.amount.copyWith(fontSize: 18)),
          const SizedBox(height: 2),
          Text(label, style: DueCollectionEntryStyles.rowSub),
        ],
      ),
    );
  }
}

class _TinyLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TinyLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: DueCollectionEntryColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style: DueCollectionEntryStyles.rowSub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _MessageBox extends StatelessWidget {
  final String message;
  final bool isError;

  const _MessageBox({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? DueCollectionEntryColors.danger
        : DueCollectionEntryColors.brandGold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isError
            ? DueCollectionEntryColors.dangerBg
            : DueCollectionEntryColors.brandGoldLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(message,
          style: DueCollectionEntryStyles.label.copyWith(color: color)),
    );
  }
}

class _MoneyLine extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MoneyLine(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: DueCollectionEntryStyles.label)),
        Text(DueCollectionEntryController.formatAmount(value),
            style: DueCollectionEntryStyles.rowTitle
                .copyWith(color: color, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _BillList extends StatelessWidget {
  final DueCollectionEntryController ctrl;

  const _BillList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Container(
        decoration: DueCollectionEntryStyles.panel(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  const Icon(DueCollectionEntryIcons.customer,
                      color: DueCollectionEntryColors.brandGold, size: 17),
                  const SizedBox(width: 8),
                  const Expanded(
                      child: Text('Customer Due Desk',
                          style: DueCollectionEntryStyles.sectionTitle)),
                  _CountBadge(
                      count: ctrl.customers.length,
                      total: ctrl.stats.customerCount),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: _SearchBox(ctrl: ctrl),
            ),
            Expanded(
              child: ctrl.selectedCustomer != null
                  ? _CustomerDueDetail(ctrl: ctrl)
                  : ctrl.customers.isEmpty
                      ? const _EmptyBills()
                      : _CustomerResultsList(ctrl: ctrl),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final int total;

  const _CountBadge({required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final label = count == total ? '$total customers' : '$count found';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: DueCollectionEntryColors.brandGoldLight,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
            color: DueCollectionEntryColors.brandGold.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: DueCollectionEntryStyles.label
              .copyWith(color: DueCollectionEntryColors.brandGold)),
    );
  }
}

class _CustomerResultsList extends StatelessWidget {
  final DueCollectionEntryController ctrl;

  const _CustomerResultsList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DueCollectionEntryColors.panelSoft,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        itemCount: ctrl.customers.length,
        itemBuilder: (context, index) {
          final customer = ctrl.customers[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CustomerResultCard(
              customer: customer,
              selected: ctrl.selectedCustomer?.key == customer.key,
              onTap: () => ctrl.selectCustomer(customer),
            ),
          );
        },
      ),
    );
  }
}

class _CustomerResultCard extends StatelessWidget {
  final DueCollectionCustomerModel customer;
  final bool selected;
  final VoidCallback onTap;

  const _CustomerResultCard({
    required this.customer,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? DueCollectionEntryColors.brandGold
        : DueCollectionEntryColors.bodyBorder;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? DueCollectionEntryColors.rowSelected
              : DueCollectionEntryColors.bodyPanel,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: DueCollectionEntryColors.infoBg,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                    color:
                        DueCollectionEntryColors.info.withValues(alpha: 0.18)),
              ),
              child: const Icon(DueCollectionEntryIcons.customer,
                  color: DueCollectionEntryColors.info, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name,
                      style: DueCollectionEntryStyles.rowTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(customer.mobile,
                      style: DueCollectionEntryStyles.rowSub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _MiniTag(customer.billCount == 1
                          ? '1 bill'
                          : '${customer.billCount} bills'),
                      if (customer.hasOverdue) ...[
                        const SizedBox(width: 6),
                        _MiniTag(
                          '${DueCollectionEntryController.formatCompact(customer.overdueDue)} overdue',
                          color: DueCollectionEntryColors.danger,
                        ),
                      ],
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          DueCollectionEntryController.formatCompact(
                              customer.totalDue),
                          textAlign: TextAlign.right,
                          style: DueCollectionEntryStyles.rowTitle.copyWith(
                              color: DueCollectionEntryColors.warning),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniTag(this.text, {this.color = DueCollectionEntryColors.brandGold});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(text,
          style: DueCollectionEntryStyles.rowSub.copyWith(color: color)),
    );
  }
}

class _CustomerDueDetail extends StatelessWidget {
  final DueCollectionEntryController ctrl;

  const _CustomerDueDetail({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final customer = ctrl.selectedCustomer;
    if (customer == null) return const _NoCustomerSelected();
    return Column(
      children: [
        _CustomerProfileBanner(
            customer: customer, onBack: ctrl.clearCustomerSelection),
        const _CustomerDueBillHeader(),
        Expanded(
          child: ListView.builder(
            itemCount: customer.bills.length,
            itemBuilder: (context, index) {
              final bill = customer.bills[index];
              return _CustomerDueBillRow(
                bill: bill,
                selected: ctrl.selectedBill?.id == bill.id,
                alternate: index.isOdd,
                onTap: () => ctrl.selectBill(bill),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CustomerProfileBanner extends StatelessWidget {
  final DueCollectionCustomerModel customer;
  final VoidCallback onBack;

  const _CustomerProfileBanner({required this.customer, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: DueCollectionEntryColors.bodyPanel,
        border: Border(
          bottom: BorderSide(color: DueCollectionEntryColors.bodyBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: DueCollectionEntryColors.panelSoft,
                    borderRadius: BorderRadius.circular(9),
                    border:
                        Border.all(color: DueCollectionEntryColors.bodyBorder),
                  ),
                  child: const Icon(DueCollectionEntryIcons.back,
                      size: 17, color: DueCollectionEntryColors.textPrimary),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DueCollectionEntryColors.infoBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: DueCollectionEntryColors.info
                          .withValues(alpha: 0.18)),
                ),
                child: const Icon(DueCollectionEntryIcons.customer,
                    color: DueCollectionEntryColors.info, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name,
                        style: DueCollectionEntryStyles.sectionTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    Text(
                      '${customer.mobile}  |  ${customer.address}',
                      style: DueCollectionEntryStyles.rowSub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (customer.hasOverdue)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: DueCollectionEntryColors.dangerBg,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: DueCollectionEntryColors.danger
                            .withValues(alpha: 0.22)),
                  ),
                  child: Text('${customer.overdueCount} overdue',
                      style: DueCollectionEntryStyles.label.copyWith(
                          color: DueCollectionEntryColors.danger,
                          fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _CustomerMetricPill(
                  label: 'Total Due',
                  value: DueCollectionEntryController.formatAmount(
                      customer.totalDue),
                  color: DueCollectionEntryColors.warning,
                  strong: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CustomerMetricPill(
                  label: 'Due Bills',
                  value: customer.billCount.toString(),
                  color: DueCollectionEntryColors.info,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CustomerMetricPill(
                  label: 'Overdue Due',
                  value: DueCollectionEntryController.formatCompact(
                      customer.overdueDue),
                  color: DueCollectionEntryColors.danger,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CustomerMetricPill(
                  label: 'Paid So Far',
                  value: DueCollectionEntryController.formatCompact(
                      customer.totalPaid),
                  color: DueCollectionEntryColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerMetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool strong;

  const _CustomerMetricPill({
    required this.label,
    required this.value,
    required this.color,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: strong ? 64 : 58,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: DueCollectionEntryStyles.rowSub.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(value,
              style: DueCollectionEntryStyles.rowTitle
                  .copyWith(color: color, fontSize: strong ? 16 : 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _CustomerDueBillHeader extends StatelessWidget {
  const _CustomerDueBillHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: DueCollectionEntryColors.tableHeader,
      child: const Row(
        children: [
          Expanded(flex: 3, child: _HeaderText('Invoice')),
          Expanded(flex: 2, child: _HeaderText('Bill Date', center: true)),
          Expanded(flex: 2, child: _HeaderText('Bill', center: true)),
          Expanded(flex: 2, child: _HeaderText('Paid', center: true)),
          Expanded(flex: 2, child: _HeaderText('Due', center: true)),
          Expanded(flex: 2, child: _HeaderText('Promise', center: true)),
          Expanded(flex: 2, child: _HeaderText('Status', center: true)),
          SizedBox(width: 28),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  final bool center;

  const _HeaderText(this.text, {this.center = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: DueCollectionEntryStyles.label
          .copyWith(color: DueCollectionEntryColors.textPrimary, fontSize: 11),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _CustomerDueBillRow extends StatefulWidget {
  final DueCollectionBillModel bill;
  final bool selected;
  final bool alternate;
  final VoidCallback onTap;

  const _CustomerDueBillRow({
    required this.bill,
    required this.selected,
    required this.alternate,
    required this.onTap,
  });

  @override
  State<_CustomerDueBillRow> createState() => _CustomerDueBillRowState();
}

class _CustomerDueBillRowState extends State<_CustomerDueBillRow> {
  bool _hover = false;

  void _setHover(bool value) {
    if (!mounted || _hover == value) return;
    setState(() => _hover = value);
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    final bg = widget.selected
        ? DueCollectionEntryColors.rowSelected
        : _hover
            ? DueCollectionEntryColors.rowHover
            : widget.alternate
                ? DueCollectionEntryColors.rowAlt
                : DueCollectionEntryColors.bodyPanel;

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          height: 64,
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(flex: 3, child: _InvoiceCell(bill: bill)),
              Expanded(
                  flex: 2,
                  child: _CenterText(
                      DueCollectionEntryController.formatShortDate(
                          bill.billDate))),
              Expanded(
                  flex: 2,
                  child: _CenterText(DueCollectionEntryController.formatCompact(
                      bill.finalAmount))),
              Expanded(
                  flex: 2,
                  child: _CenterText(DueCollectionEntryController.formatCompact(
                      bill.paidAmount))),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    DueCollectionEntryController.formatCompact(bill.dueAmount),
                    style: DueCollectionEntryStyles.rowTitle
                        .copyWith(color: DueCollectionEntryColors.warning),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Expanded(flex: 2, child: _PromiseCell(bill: bill)),
              Expanded(flex: 2, child: Center(child: _StatusBadge(bill: bill))),
              const SizedBox(
                  width: 28,
                  child: Icon(DueCollectionEntryIcons.arrow,
                      size: 18, color: DueCollectionEntryColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceCell extends StatelessWidget {
  final DueCollectionBillModel bill;

  const _InvoiceCell({required this.bill});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(bill.billNo,
            style: DueCollectionEntryStyles.rowTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 3),
        Text('${bill.billingMode} - ${bill.billType}',
            style: DueCollectionEntryStyles.rowSub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _CenterText extends StatelessWidget {
  final String text;

  const _CenterText(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text(text,
            style: DueCollectionEntryStyles.rowSub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis));
  }
}

class _PromiseCell extends StatelessWidget {
  final DueCollectionBillModel bill;

  const _PromiseCell({required this.bill});

  @override
  Widget build(BuildContext context) {
    final color = bill.isOverdue
        ? DueCollectionEntryColors.danger
        : bill.isDueToday
            ? DueCollectionEntryColors.warning
            : DueCollectionEntryColors.textMuted;
    return Center(
      child: Text(
        DueCollectionEntryController.formatShortDate(bill.promiseDate),
        style: DueCollectionEntryStyles.rowSub
            .copyWith(color: color, fontWeight: FontWeight.w700),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final DueCollectionBillModel bill;

  const _StatusBadge({required this.bill});

  @override
  Widget build(BuildContext context) {
    final color = bill.isOverdue
        ? DueCollectionEntryColors.danger
        : bill.isDueToday
            ? DueCollectionEntryColors.warning
            : DueCollectionEntryColors.info;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        bill.isOverdue ? 'OVERDUE' : bill.statusLabel,
        style:
            DueCollectionEntryStyles.label.copyWith(color: color, fontSize: 11),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _NoCustomerSelected extends StatelessWidget {
  const _NoCustomerSelected();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(DueCollectionEntryIcons.customer,
              size: 48, color: DueCollectionEntryColors.textMuted),
          SizedBox(height: 12),
          Text('Select customer', style: DueCollectionEntryStyles.sectionTitle),
          SizedBox(height: 5),
          Text('Customer due bills will appear here.',
              style: DueCollectionEntryStyles.muted),
        ],
      ),
    );
  }
}

class _EmptyBills extends StatelessWidget {
  const _EmptyBills();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(DueCollectionEntryIcons.empty,
              size: 48, color: DueCollectionEntryColors.textMuted),
          SizedBox(height: 12),
          Text(DueCollectionEntryStrings.noBillTitle,
              style: DueCollectionEntryStyles.sectionTitle),
          SizedBox(height: 5),
          Text(DueCollectionEntryStrings.noBillSub,
              style: DueCollectionEntryStyles.muted),
        ],
      ),
    );
  }
}

class _CollectionPanel extends StatelessWidget {
  final DueCollectionEntryController ctrl;
  final VoidCallback onSave;
  final VoidCallback onSaveAndPrint;
  final bool embedded;

  const _CollectionPanel({
    required this.ctrl,
    required this.onSave,
    required this.onSaveAndPrint,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final bill = ctrl.selectedBill;
    final content = Container(
      margin: EdgeInsets.all(embedded ? 0 : 14),
      decoration: DueCollectionEntryStyles.panel(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: DueCollectionEntryColors.tableHeader,
            child: const Row(
              children: [
                Icon(DueCollectionEntryIcons.amount,
                    size: 19, color: DueCollectionEntryColors.brandGold),
                SizedBox(width: 8),
                Text(DueCollectionEntryStrings.collectionForm,
                    style: DueCollectionEntryStyles.sectionTitle),
              ],
            ),
          ),
          Expanded(
            child: bill == null
                ? const SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: _NoSelectedBill(),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: _CollectionForm(ctrl: ctrl, bill: bill),
                        ),
                      ),
                      _StickySaveFooter(
                        ctrl: ctrl,
                        onSave: onSave,
                        onSaveAndPrint: onSaveAndPrint,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
    if (embedded) return SizedBox(height: 760, child: content);
    return content;
  }
}

class _NoSelectedBill extends StatelessWidget {
  const _NoSelectedBill();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Icon(DueCollectionEntryIcons.receipt,
                size: 46, color: DueCollectionEntryColors.textMuted),
            SizedBox(height: 12),
            Text('Select bill', style: DueCollectionEntryStyles.sectionTitle),
            SizedBox(height: 5),
            Text('Collection form will appear here.',
                style: DueCollectionEntryStyles.muted),
          ],
        ),
      ),
    );
  }
}

class _CollectionForm extends StatelessWidget {
  final DueCollectionEntryController ctrl;
  final DueCollectionBillModel bill;
  const _CollectionForm({required this.ctrl, required this.bill});

  @override
  Widget build(BuildContext context) {
    final settlementValidation = ctrl.settlementValidationMessage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BillSummaryBox(bill: bill),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final stackFields = constraints.maxWidth < 520;
            final amountInput = _AmountInput(
              label: 'Collection Amount',
              controller: ctrl.amountCtrl,
              icon: DueCollectionEntryIcons.amount,
              autofocusColor: DueCollectionEntryColors.brandGold,
              textStyle: DueCollectionEntryStyles.amount.copyWith(fontSize: 20),
            );
            final discountInput = _AmountInput(
              label: 'Discount / Waiver',
              controller: ctrl.discountCtrl,
              icon: DueCollectionEntryIcons.discount,
              autofocusColor: DueCollectionEntryColors.warning,
              textStyle: DueCollectionEntryStyles.amount.copyWith(
                  fontSize: 18, color: DueCollectionEntryColors.warning),
            );
            if (stackFields) {
              return Column(
                children: [
                  amountInput,
                  const SizedBox(height: 10),
                  discountInput,
                ],
              );
            }
            return Row(
              children: [
                Expanded(flex: 6, child: amountInput),
                const SizedBox(width: 10),
                Expanded(flex: 5, child: discountInput),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _QuickAmountButton(
                    label: DueCollectionEntryStrings.fullDue,
                    onTap: ctrl.setFullDueAmount)),
            const SizedBox(width: 10),
            Expanded(
                child: _QuickAmountButton(
                    label: DueCollectionEntryStrings.halfDue,
                    onTap: ctrl.setHalfDueAmount)),
            const SizedBox(width: 10),
            Expanded(
                child: _QuickAmountButton(
                    label: 'Clear Disc.', onTap: ctrl.clearDiscount)),
          ],
        ),
        if (settlementValidation != null) ...[
          const SizedBox(height: 10),
          _MessageBox(message: settlementValidation, isError: true),
        ],
        const SizedBox(height: 16),
        const Text('Payment Mode', style: DueCollectionEntryStyles.label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: DueCollectionPaymentMode.values
              .map((mode) => _ModeChip(
                  mode: mode,
                  selected: ctrl.paymentMode == mode,
                  onTap: () => ctrl.setPaymentMode(mode)))
              .toList(),
        ),
        if (ctrl.requiresBankAccount) ...[
          const SizedBox(height: 14),
          const Text('Bank Account', style: DueCollectionEntryStyles.label),
          const SizedBox(height: 7),
          _BankAccountDropdown(ctrl: ctrl),
          if (ctrl.needsUpiSetup) ...[
            const SizedBox(height: 8),
            const _MessageBox(
              message:
                  'Selected account has no UPI ID. Click Save to set UPI details first.',
              isError: true,
            ),
          ],
        ],
        const SizedBox(height: 14),
        _PromiseDateField(ctrl: ctrl),
        const SizedBox(height: 14),
        const Text('Notes', style: DueCollectionEntryStyles.label),
        const SizedBox(height: 7),
        TextField(
          controller: ctrl.notesCtrl,
          minLines: 3,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Optional narration',
            hintStyle: DueCollectionEntryStyles.muted,
            filled: true,
            fillColor: DueCollectionEntryColors.panelSoft,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: DueCollectionEntryColors.bodyBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: DueCollectionEntryColors.brandGold, width: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SettlementPreview(ctrl: ctrl, bill: bill),
        if (ctrl.needsPromiseDate && ctrl.promiseDate == null) ...[
          const SizedBox(height: 10),
          const _MessageBox(
              message: 'Select next promise date for remaining due.',
              isError: true),
        ],
        if (ctrl.lastReceiptNo != null) ...[
          const SizedBox(height: 12),
          _ReceiptReadyBox(
            receiptNo: ctrl.lastReceiptNo!,
            billNo: bill.billNo,
            amount: ctrl.lastCollectedAmount,
            discount: ctrl.lastDiscountAmount,
            balance: ctrl.lastBalanceDue,
            mode: ctrl.lastPaymentModeLabel ?? ctrl.paymentMode.label,
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

class _AmountInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final Color autofocusColor;
  final TextStyle textStyle;

  const _AmountInput({
    required this.label,
    required this.controller,
    required this.icon,
    required this.autofocusColor,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: DueCollectionEntryStyles.label),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.right,
          style: textStyle,
          decoration: InputDecoration(
            isDense: false,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 17),
            prefixIcon: Icon(icon, color: autofocusColor),
            hintText: '0.00',
            filled: true,
            fillColor: DueCollectionEntryColors.panelSoft,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: DueCollectionEntryColors.bodyBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: autofocusColor, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromiseDateField extends StatelessWidget {
  final DueCollectionEntryController ctrl;

  const _PromiseDateField({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final required = ctrl.needsPromiseDate;
    final selected = ctrl.promiseDate;
    final color = required && selected == null
        ? DueCollectionEntryColors.warning
        : DueCollectionEntryColors.brandGold;
    final bg = required
        ? DueCollectionEntryColors.warningBg
        : DueCollectionEntryColors.panelSoft;
    final label = required ? 'Next Promise Date Required' : 'Next Promise Date';
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 140),
      opacity: required || selected != null ? 1 : 0.72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: DueCollectionEntryStyles.label.copyWith(color: color)),
              const Spacer(),
              if (required || selected != null) ...[
                _TinyPromiseButton(
                    label: '7D', onTap: () => ctrl.setQuickPromiseDays(7)),
                const SizedBox(width: 6),
                _TinyPromiseButton(
                    label: '15D', onTap: () => ctrl.setQuickPromiseDays(15)),
                const SizedBox(width: 6),
                _TinyPromiseButton(
                    label: '30D', onTap: () => ctrl.setQuickPromiseDays(30)),
              ],
            ],
          ),
          const SizedBox(height: 7),
          InkWell(
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: selected ?? now.add(const Duration(days: 7)),
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 5),
              );
              if (picked != null) ctrl.setPromiseDate(picked);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: DueCollectionEntryStyles.flatPanel(color: bg),
              child: Row(
                children: [
                  Icon(DueCollectionEntryIcons.calendar,
                      size: 18, color: color),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      selected == null
                          ? (required
                              ? 'Set follow-up for remaining balance'
                              : 'Optional for partial follow-up')
                          : DueCollectionEntryController.formatDate(selected),
                      style: DueCollectionEntryStyles.rowTitle.copyWith(
                          color: selected == null
                              ? DueCollectionEntryColors.textMuted
                              : DueCollectionEntryColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (selected != null)
                    IconButton(
                      tooltip: 'Clear',
                      onPressed: () => ctrl.setPromiseDate(null),
                      icon: const Icon(DueCollectionEntryIcons.clear, size: 17),
                      color: DueCollectionEntryColors.textMuted,
                    )
                  else
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: DueCollectionEntryColors.textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyPromiseButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TinyPromiseButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: DueCollectionEntryColors.bodyPanel,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: DueCollectionEntryColors.bodyBorder),
        ),
        child: Text(label, style: DueCollectionEntryStyles.rowSub),
      ),
    );
  }
}

class _BillSummaryBox extends StatelessWidget {
  final DueCollectionBillModel bill;

  const _BillSummaryBox({required this.bill});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: DueCollectionEntryStyles.flatPanel(
          color: DueCollectionEntryColors.panelSoft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DueCollectionEntryColors.brandGoldLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: DueCollectionEntryColors.brandGold
                      .withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: DueCollectionEntryColors.bodyPanel,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: DueCollectionEntryColors.brandGold
                            .withValues(alpha: 0.24)),
                  ),
                  child: const Icon(DueCollectionEntryIcons.bill,
                      color: DueCollectionEntryColors.brandGold, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(DueCollectionEntryStrings.selectedBill,
                          style: DueCollectionEntryStyles.label),
                      const SizedBox(height: 3),
                      Text(bill.billNo,
                          style: DueCollectionEntryStyles.sectionTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                _StatusBadge(bill: bill),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: DueCollectionEntryStyles.flatPanel(),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: DueCollectionEntryColors.infoBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: DueCollectionEntryColors.info
                            .withValues(alpha: 0.18)),
                  ),
                  child: const Icon(DueCollectionEntryIcons.customer,
                      color: DueCollectionEntryColors.info, size: 21),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bill.customerName,
                          style: DueCollectionEntryStyles.rowTitle
                              .copyWith(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 5),
                      _TinyLine(
                          icon: DueCollectionEntryIcons.phone,
                          text:
                              '${bill.mobile}  |  ${DueCollectionEntryController.formatDate(bill.billDate)}'),
                      if (bill.address.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        _TinyLine(
                            icon: DueCollectionEntryIcons.location,
                            text: bill.address),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _AmountChip(
                  label: 'Bill',
                  value: bill.finalAmount,
                  color: DueCollectionEntryColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AmountChip(
                  label: 'Paid',
                  value: bill.paidAmount,
                  color: DueCollectionEntryColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AmountChip(
                  label: 'Due',
                  value: bill.dueAmount,
                  color: DueCollectionEntryColors.warning,
                  emphasis: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool emphasis;

  const _AmountChip({
    required this.label,
    required this.value,
    required this.color,
    this.emphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: emphasis
            ? DueCollectionEntryColors.warningBg
            : DueCollectionEntryColors.bodyPanel,
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: color.withValues(alpha: emphasis ? 0.24 : 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: DueCollectionEntryStyles.rowSub.copyWith(color: color)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              DueCollectionEntryController.formatAmount(value),
              style: DueCollectionEntryStyles.rowTitle
                  .copyWith(color: color, fontSize: emphasis ? 14 : 13),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptReadyBox extends StatelessWidget {
  final String receiptNo;
  final String billNo;
  final double amount;
  final double discount;
  final double balance;
  final String mode;

  const _ReceiptReadyBox({
    required this.receiptNo,
    required this.billNo,
    required this.amount,
    required this.discount,
    required this.balance,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DueCollectionEntryColors.successBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: DueCollectionEntryColors.success.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DueCollectionEntryColors.bodyPanel,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                      color: DueCollectionEntryColors.success
                          .withValues(alpha: 0.2)),
                ),
                child: const Icon(DueCollectionEntryIcons.verified,
                    color: DueCollectionEntryColors.success, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(DueCollectionEntryStrings.receiptReady,
                        style: DueCollectionEntryStyles.label),
                    const SizedBox(height: 3),
                    Text(receiptNo,
                        style: DueCollectionEntryStyles.rowTitle
                            .copyWith(color: DueCollectionEntryColors.success),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              _ReceiptHistoryButton(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DueReceiptHistoryScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ReceiptMetaLine(
                  label: 'Collected',
                  value: DueCollectionEntryController.formatAmount(amount),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ReceiptMetaLine(
                  label: 'Balance',
                  value: DueCollectionEntryController.formatAmount(balance),
                ),
              ),
            ],
          ),
          if (discount > 0.5) ...[
            const SizedBox(height: 8),
            _ReceiptMetaLine(
              label: 'Discount Applied',
              value: DueCollectionEntryController.formatAmount(discount),
              compact: false,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ReceiptMetaLine(
                  label: 'Mode',
                  value: mode.toUpperCase(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ReceiptMetaLine(
                  label: DueCollectionEntryStrings.savedInHistory,
                  value: billNo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiptHistoryButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ReceiptHistoryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: DueCollectionEntryColors.bodyPanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: DueCollectionEntryColors.success.withValues(alpha: 0.2)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(DueCollectionEntryIcons.history,
                size: 15, color: DueCollectionEntryColors.success),
            SizedBox(width: 5),
            Text(DueCollectionEntryStrings.viewHistory,
                style: TextStyle(
                    color: DueCollectionEntryColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0)),
          ],
        ),
      ),
    );
  }
}

class _ReceiptMetaLine extends StatelessWidget {
  final String label;
  final String value;
  final bool compact;

  const _ReceiptMetaLine({
    required this.label,
    required this.value,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: DueCollectionEntryColors.bodyPanel.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: DueCollectionEntryColors.success.withValues(alpha: 0.14)),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: DueCollectionEntryStyles.rowSub),
                const SizedBox(height: 3),
                Text(value,
                    style: DueCollectionEntryStyles.rowTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            )
          : Row(
              children: [
                Expanded(
                    child: Text(label, style: DueCollectionEntryStyles.rowSub)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(value,
                      style: DueCollectionEntryStyles.rowTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
    );
  }
}

class _QuickAmountButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAmountButton({required this.label, required this.onTap});

  @override
  State<_QuickAmountButton> createState() => _QuickAmountButtonState();
}

class _QuickAmountButtonState extends State<_QuickAmountButton> {
  bool _hover = false;

  void _setHover(bool value) {
    if (!mounted || _hover == value) return;
    setState(() => _hover = value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hover
                ? DueCollectionEntryColors.brandGoldLight
                : DueCollectionEntryColors.bodyPanel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: _hover
                    ? DueCollectionEntryColors.brandGold
                    : DueCollectionEntryColors.bodyBorder),
          ),
          child: Text(widget.label,
              style: DueCollectionEntryStyles.label
                  .copyWith(color: DueCollectionEntryColors.textPrimary)),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final DueCollectionPaymentMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip(
      {required this.mode, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? DueCollectionEntryColors.brandGoldLight
              : DueCollectionEntryColors.bodyPanel,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: selected
                  ? DueCollectionEntryColors.brandGold
                  : DueCollectionEntryColors.bodyBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_modeIcon(mode),
                size: 16,
                color: selected
                    ? DueCollectionEntryColors.brandGold
                    : DueCollectionEntryColors.textMuted),
            const SizedBox(width: 6),
            Text(mode.label,
                style: DueCollectionEntryStyles.label.copyWith(
                    color: selected
                        ? DueCollectionEntryColors.brandGold
                        : DueCollectionEntryColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  IconData _modeIcon(DueCollectionPaymentMode mode) {
    switch (mode) {
      case DueCollectionPaymentMode.cash:
        return DueCollectionEntryIcons.cash;
      case DueCollectionPaymentMode.upi:
        return DueCollectionEntryIcons.upi;
      case DueCollectionPaymentMode.card:
        return DueCollectionEntryIcons.card;
      case DueCollectionPaymentMode.bank:
        return DueCollectionEntryIcons.bank;
      case DueCollectionPaymentMode.cheque:
        return DueCollectionEntryIcons.cheque;
    }
  }
}

class _BankAccountDropdown extends StatelessWidget {
  final DueCollectionEntryController ctrl;

  const _BankAccountDropdown({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (ctrl.bankAccounts.isEmpty) {
      return const _MessageBox(
          message:
              'No active bank account found. Click Save to set bank/UPI details first.',
          isError: true);
    }
    final accounts = ctrl.bankAccounts;
    final selected = ctrl.selectedBankAccount ?? accounts.first;
    final selectedIndex = accounts.indexWhere((a) => a.id == selected.id);
    return PopupMenuButton<int>(
      tooltip: 'Select payment account',
      color: DueCollectionEntryColors.bodyPanel,
      elevation: 10,
      offset: const Offset(0, 8),
      constraints: const BoxConstraints(minWidth: 320, maxWidth: 430),
      onSelected: ctrl.setBankAccount,
      itemBuilder: (context) => List.generate(accounts.length, (index) {
        final account = accounts[index];
        return PopupMenuItem<int>(
          value: account.id,
          padding: EdgeInsets.zero,
          child: _PaymentAccountOption(
            account: account,
            role: _accountRole(account, index),
            selected: account.id == selected.id,
          ),
        );
      }),
      child: _SelectedPaymentAccountCard(
        account: selected,
        role: _accountRole(selected, selectedIndex < 0 ? 0 : selectedIndex),
      ),
    );
  }

  String _accountRole(DueCollectionBankAccountModel account, int index) {
    if (account.isPrimary || index == 0) return 'Primary Bank';
    if (index == 1) return 'Secondary Bank';
    return 'Additional Bank ${index + 1}';
  }
}

class _SelectedPaymentAccountCard extends StatelessWidget {
  final DueCollectionBankAccountModel account;
  final String role;

  const _SelectedPaymentAccountCard({
    required this.account,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: DueCollectionEntryStyles.flatPanel(
        color: DueCollectionEntryColors.panelSoft,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DueCollectionEntryColors.brandGoldLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(DueCollectionEntryIcons.bank,
                size: 18, color: DueCollectionEntryColors.brandGold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(role,
                          style: DueCollectionEntryStyles.label.copyWith(
                              color: DueCollectionEntryColors.brandGold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (account.hasUpi) ...[
                      const SizedBox(width: 6),
                      const _MiniAccountBadge(label: 'UPI'),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _accountTitle(account),
                  style: DueCollectionEntryStyles.rowTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _accountMeta(account),
                  style: DueCollectionEntryStyles.rowSub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down_rounded,
              size: 20, color: DueCollectionEntryColors.textMuted),
        ],
      ),
    );
  }
}

class _PaymentAccountOption extends StatelessWidget {
  final DueCollectionBankAccountModel account;
  final String role;
  final bool selected;

  const _PaymentAccountOption({
    required this.account,
    required this.role,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: selected
          ? DueCollectionEntryColors.brandGoldLight
          : DueCollectionEntryColors.bodyPanel,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: selected
                ? DueCollectionEntryColors.brandGold
                : DueCollectionEntryColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role,
                    style: DueCollectionEntryStyles.label.copyWith(
                        color: selected
                            ? DueCollectionEntryColors.brandGold
                            : DueCollectionEntryColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  _accountTitle(account),
                  style: DueCollectionEntryStyles.rowTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _accountMeta(account),
                  style: DueCollectionEntryStyles.rowSub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (account.hasUpi) const _MiniAccountBadge(label: 'UPI'),
        ],
      ),
    );
  }
}

class _MiniAccountBadge extends StatelessWidget {
  final String label;

  const _MiniAccountBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: DueCollectionEntryColors.successBg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: DueCollectionEntryColors.success.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: DueCollectionEntryStyles.rowSub.copyWith(
          color: DueCollectionEntryColors.success,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _accountTitle(DueCollectionBankAccountModel account) {
  if (account.bankName.trim().isEmpty) return account.accountName;
  return '${account.accountName} - ${account.bankName}';
}

String _accountMeta(DueCollectionBankAccountModel account) {
  final parts = <String>[];
  final number = _maskAccountNumber(account.accountNumber);
  if (number.isNotEmpty) parts.add(number);
  final upi = account.upiId?.trim() ?? '';
  if (upi.isNotEmpty) parts.add(upi);
  return parts.isEmpty ? 'Account detail saved' : parts.join('  |  ');
}

String _maskAccountNumber(String value) {
  final text = value.trim();
  if (text.isEmpty) return '';
  if (text.startsWith('UPI:')) return text.substring(4);
  if (text.length <= 4) return text;
  return 'xxxx ${text.substring(text.length - 4)}';
}

class _PaymentSetupDialog extends StatefulWidget {
  final DueCollectionEntryController ctrl;

  const _PaymentSetupDialog({required this.ctrl});

  @override
  State<_PaymentSetupDialog> createState() => _PaymentSetupDialogState();
}

class _PaymentSetupDialogState extends State<_PaymentSetupDialog> {
  late final TextEditingController _accountNameCtrl;
  late final TextEditingController _bankNameCtrl;
  late final TextEditingController _accountNumberCtrl;
  late final TextEditingController _holderCtrl;
  late final TextEditingController _ifscCtrl;
  late final TextEditingController _branchCtrl;
  late final TextEditingController _upiCtrl;

  String? _error;
  bool _isSaving = false;
  late bool _isPrimary;

  bool get _upiOnly =>
      widget.ctrl.needsUpiSetup && widget.ctrl.selectedBankAccount != null;
  bool get _upiRequired =>
      widget.ctrl.paymentMode == DueCollectionPaymentMode.upi;

  @override
  void initState() {
    super.initState();
    final selected = widget.ctrl.selectedBankAccount;
    _accountNameCtrl = TextEditingController(text: selected?.accountName ?? '');
    _bankNameCtrl = TextEditingController(text: selected?.bankName ?? '');
    _accountNumberCtrl =
        TextEditingController(text: selected?.accountNumber ?? '');
    _holderCtrl = TextEditingController();
    _ifscCtrl = TextEditingController();
    _branchCtrl = TextEditingController();
    _upiCtrl = TextEditingController(text: selected?.upiId ?? '');
    _isPrimary = widget.ctrl.bankAccounts.isEmpty;
  }

  @override
  void dispose() {
    _accountNameCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _holderCtrl.dispose();
    _ifscCtrl.dispose();
    _branchCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (_upiOnly) {
      if (_upiCtrl.text.trim().isEmpty) {
        setState(() => _error = 'Enter UPI ID for selected account.');
        return;
      }
      setState(() => _isSaving = true);
      final success =
          await widget.ctrl.updateSelectedAccountUpi(_upiCtrl.text.trim());
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context, true);
      } else {
        setState(() => _error = 'Could not save UPI ID.');
      }
      return;
    }

    if (_accountNameCtrl.text.trim().isEmpty ||
        _bankNameCtrl.text.trim().isEmpty ||
        _accountNumberCtrl.text.trim().isEmpty) {
      setState(() =>
          _error = 'Account name, bank name and account number are required.');
      return;
    }
    if (_upiRequired && _upiCtrl.text.trim().isEmpty) {
      setState(() => _error = 'UPI ID is required for UPI payment.');
      return;
    }

    setState(() => _isSaving = true);
    final id = await widget.ctrl.createPaymentAccount(
      accountName: _accountNameCtrl.text.trim(),
      bankName: _bankNameCtrl.text.trim(),
      accountNumber: _accountNumberCtrl.text.trim(),
      holderName: _holderCtrl.text.trim(),
      ifscCode: _ifscCtrl.text.trim(),
      branchName: _branchCtrl.text.trim(),
      upiId: _upiCtrl.text.trim(),
      isPrimary: _isPrimary,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (id != null) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error = 'Could not save bank account.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeLabel = widget.ctrl.paymentMode.label;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        decoration: BoxDecoration(
          color: DueCollectionEntryColors.bodyPanel,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 32,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 15),
              decoration: const BoxDecoration(
                color: DueCollectionEntryColors.shellPanel,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: DueCollectionEntryColors.brandGoldLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(DueCollectionEntryIcons.bank,
                        size: 20, color: DueCollectionEntryColors.brandGold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Set $modeLabel Details',
                            style: DueCollectionEntryStyles.appBarTitle),
                        const SizedBox(height: 3),
                        Text(
                          _upiOnly
                              ? 'Add UPI ID to the selected account before saving.'
                              : 'Create/select a real account so payment records stay traceable.',
                          style: DueCollectionEntryStyles.appBarSub,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: DueCollectionEntryColors.shellMuted),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_upiOnly) ...[
                      _SetupField(
                        label: 'Selected Account',
                        controller: _accountNameCtrl,
                        icon: DueCollectionEntryIcons.bank,
                        readOnly: true,
                      ),
                      const SizedBox(height: 12),
                      _SetupField(
                        label: 'UPI ID',
                        controller: _upiCtrl,
                        icon: DueCollectionEntryIcons.upi,
                        hint: 'example@upi',
                      ),
                    ] else ...[
                      _SetupTargetSelector(
                        isPrimary: _isPrimary,
                        onChanged: (value) =>
                            setState(() => _isPrimary = value),
                      ),
                      const SizedBox(height: 14),
                      _SetupField(
                        label: 'Account Name',
                        controller: _accountNameCtrl,
                        icon: DueCollectionEntryIcons.bank,
                        hint: 'HDFC Current / PhonePe UPI',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SetupField(
                              label: 'Bank Name',
                              controller: _bankNameCtrl,
                              icon: DueCollectionEntryIcons.bank,
                              hint: 'HDFC Bank',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SetupField(
                              label: 'Account Number',
                              controller: _accountNumberCtrl,
                              icon: DueCollectionEntryIcons.bill,
                              hint: 'Account no',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SetupField(
                              label: 'Holder Name',
                              controller: _holderCtrl,
                              icon: DueCollectionEntryIcons.customer,
                              hint: 'Optional',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SetupField(
                              label: 'IFSC',
                              controller: _ifscCtrl,
                              icon: DueCollectionEntryIcons.receipt,
                              hint: 'Optional',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SetupField(
                              label: 'Branch',
                              controller: _branchCtrl,
                              icon: DueCollectionEntryIcons.location,
                              hint: 'Optional',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SetupField(
                              label: _upiRequired ? 'UPI ID' : 'UPI ID',
                              controller: _upiCtrl,
                              icon: DueCollectionEntryIcons.upi,
                              hint: _upiRequired ? 'Required' : 'Optional',
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      _MessageBox(message: _error!, isError: true),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: DueCollectionEntryColors.bodyBorder),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(DueCollectionEntryIcons.save, size: 17),
                      label: Text(_isSaving ? 'Saving...' : 'Save Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DueCollectionEntryColors.brandGold,
                        foregroundColor: const Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final bool readOnly;

  const _SetupField({
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      style: DueCollectionEntryStyles.rowTitle,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: DueCollectionEntryColors.brandGold),
        filled: true,
        fillColor: DueCollectionEntryColors.panelSoft,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: DueCollectionEntryColors.bodyBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: DueCollectionEntryColors.brandGold, width: 1.4),
        ),
      ),
    );
  }
}

class _SetupTargetSelector extends StatelessWidget {
  final bool isPrimary;
  final ValueChanged<bool> onChanged;

  const _SetupTargetSelector({
    required this.isPrimary,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SetupTargetCard(
            selected: isPrimary,
            icon: DueCollectionEntryIcons.verified,
            title: 'Primary Account',
            subtitle: 'Update Shop Profile primary bank',
            onTap: () => onChanged(true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SetupTargetCard(
            selected: !isPrimary,
            icon: DueCollectionEntryIcons.bank,
            title: 'Additional Account',
            subtitle: 'Create another banking account',
            onTap: () => onChanged(false),
          ),
        ),
      ],
    );
  }
}

class _SetupTargetCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SetupTargetCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? DueCollectionEntryColors.brandGold
        : DueCollectionEntryColors.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? DueCollectionEntryColors.brandGoldLight
              : DueCollectionEntryColors.panelSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? DueCollectionEntryColors.brandGold
                : DueCollectionEntryColors.bodyBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DueCollectionEntryStyles.rowTitle
                        .copyWith(color: DueCollectionEntryColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: DueCollectionEntryStyles.rowSub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettlementPreview extends StatelessWidget {
  final DueCollectionEntryController ctrl;
  final DueCollectionBillModel bill;

  const _SettlementPreview({required this.ctrl, required this.bill});

  @override
  Widget build(BuildContext context) {
    final collected = ctrl.amount.clamp(0.0, bill.dueAmount).toDouble();
    final discount = ctrl.discountAmount.clamp(0.0, bill.dueAmount).toDouble();
    final settlement =
        (collected + discount).clamp(0.0, bill.dueAmount).toDouble();
    final balance = ctrl.balanceAfterSave;
    final progress = bill.dueAmount <= 0 ? 0.0 : settlement / bill.dueAmount;
    final isClosing = balance <= 0.5 && settlement > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: DueCollectionEntryStyles.flatPanel(
          color: DueCollectionEntryColors.panelSoft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MoneyLine(
              label: 'Collecting Now',
              value: collected,
              color: DueCollectionEntryColors.success),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _MoneyLine(
                label: 'Discount / Waiver',
                value: discount,
                color: DueCollectionEntryColors.warning),
          ],
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: progress.clamp(0.0, 1.0),
              backgroundColor: DueCollectionEntryColors.bodyBorder,
              valueColor: AlwaysStoppedAnimation<Color>(isClosing
                  ? DueCollectionEntryColors.success
                  : DueCollectionEntryColors.brandGold),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  isClosing
                      ? 'Bill will close after save'
                      : 'Partial settlement',
                  style: DueCollectionEntryStyles.label.copyWith(
                    color: isClosing
                        ? DueCollectionEntryColors.success
                        : DueCollectionEntryColors.warning,
                  ),
                ),
              ),
              Text(
                DueCollectionEntryController.formatAmount(balance),
                style: DueCollectionEntryStyles.rowTitle.copyWith(
                  color: isClosing
                      ? DueCollectionEntryColors.success
                      : DueCollectionEntryColors.warning,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StickySaveFooter extends StatelessWidget {
  final DueCollectionEntryController ctrl;
  final VoidCallback onSave;
  final VoidCallback onSaveAndPrint;

  const _StickySaveFooter({
    required this.ctrl,
    required this.onSave,
    required this.onSaveAndPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: DueCollectionEntryColors.bodyPanel,
        border: Border(
          top: BorderSide(color: DueCollectionEntryColors.bodyBorder),
        ),
      ),
      child: _SaveActions(
        ctrl: ctrl,
        onSave: onSave,
        onSaveAndPrint: onSaveAndPrint,
      ),
    );
  }
}

class _SaveActions extends StatelessWidget {
  final DueCollectionEntryController ctrl;
  final VoidCallback onSave;
  final VoidCallback onSaveAndPrint;

  const _SaveActions({
    required this.ctrl,
    required this.onSave,
    required this.onSaveAndPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SaveActionButton(
            ctrl: ctrl,
            label: ctrl.isSaving
                ? DueCollectionEntryStrings.saving
                : DueCollectionEntryStrings.saveCollection,
            icon: DueCollectionEntryIcons.save,
            onTap: onSave,
            filled: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SaveActionButton(
            ctrl: ctrl,
            label: DueCollectionEntryStrings.saveAndPrint,
            icon: DueCollectionEntryIcons.printReceipt,
            onTap: onSaveAndPrint,
            filled: false,
          ),
        ),
      ],
    );
  }
}

class _SaveActionButton extends StatelessWidget {
  final DueCollectionEntryController ctrl;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _SaveActionButton({
    required this.ctrl,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = ctrl.canAttemptSave;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled
              ? (filled
                  ? DueCollectionEntryColors.brandGold
                  : DueCollectionEntryColors.bodyPanel)
              : DueCollectionEntryColors.bodyBorder,
          borderRadius: BorderRadius.circular(10),
          border: filled
              ? null
              : Border.all(
                  color: enabled
                      ? DueCollectionEntryColors.brandGold
                      : DueCollectionEntryColors.bodyBorder),
          boxShadow: enabled && filled
              ? [
                  BoxShadow(
                    color: DueCollectionEntryColors.brandGold
                        .withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (ctrl.isSaving && filled)
              const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF111827)))
            else
              Icon(icon,
                  size: 18,
                  color: filled
                      ? const Color(0xFF111827)
                      : DueCollectionEntryColors.brandGold),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                    color: filled
                        ? const Color(0xFF111827)
                        : DueCollectionEntryColors.brandGold,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
