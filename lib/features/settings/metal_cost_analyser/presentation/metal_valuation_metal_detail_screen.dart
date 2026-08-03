import 'package:flutter/material.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/application/metal_valuation_controller.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_models.dart';

import 'widgets/metal_valuation_app_bar.dart';
import 'widgets/metal_valuation_tables.dart';
import 'widgets/metal_valuation_tokens.dart';

class MetalValuationMetalDetailScreen extends StatefulWidget {
  final String metalType;
  final VoidCallback? onBack;

  const MetalValuationMetalDetailScreen({
    super.key,
    required this.metalType,
    this.onBack,
  });

  @override
  State<MetalValuationMetalDetailScreen> createState() =>
      _MetalValuationMetalDetailScreenState();
}

class _MetalValuationMetalDetailScreenState
    extends State<MetalValuationMetalDetailScreen> {
  late final MetalValuationFilter _filter;
  late final MetalValuationController _controller;

  @override
  void initState() {
    super.initState();
    _filter = MetalValuationFilter.fromMetalType(widget.metalType);
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
        final title = _filter.isAll
            ? 'METAL PERFORMANCE'
            : '${_filter.label.toUpperCase()} PERFORMANCE';
        return Scaffold(
          backgroundColor: MetalValuationColors.canvas,
          appBar: MetalValuationAppBar(
            title: title,
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
          _controller.errorMessage ?? 'Unable to load metal performance.',
          style: MetalValuationText.body,
        ),
      );
    }

    final snapshot = _controller.snapshot;
    final row = snapshot.breakdown.isEmpty ? null : snapshot.breakdown.first;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MetalDetailHeader(
                metalType: _filter.isAll ? widget.metalType : _filter.label,
                row: row,
              ),
              const SizedBox(height: 16),
              AvailableStockValuationTable(rows: snapshot.availableStock),
              const SizedBox(height: 16),
              SoldStockValuationTable(rows: snapshot.soldStock),
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

class _MetalDetailHeader extends StatelessWidget {
  final String metalType;
  final MetalValuationBreakdown? row;

  const _MetalDetailHeader({
    required this.metalType,
    required this.row,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedMetal = metalType.toUpperCase();
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
                metalType: normalizedMetal,
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
                      '${titleCase(metalType)} Stock Performance',
                      style: MetalValuationText.sectionTitle.copyWith(
                        fontSize: 26,
                        color: const Color(0xFF3B2A08),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Metal-specific stock movement, sold weight and live inventory.',
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
                childAspectRatio: columns == 2 ? 3.8 : 5.2,
                children: [
                  _HeaderMetric(
                    label: 'Available Net Weight',
                    value: formatGram(row?.availableNetWeight ?? 0),
                    color: MetalValuationColors.green,
                  ),
                  _HeaderMetric(
                    label: 'Available Total Fine',
                    value: formatGram(row?.availableFineWeight ?? 0),
                    color: MetalValuationColors.green,
                  ),
                  _HeaderMetric(
                    label: 'Available Units',
                    value: '${row?.availableUnits ?? 0}',
                    color: MetalValuationColors.green,
                  ),
                  _HeaderMetric(
                    label: 'Sold Net Weight',
                    value: formatGram(row?.soldNetWeight ?? 0),
                    color: MetalValuationColors.red,
                  ),
                  _HeaderMetric(
                    label: 'Sold Total Fine',
                    value: formatGram(row?.soldFineWeight ?? 0),
                    color: MetalValuationColors.red,
                  ),
                  _HeaderMetric(
                    label: 'Sold Units',
                    value: '${row?.soldUnits ?? 0}',
                    color: MetalValuationColors.red,
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
  final Color color;

  const _HeaderMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
              color: color,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}
