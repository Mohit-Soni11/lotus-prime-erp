import 'package:flutter/material.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/application/metal_valuation_controller.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_models.dart';

import 'widgets/metal_valuation_app_bar.dart';
import 'widgets/metal_valuation_tables.dart';
import 'widgets/metal_valuation_tokens.dart';

class MetalValuationBatchDetailScreen extends StatefulWidget {
  final String metalType;
  final String batchCode;
  final VoidCallback? onBack;

  const MetalValuationBatchDetailScreen({
    super.key,
    required this.metalType,
    required this.batchCode,
    this.onBack,
  });

  @override
  State<MetalValuationBatchDetailScreen> createState() =>
      _MetalValuationBatchDetailScreenState();
}

class _MetalValuationBatchDetailScreenState
    extends State<MetalValuationBatchDetailScreen> {
  late final MetalValuationFilter _filter;
  late final String _batchCode;
  late final MetalValuationController _controller;

  @override
  void initState() {
    super.initState();
    _filter = MetalValuationFilter.fromMetalType(widget.metalType);
    _batchCode = Uri.decodeComponent(widget.batchCode);
    _controller = MetalValuationController(initialFilter: _filter)..load();
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
            title: '${_filter.label.toUpperCase()} BATCH VALUATION',
            onBack: widget.onBack ?? () => Navigator.maybePop(context),
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_controller.hasError) {
      return Center(
        child: Text(
          _controller.errorMessage ?? 'Unable to load batch valuation.',
          style: MetalValuationText.body,
        ),
      );
    }

    final snapshot = _controller.snapshot;
    final batch = snapshot.batchSummaries
        .where((row) => row.batchCode == _batchCode)
        .cast<BatchValuationRow?>()
        .firstOrNull;
    final availableRows = snapshot.availableStock
        .where((row) => row.batchCode == _batchCode)
        .toList();
    final soldRows =
        snapshot.soldStock.where((row) => row.batchCode == _batchCode).toList();

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BatchDetailHeader(
                batchCode: _batchCode,
                metalType: _filter.label,
                batch: batch,
              ),
              const SizedBox(height: 16),
              ItemValuationLedgerTable(rows: availableRows),
              const SizedBox(height: 16),
              SoldStockValuationTable(rows: soldRows),
              const SizedBox(height: 24),
            ],
          ),
        ),
        if (_controller.isLoading)
          Positioned.fill(
            child: Container(
              color: MetalValuationColors.canvas.withValues(alpha: 0.34),
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 18),
              child: const CircularProgressIndicator(
                color: MetalValuationColors.goldDark,
              ),
            ),
          ),
      ],
    );
  }
}

class _BatchDetailHeader extends StatelessWidget {
  final String batchCode;
  final String metalType;
  final BatchValuationRow? batch;

  const _BatchDetailHeader({
    required this.batchCode,
    required this.metalType,
    required this.batch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF4BF), Color(0xFFE0B11F)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MetalValuationMetalImage(
                metalType: metalType,
                borderColor: Colors.white,
                fallbackColor: MetalValuationColors.goldDark,
                size: 58,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batchCode,
                      style: MetalValuationText.sectionTitle.copyWith(
                        fontSize: 25,
                        color: const Color(0xFF3B2A08),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatDate(batch?.createdAt)}  |  ${batch?.supplierName ?? 'Not recorded'}',
                      style: MetalValuationText.body.copyWith(
                        color: const Color(0xFF4B3A12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 780 ? 2 : 3;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: columns,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: columns == 2 ? 3.1 : 4.3,
                children: [
                  _HeaderMetric(
                    label: 'Total Net Weight',
                    value: formatGram(batch?.totalNetWeight ?? 0),
                    valueColor: MetalValuationColors.green,
                  ),
                  _HeaderMetric(
                    label: 'Total Valuation Fine',
                    value: formatGram(batch?.valuationFineWeight ?? 0),
                    valueColor: MetalValuationColors.goldDark,
                  ),
                  _HeaderMetric(
                    label: 'Rate',
                    value: '${formatMoney(batch?.ratePerGram ?? 0)}/g',
                    valueColor: MetalValuationColors.goldDark,
                  ),
                  _HeaderMetric(
                    label: 'Making',
                    value: formatMoney(batch?.makingAmount ?? 0),
                  ),
                  _HeaderMetric(
                    label: 'Valuation Cost',
                    value: formatMoney(batch?.totalCost ?? 0),
                    valueColor: MetalValuationColors.goldDark,
                  ),
                  _HeaderMetric(
                    label: 'Total Units',
                    value: '${batch?.totalUnits ?? 0}',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _HeaderMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: MetalValuationText.label),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MetalValuationText.value.copyWith(
              fontSize: 19,
              color: valueColor ?? MetalValuationColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
