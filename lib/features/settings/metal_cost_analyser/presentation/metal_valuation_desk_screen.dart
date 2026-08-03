import 'package:flutter/material.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/application/metal_valuation_controller.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_models.dart';

import 'widgets/metal_valuation_app_bar.dart';
import 'widgets/metal_valuation_breakdown_panel.dart';
import 'widgets/metal_valuation_filter_bar.dart';
import 'widgets/metal_valuation_summary_panel.dart';
import 'widgets/metal_valuation_tables.dart';
import 'widgets/metal_valuation_tokens.dart';

class MetalValuationDeskScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const MetalValuationDeskScreen({super.key, this.onBack});

  @override
  State<MetalValuationDeskScreen> createState() =>
      _MetalValuationDeskScreenState();
}

class _MetalValuationDeskScreenState extends State<MetalValuationDeskScreen> {
  late final MetalValuationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MetalValuationController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: MetalValuationColors.canvas,
          appBar: MetalValuationAppBar(
            onBack: widget.onBack ?? () => Navigator.maybePop(context),
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_controller.hasError) {
      return _ErrorView(
        message:
            _controller.errorMessage ?? 'Unable to load metal valuation data.',
        onRetry: _controller.refresh,
      );
    }

    final snapshot = _controller.snapshot;
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MetalValuationSummaryPanel(snapshot: snapshot),
              const SizedBox(height: 16),
              _ControlPanel(
                selectedFilter: _controller.filter,
                onFilterChanged: _controller.setFilter,
              ),
              const SizedBox(height: 16),
              MetalValuationMetricStrip(summary: snapshot.summary),
              const SizedBox(height: 16),
              MetalValuationBreakdownPanel(rows: snapshot.breakdown),
              const SizedBox(height: 16),
              SoldStockValuationTable(rows: snapshot.soldStock),
              const SizedBox(height: 16),
              AvailableStockValuationTable(rows: snapshot.availableStock),
              const SizedBox(height: 24),
            ],
          ),
        ),
        if (_controller.isLoading)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: MetalValuationColors.canvas.withValues(alpha: 0.36),
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 18),
                child: const _LoadingChip(),
              ),
            ),
          ),
      ],
    );
  }
}

class _ControlPanel extends StatelessWidget {
  final MetalValuationFilter selectedFilter;
  final ValueChanged<MetalValuationFilter> onFilterChanged;

  const _ControlPanel({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: valuationPanelDecoration(color: Colors.white),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: MetalValuationColors.gold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: MetalValuationColors.goldDark,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Valuation Scope', style: MetalValuationText.sectionTitle),
                const SizedBox(height: 3),
                Text(
                  'Filter the desk by metal without changing source records.',
                  style: MetalValuationText.body,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            flex: 2,
            child: MetalValuationFilterBar(
              selected: selectedFilter,
              onChanged: onFilterChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingChip extends StatelessWidget {
  const _LoadingChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: MetalValuationColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: MetalValuationColors.goldDark,
            ),
          ),
          const SizedBox(width: 10),
          Text('Refreshing valuation data', style: MetalValuationText.body),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        decoration: valuationPanelDecoration(color: Colors.white),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: MetalValuationColors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: MetalValuationColors.red,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Valuation Desk Needs Refresh',
              style: MetalValuationText.sectionTitle,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: MetalValuationText.body,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh Desk'),
              style: FilledButton.styleFrom(
                backgroundColor: MetalValuationColors.goldDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
