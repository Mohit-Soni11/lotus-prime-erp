import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../logic/booking_advance/booking_invoice_pdf_service.dart';
import '../../../logic/booking_advance/booking_invoice_preview_controller.dart';
import '../../../repositories/booking_advance/booking_advance_repository.dart';
import '../../../theme/booking_advance/booking_advance_theme.dart';
import 'widgets/booking_invoice_command_panel.dart';

class BookingInvoicePreviewScreen extends StatefulWidget {
  const BookingInvoicePreviewScreen({
    super.key,
    required this.orderIds,
    BookingAdvanceRepository? repository,
  }) : _repository = repository;

  final List<int> orderIds;
  final BookingAdvanceRepository? _repository;

  static Future<void> push(
    BuildContext context, {
    required List<int> orderIds,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (ctx, anim, _) {
          return BookingInvoicePreviewScreen(orderIds: orderIds);
        },
        transitionsBuilder: (ctx, anim, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  @override
  State<BookingInvoicePreviewScreen> createState() =>
      _BookingInvoicePreviewScreenState();
}

class _BookingInvoicePreviewScreenState
    extends State<BookingInvoicePreviewScreen> {
  late final BookingInvoicePreviewController _controller;
  bool _isSharing = false;
  bool _isExporting = false;
  bool _isPrinting = false;
  bool _isExported = false;
  bool _isPrinted = false;

  @override
  void initState() {
    super.initState();
    _controller = BookingInvoicePreviewController(
      orderIds: widget.orderIds,
      repository: widget._repository,
    );
    _controller.addListener(_handleControllerChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.load();
      }
    });
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BookingAdvanceColors.bodyBg,
      body: SafeArea(
        child: Row(
          children: [
            BookingInvoiceCommandPanel(
              controller: _controller,
              isSharing: _isSharing,
              isExporting: _isExporting,
              isPrinting: _isPrinting,
              isExported: _isExported,
              isPrinted: _isPrinted,
              onBack: () => Navigator.of(context).maybePop(),
              onShare: _sharePdf,
              onExport: _exportPdf,
              onPrint: _printPdf,
            ),
            Expanded(
              child: Container(
                color: BookingAdvanceColors.bodyBorder.withValues(alpha: 0.28),
                child: _buildPreviewPanel(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewPanel() {
    if (_controller.genState == BookingInvoiceGenerationState.idle ||
        _controller.genState == BookingInvoiceGenerationState.generating) {
      return const Center(
        child: CircularProgressIndicator(
          color: BookingAdvanceColors.brandGold,
        ),
      );
    }

    if (_controller.genState == BookingInvoiceGenerationState.error) {
      return Center(
        child: Text(
          'Error: ${_controller.errorMessage}',
          style: const TextStyle(color: BookingAdvanceColors.danger),
        ),
      );
    }

    final previewKey = ValueKey(
      '${_controller.selectedFormat.name}-'
      '${_controller.printCopies}-'
      '${_controller.includeDuplicateStamp}-'
      '${_controller.includeCustomerAddress}-'
      '${_controller.includeRateColumn}-'
      '${_controller.includeTerms}-'
      '${_controller.pdfBytes?.length ?? 0}',
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Padding(
        key: previewKey,
        padding: const EdgeInsets.all(32),
        child: PdfPreview(
          build: (_) async => _controller.pdfBytes!,
          allowPrinting: false,
          allowSharing: false,
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
          initialPageFormat: BookingInvoicePdfService.pageFormatFor(
            _controller.selectedFormat,
          ),
        ),
      ),
    );
  }

  Future<void> _sharePdf() async {
    setState(() => _isSharing = true);
    try {
      final shared = await _controller.shareInvoicePdf();
      if (!mounted) return;
      if (!shared) {
        AppFeedback.error(context, message: 'Booking invoice share cancelled.');
      }
    } catch (_) {
      if (!mounted) return;
      AppFeedback.error(
        context,
        message: 'Booking invoice PDF share failed. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    final path = await _controller.exportInvoicePdf();
    if (!mounted) return;
    setState(() {
      _isExporting = false;
      _isExported = path != null;
    });
    if (path == null) return;

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isExported = false);
      }
    });
    AppFeedback.success(
      context,
      message: 'Booking invoice exported successfully.',
    );
  }

  Future<void> _printPdf() async {
    setState(() => _isPrinting = true);
    try {
      final printed = await _controller.printInvoice(context);
      if (!mounted) return;
      setState(() {
        _isPrinting = false;
        _isPrinted = printed || _isPrinted;
      });
      if (printed) {
        AppFeedback.success(
          context,
          message: 'Booking invoice printed successfully.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPrinting = false);
      AppFeedback.error(
        context,
        message: 'Booking invoice print failed. Please try again.',
      );
    }
  }
}
