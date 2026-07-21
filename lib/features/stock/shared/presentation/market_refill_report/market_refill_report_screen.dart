import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/market_refill_report_controller.dart';
import 'package:lotus_erp/features/stock/shared/data/repositories/market_refill_report_repository.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/market_refill/market_refill_models.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

part 'widgets/market_refill_report_widgets.dart';
part 'market_refill_purchase_pdf.dart';

class MarketRefillReportScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const MarketRefillReportScreen({super.key, this.onBack});

  @override
  State<MarketRefillReportScreen> createState() =>
      _MarketRefillReportScreenState();
}

class _MarketRefillReportScreenState extends State<MarketRefillReportScreen> {
  late final MarketRefillReportController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MarketRefillReportController(
      MarketRefillReportRepository(AppDatabase()),
    );
    _controller.addListener(_rebuild);
    _controller.load();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  void _handleBack() {
    final fallback = widget.onBack ?? () => Navigator.of(context).maybePop();
    fallback();
  }

  Future<void> _previewPdf() async {
    if (_controller.report.rows.isEmpty) {
      _showSnack('No sold stock found for this period.');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _MarketPurchasePdfPreviewScreen(
          report: _controller.report,
        ),
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InvColors.bodyBg,
      appBar: _MarketRefillAppBar(
        onBack: _handleBack,
        onRefresh: _controller.load,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MarketRefillHero(
                  report: _controller.report,
                  isExportEnabled: !_controller.isLoading &&
                      _controller.report.rows.isNotEmpty,
                  canRestore: !_controller.isLoading &&
                      _controller.report.rows.isEmpty &&
                      _controller.report.lastClearedAt != null,
                  onPreviewPdf: _previewPdf,
                  onCheckout: _confirmCheckoutAndClear,
                  onRestore: _restoreClearedList,
                ),
                const SizedBox(height: 18),
                _MarketRefillItemList(
                  report: _controller.report,
                  onProgressChanged: _controller.updateLineProgress,
                ),
                const SizedBox(height: 18),
                _MarketRefillHistoryPanel(records: _controller.recentCheckouts),
              ],
            ),
          ),
          if (_controller.isLoading)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: InvColors.bodyBg.withValues(alpha: 0.55),
                  alignment: Alignment.topCenter,
                  padding: const EdgeInsets.only(top: 18),
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.8,
                      color: InvColors.brandGold,
                    ),
                  ),
                ),
              ),
            ),
          if (_controller.errorMessage != null && !_controller.isLoading)
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: _MarketRefillError(message: _controller.errorMessage!),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmCheckoutAndClear() async {
    if (_controller.report.rows.isEmpty) {
      _showSnack('Purchase ready list is already empty.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFCF7),
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 6),
        actionsPadding: const EdgeInsets.fromLTRB(20, 4, 24, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Checkout clear purchase list?',
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: InvColors.textDark,
          ),
        ),
        content: Text(
          'Current sold items will be hidden from this active market list. '
          'Temporary checkout history stays for 2 days only. '
          'Your sales and stock history will stay safe.',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.45,
            color: InvColors.textDark,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: InvColors.textDark,
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: InvColors.brandGold,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Checkout Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _controller.checkoutAndClear();
    _showSnack('Purchase ready list checked out and cleared.');
  }

  Future<void> _restoreClearedList() async {
    await _controller.restoreClearedList();
    _showSnack('Previous purchase list restored.');
  }
}
