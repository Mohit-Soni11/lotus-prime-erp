import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../constants/app_routes.dart';
import '../../../database/db/app_database.dart';
import '../../../logic/girvi/girvi_account_detail_controller.dart';
import '../../../logic/girvi/girvi_invoice_hub_controller.dart';
import '../../../logic/girvi/girvi_payment_record_pdf_service.dart';
import '../../../models/girvi/girvi_account_lifecycle_summary.dart';
import '../../../models/girvi/girvi_enums.dart';
import '../../../models/girvi/girvi_loan_model.dart';
import '../../../repositories/customer/customer_profile_repository.dart';
import '../../../repositories/girvi/girvi_details_repository.dart';
import '../../../repositories/girvi/girvi_invoice_branding_repository.dart';
import '../../../theme/girvi/girvi_theme.dart';
import '../shared/girvi_shared_widgets.dart';

part 'parts/girvi_account_detail_layout.dart';
part 'parts/girvi_account_detail_panels.dart';
part 'parts/girvi_account_detail_payment_history.dart';
part 'parts/girvi_account_detail_shared.dart';

class GirviAccountDetailScreen extends StatefulWidget {
  final int loanId;
  final VoidCallback onBack;
  final String? returnTo;

  const GirviAccountDetailScreen({
    super.key,
    required this.loanId,
    required this.onBack,
    this.returnTo,
  });

  @override
  State<GirviAccountDetailScreen> createState() =>
      _GirviAccountDetailScreenState();
}

class _GirviAccountDetailScreenState extends State<GirviAccountDetailScreen> {
  final AppDatabase _db = AppDatabase();
  late final GirviAccountDetailController _controller;

  final NumberFormat _moneyFormat = NumberFormat('#,##,##0', 'en_IN');
  final NumberFormat _preciseMoneyFormat = NumberFormat('#,##,##0.00', 'en_IN');
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  bool _openingGirviInvoice = false;
  bool _viewingPaymentRecord = false;
  bool _printingPaymentRecord = false;

