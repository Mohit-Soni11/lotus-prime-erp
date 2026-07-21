import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/market_refill_report_controller.dart';
import 'package:lotus_erp/features/stock/shared/data/repositories/market_refill_report_repository.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/market_refill/market_refill_models.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

part 'widgets/market_refill_report_widgets.dart';

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

  Future<void> _exportCsv() async {
    if (_controller.report.rows.isEmpty) {
      _showSnack('No sold stock found for this period.');
      return;
    }
    final selectedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Market Refill Report',
      fileName: _controller.suggestedFileName(),
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    if (selectedPath == null) return;
    final exportedPath = await _controller.exportCsv(selectedPath);
    _showSnack('Market refill report exported: $exportedPath');
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
                  isExportEnabled:
                      !_controller.isLoading && _controller.report.rows.isNotEmpty,
                  onExport: _exportCsv,
                ),
                const SizedBox(height: 18),
                _MarketRefillToolbar(
                  selected: _controller.preset,
                  onChanged: _controller.selectPreset,
                ),
                const SizedBox(height: 18),
                _MarketRefillMetalSnapshot(metals: _controller.report.metals),
                const SizedBox(height: 18),
                _MarketRefillItemList(report: _controller.report),
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
}