  @override
  void initState() {
    super.initState();
    _controller = GirviAccountDetailController(_db)..load(widget.loanId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _reload() => _controller.load(widget.loanId);

  void _openInterestEntry() {
    final account = _controller.account;
    if (account == null) return;

    context.go(
      Uri(
        path: RoutePaths.girviInterest,
        queryParameters: {
          'ticketNo': account.loan.ticketNo,
          'returnTo': widget.returnTo == 'riskCollections' ||
                  widget.returnTo == 'girviNotice'
              ? widget.returnTo!
              : 'girviLedger',
        },
      ).toString(),
    );
  }

  Future<void> _previewGirviInvoice() async {
    final account = _controller.account;
    if (account == null || _openingGirviInvoice) return;

    setState(() => _openingGirviInvoice = true);
    try {
      final bytes = await _buildGirviInvoicePdf(account);
      if (!mounted) return;

      await _showGirviInvoicePreview(pdfBytes: bytes);
    } catch (_) {
      if (mounted) _showMessage('Girvi invoice could not be opened.');
    } finally {
      if (mounted) setState(() => _openingGirviInvoice = false);
    }
  }

  Future<Uint8List> _buildGirviInvoicePdf(
    GirviLoanWithCustomer account,
  ) async {
    final draft =
        await CustomerProfileRepository(db: _db).fetchGirviInvoiceDraft(
      customerId: account.loan.customerId,
      loanId: account.loan.id,
    );
    if (draft == null) {
      throw StateError('Girvi invoice draft could not be loaded.');
    }

    final invoiceController = GirviInvoiceHubController(
      draft: draft,
      onFinalize: () async => true,
    );
    try {
      await invoiceController.generatePreview();
      final bytes = invoiceController.pdfBytes;
      if (bytes == null) {
        throw StateError('Girvi invoice PDF could not be generated.');
      }
      return bytes;
    } finally {
      invoiceController.dispose();
    }
  }

  Future<void> _showGirviInvoicePreview({required Uint8List pdfBytes}) async {
    final sides = await _rasterGirviInvoiceSides(pdfBytes);
    if (!mounted) return;
    if (sides.isEmpty) {
      return _showCleanGirviInvoicePreview(pdfBytes: pdfBytes);
    }

    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      useSafeArea: false,
      builder: (dialogContext) => Material(
        type: MaterialType.transparency,
        child: _GirviInvoiceFlipPreview(
          sides: sides,
          onClose: () => Navigator.of(dialogContext).pop(),
        ),
      ),
    );
  }

  Future<List<PdfRaster>> _rasterGirviInvoiceSides(Uint8List pdfBytes) async {
    try {
      final info = await Printing.info();
      if (!info.canRaster) return const [];

      final sides = <PdfRaster>[];
      await for (final page in Printing.raster(pdfBytes, dpi: 144)) {
        sides.add(page);
        if (sides.length == 2) break;
      }
      return List.unmodifiable(sides);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _showCleanGirviInvoicePreview({required Uint8List pdfBytes}) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.74),
      useSafeArea: false,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF111827),
        child: Stack(
          children: [
            Positioned.fill(
              child: PdfPreview(
                build: (_) async => pdfBytes,
                initialPageFormat: PdfPageFormat.a4,
                allowPrinting: false,
                allowSharing: false,
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                useActions: false,
                maxPageWidth: 860,
                scrollViewDecoration: const BoxDecoration(
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Positioned(
              top: 18,
              right: 18,
              child: Material(
                color: Colors.black.withValues(alpha: 0.62),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Close preview',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printPaymentRecord() async {
    final account = _controller.account;
    if (account == null || _printingPaymentRecord) return;

    setState(() => _printingPaymentRecord = true);
    try {
      final bytes = await _buildPaymentRecordPdf(account);
      if (!mounted) return;

      await Printing.layoutPdf(
        name: 'girvi_payment_record_${_safePdfName(account.loan.ticketNo)}.pdf',
        onLayout: (_) async => bytes,
      );
    } catch (_) {
      if (mounted) _showMessage('Payment record could not be printed.');
    } finally {
      if (mounted) setState(() => _printingPaymentRecord = false);
    }
  }

  Future<void> _previewPaymentRecord() async {
    final account = _controller.account;
    if (account == null || _viewingPaymentRecord) return;

    setState(() => _viewingPaymentRecord = true);
    try {
      final bytes = await _buildPaymentRecordPdf(account);
      if (!mounted) return;

      await _showPaymentRecordPreview(
        pdfBytes: bytes,
        fileName:
            'girvi_payment_record_${_safePdfName(account.loan.ticketNo)}.pdf',
      );
    } catch (_) {
      if (mounted) _showMessage('Payment record could not be opened.');
    } finally {
      if (mounted) setState(() => _viewingPaymentRecord = false);
    }
  }

  Future<Uint8List> _buildPaymentRecordPdf(
      GirviLoanWithCustomer account) async {
    final branding = await GirviInvoiceBrandingRepository(db: _db).fetch();
    return GirviPaymentRecordPdfService().build(
      account: account,
      payments: _controller.payments,
      details: _controller.details,
      branding: branding,
    );
  }

  Future<void> _showPaymentRecordPreview({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    final sides = await _rasterPaymentRecordSides(pdfBytes);
    if (!mounted) return;
    if (sides.isNotEmpty) {
      return showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.78),
        useSafeArea: false,
        builder: (dialogContext) => Material(
          type: MaterialType.transparency,
          child: _GirviInvoiceFlipPreview(
            sides: sides,
            singleSideLabel: 'Payment record preview',
            onClose: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      );
    }

    return _showCleanPaymentRecordPreview(
      pdfBytes: pdfBytes,
      fileName: fileName,
    );
  }

  Future<List<PdfRaster>> _rasterPaymentRecordSides(Uint8List pdfBytes) async {
    try {
      final info = await Printing.info();
      if (!info.canRaster) return const [];

      final sides = <PdfRaster>[];
      await for (final page in Printing.raster(pdfBytes, dpi: 144)) {
        sides.add(page);
        if (sides.length == 2) break;
      }
      return List.unmodifiable(sides);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _showCleanPaymentRecordPreview({
    required Uint8List pdfBytes,
    required String fileName,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.74),
      useSafeArea: false,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF111827),
        child: Stack(
          children: [
            Positioned.fill(
              child: PdfPreview(
                build: (_) async => pdfBytes,
                initialPageFormat: PdfPageFormat.a4,
                allowPrinting: true,
                allowSharing: false,
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                pdfFileName: fileName,
                maxPageWidth: 860,
                scrollViewDecoration: const BoxDecoration(
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Positioned(
              top: 18,
              right: 18,
              child: Material(
                color: Colors.black.withValues(alpha: 0.62),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Close preview',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _safePdfName(String value) {
    return value.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: GirviColors.shellBg,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _money(double value, {bool precise = false}) {
    final format = precise ? _preciseMoneyFormat : _moneyFormat;
    return 'Rs ${format.format(value)}';
  }

  String _date(DateTime? value) {
    if (value == null) return 'Not set';
    return _dateFormat.format(value);
  }

  String _dateTime(DateTime? value) {
    if (value == null) return 'Not set';
    return _dateTimeFormat.format(value);
  }

  String _weight(double value) => '${value.toStringAsFixed(2)} g';

  String _accountStatusLabel(GirviLoanWithCustomer account) {
    final loan = account.loan;
    if (loan.deliveredAt != null) return 'Delivered and Closed';
    if (loan.girviStatus == GirviStatus.readyForDelivery) {
      return 'Settlement Complete - Delivery Pending';
    }
    if (loan.girviStatus == GirviStatus.partialRelease) {
      return 'Settlement Pending';
    }
    if (loan.girviStatus == GirviStatus.auctioned) return 'Auctioned';
    if (loan.girviStatus == GirviStatus.released) return 'Released';
    if (loan.isOverdue) return 'Overdue';
    return loan.statusLabel;
  }

  Color _accountStatusColor(GirviLoanWithCustomer account) {
    final status = account.loan.girviStatus;
    if (account.loan.deliveredAt != null) return GirviColors.success;
    if (status == GirviStatus.readyForDelivery) return GirviColors.success;
    if (status == GirviStatus.partialRelease) return GirviColors.warning;
    if (status == GirviStatus.auctioned) return GirviColors.statusAuctioned;
    if (account.loan.isOverdue) return GirviColors.danger;
    return account.loan.statusColor;
  }

  bool _canOpenSettlementAction(GirviLoanWithCustomer account) {
    final status = account.loan.girviStatus;
    return status == GirviStatus.active ||
        status == GirviStatus.overdue ||
        status == GirviStatus.partialRelease ||
        status == GirviStatus.readyForDelivery;
  }

  String _settlementActionLabel(GirviLoanWithCustomer account) {
    if (account.loan.girviStatus == GirviStatus.readyForDelivery) {
      return 'Complete Delivery';
    }
    return 'Collect / Settle';
  }

  String? _paymentCoverageLabel(GirviPaymentModel payment) {
    final from = payment.interestFromDate;
    final to = payment.interestToDate;
    if (from != null && to != null) {
      return '${_date(from)} to ${_date(to)}';
    }

    final months = payment.monthsCovered ?? 0;
    if (months > 0) return '$months month${months == 1 ? '' : 's'} covered';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GirviColors.bodyBg,
      appBar: GirviAppBar(
        screenTitle: 'GIRVI ACCOUNT',
        screenSubtitle: 'Ticket statement',
        onBack: widget.onBack,
        actions: [
          _AccountHeaderButton(
            tooltip: 'Refresh account',
            icon: GirviIcons.refresh,
            onTap: _reload,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const _AccountLoadingState();
          }

          if (_controller.errorMessage != null) {
            return _AccountErrorState(
              message: _controller.errorMessage!,
              onRetry: _reload,
              onBack: widget.onBack,
            );
          }

          final account = _controller.account;
          if (account == null) {
            return _AccountErrorState(
              message: 'Girvi account could not be found.',
              onRetry: _reload,
              onBack: widget.onBack,
            );
          }

          return _buildAccountDetailBody(account);
        },
      ),
    );
  }
}
