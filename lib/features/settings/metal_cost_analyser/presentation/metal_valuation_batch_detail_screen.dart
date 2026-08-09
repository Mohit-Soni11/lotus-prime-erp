import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/application/metal_valuation_controller.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/data/metal_valuation_grade_repository.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_grade_models.dart';
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
  late final Future<MetalValuationGradeSnapshot> _gradeFuture;

  @override
  void initState() {
    super.initState();
    _filter = MetalValuationFilter.fromMetalType(widget.metalType);
    _batchCode = Uri.decodeComponent(widget.batchCode);
    _controller = MetalValuationController(initialFilter: _filter)..load();
    _gradeFuture = MetalValuationGradeRepository().fetchGradeSnapshot(
      _filter.label,
      batchCode: _batchCode,
    );
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
              FutureBuilder<MetalValuationGradeSnapshot>(
                future: _gradeFuture,
                builder: (context, gradeSnapshot) {
                  if (gradeSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const _BatchGradeLoadingPanel();
                  }
                  if (gradeSnapshot.hasError) {
                    return const _BatchGradeMessagePanel(
                      title: 'Grade Valuation Not Available',
                      message:
                          'Batch grade movement could not be loaded right now.',
                    );
                  }
                  final grades = gradeSnapshot.data?.grades ??
                      const <MetalValuationGradeRow>[];
                  if (grades.isEmpty) {
                    return const _BatchGradeMessagePanel(
                      title: 'No Grade Movement',
                      message:
                          'This batch has no available or sold grade movement yet.',
                    );
                  }
                  return _BatchGradeGrid(
                    metalType: _filter.label,
                    batchCode: _batchCode,
                    grades: grades,
                  );
                },
              ),
              const SizedBox(height: 16),
              ItemValuationLedgerTable(rows: availableRows),
              const SizedBox(height: 16),
              SoldStockValuationTable(
                rows: soldRows,
                onInvoiceSelected: _openSoldInvoice,
                onCustomerSelected: _openSoldCustomer,
              ),
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

  void _openSoldInvoice(SoldValuationRow row) {
    final customerId = row.customerId;
    if (customerId == null) return;
    context.push(
      Uri(
        path: RoutePaths.customerProfileFor(customerId),
        queryParameters: {'billId': '${row.billId}'},
      ).toString(),
    );
  }

  void _openSoldCustomer(SoldValuationRow row) {
    final customerId = row.customerId;
    if (customerId == null) return;
    context.push(RoutePaths.customerProfileFor(customerId));
  }
}

class _BatchGradeGrid extends StatelessWidget {
  final String metalType;
  final String batchCode;
  final List<MetalValuationGradeRow> grades;

  const _BatchGradeGrid({
    required this.metalType,
    required this.batchCode,
    required this.grades,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: valuationPanelDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  Icons.layers_rounded,
                  color: MetalValuationColors.goldDark,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grade Valuation',
                      style: MetalValuationText.sectionTitle,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Batch movement separated by grade or item group.',
                      style: MetalValuationText.body,
                    ),
                  ],
                ),
              ),
              Text(
                '${grades.length} groups',
                style: MetalValuationText.label.copyWith(
                  color: MetalValuationColors.goldDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 1120
                  ? (constraints.maxWidth - 24) / 3
                  : constraints.maxWidth >= 720
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final grade in grades)
                    SizedBox(
                      width: width,
                      child: _BatchGradeCard(
                        metalType: metalType,
                        batchCode: batchCode,
                        grade: grade,
                      ),
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

class _BatchGradeCard extends StatelessWidget {
  final String metalType;
  final String batchCode;
  final MetalValuationGradeRow grade;

  const _BatchGradeCard({
    required this.metalType,
    required this.batchCode,
    required this.grade,
  });

  @override
  Widget build(BuildContext context) {
    final active = grade.soldUnits > 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          PageRouteBuilder<void>(
            pageBuilder: (_, animation, __) => _BatchGradeDetailScreen(
              metalType: metalType,
              batchCode: batchCode,
              grade: grade,
            ),
            transitionsBuilder: (_, animation, __, child) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );
              return FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.025, 0),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
              );
            },
          ),
        ),
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: MetalValuationColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      titleCase(grade.gradeLabel),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MetalValuationText.sectionTitle.copyWith(
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: active
                        ? MetalValuationColors.goldDark
                        : MetalValuationColors.green,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _BatchGradeMetric(
                      label: 'Available',
                      value: formatGram(grade.availableNetWeight),
                      color: MetalValuationColors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _BatchGradeMetric(
                      label: 'Sold',
                      value: formatGram(grade.soldNetWeight),
                      color: active
                          ? MetalValuationColors.red
                          : MetalValuationColors.softInk,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _BatchGradeFact(
                      label: 'Sold Cost',
                      value: formatMoney(grade.soldCost),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _BatchGradeFact(
                      label: 'Profit',
                      value: formatMoney(grade.profit),
                      color: grade.profit >= 0
                          ? MetalValuationColors.green
                          : MetalValuationColors.red,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _BatchGradeFact(
                      label: 'Margin',
                      value: formatPercent(grade.marginPercent),
                      color: grade.marginPercent >= 0
                          ? MetalValuationColors.green
                          : MetalValuationColors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BatchGradeDetailScreen extends StatelessWidget {
  final String metalType;
  final String batchCode;
  final MetalValuationGradeRow grade;

  const _BatchGradeDetailScreen({
    required this.metalType,
    required this.batchCode,
    required this.grade,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MetalValuationColors.canvas,
      appBar: MetalValuationAppBar(
        title: '${titleCase(grade.gradeLabel).toUpperCase()} VALUATION',
        onBack: () => Navigator.maybePop(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BatchGradeDetailHeader(
              metalType: metalType,
              batchCode: batchCode,
              grade: grade,
            ),
            const SizedBox(height: 16),
            _BatchGradeDetailPanel(
              title: 'Stock Valuation',
              metrics: [
                _DetailMetricData(
                  'Available Weight',
                  formatGram(grade.availableNetWeight),
                  MetalValuationColors.green,
                ),
                _DetailMetricData(
                  'Sold Weight',
                  formatGram(grade.soldNetWeight),
                  MetalValuationColors.red,
                ),
                _DetailMetricData(
                  'Total Weight',
                  formatGram(grade.totalNetWeight),
                  MetalValuationColors.goldDark,
                ),
                _DetailMetricData(
                  'Units',
                  '${grade.availableUnits} available / ${grade.soldUnits} sold',
                  MetalValuationColors.ink,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _BatchGradeDetailPanel(
              title: 'Cost Recovery',
              metrics: [
                _DetailMetricData(
                  'Available Cost',
                  formatMoney(grade.availableCost),
                  MetalValuationColors.ink,
                ),
                _DetailMetricData(
                  'Sold Cost',
                  formatMoney(grade.soldCost),
                  MetalValuationColors.ink,
                ),
                _DetailMetricData(
                  'Sale Value',
                  formatMoney(grade.saleValue),
                  MetalValuationColors.goldDark,
                ),
                _DetailMetricData(
                  'Profit',
                  formatMoney(grade.profit),
                  grade.profit >= 0
                      ? MetalValuationColors.green
                      : MetalValuationColors.red,
                ),
                _DetailMetricData(
                  'Margin',
                  formatPercent(grade.marginPercent),
                  grade.marginPercent >= 0
                      ? MetalValuationColors.green
                      : MetalValuationColors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchGradeDetailHeader extends StatelessWidget {
  final String metalType;
  final String batchCode;
  final MetalValuationGradeRow grade;

  const _BatchGradeDetailHeader({
    required this.metalType,
    required this.batchCode,
    required this.grade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF4BF), Color(0xFFE0B11F)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          MetalValuationMetalImage(
            metalType: metalType,
            borderColor: Colors.white,
            fallbackColor: MetalValuationColors.goldDark,
            size: 56,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleCase(grade.gradeLabel),
                  style: MetalValuationText.sectionTitle.copyWith(
                    color: const Color(0xFF3B2A08),
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$batchCode  |  ${titleCase(metalType)} batch grade valuation',
                  style: MetalValuationText.body.copyWith(
                    color: const Color(0xFF4B3A12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchGradeDetailPanel extends StatelessWidget {
  final String title;
  final List<_DetailMetricData> metrics;

  const _BatchGradeDetailPanel({
    required this.title,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: valuationPanelDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: MetalValuationText.sectionTitle),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 1000
                  ? (constraints.maxWidth - 30) / 4
                  : constraints.maxWidth >= 640
                      ? (constraints.maxWidth - 10) / 2
                      : constraints.maxWidth;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final metric in metrics)
                    SizedBox(
                      width: width,
                      child: _BatchGradeMetric(
                        label: metric.label,
                        value: metric.value,
                        color: metric.color,
                      ),
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

class _DetailMetricData {
  final String label;
  final String value;
  final Color color;

  const _DetailMetricData(this.label, this.value, this.color);
}

class _BatchGradeMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BatchGradeMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: MetalValuationText.label.copyWith(fontSize: 11)),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MetalValuationText.value.copyWith(
              color: color,
              fontSize: 19,
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchGradeFact extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _BatchGradeFact({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MetalValuationColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: MetalValuationText.label.copyWith(fontSize: 11)),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MetalValuationText.body.copyWith(
              color: color ?? MetalValuationColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchGradeLoadingPanel extends StatelessWidget {
  const _BatchGradeLoadingPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: valuationPanelDecoration(color: Colors.white),
      child: const Center(
        child: CircularProgressIndicator(
          color: MetalValuationColors.goldDark,
        ),
      ),
    );
  }
}

class _BatchGradeMessagePanel extends StatelessWidget {
  final String title;
  final String message;

  const _BatchGradeMessagePanel({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: valuationPanelDecoration(color: Colors.white),
      child: Column(
        children: [
          Text(title, style: MetalValuationText.sectionTitle),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: MetalValuationText.body.copyWith(
              color: MetalValuationColors.mutedInk,
            ),
          ),
        ],
      ),
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
                    label: 'Purity',
                    value: formatPercent(batch?.purityPercent ?? 0),
                    valueColor: MetalValuationColors.green,
                  ),
                  _HeaderMetric(
                    label: 'Wastage',
                    value: formatPercent(batch?.wastagePercent ?? 0),
                    valueColor: MetalValuationColors.blue,
                  ),
                  _HeaderMetric(
                    label: 'Valuation Purity',
                    value: formatPercent(batch?.valuationPurityPercent ?? 0),
                    valueColor: MetalValuationColors.goldDark,
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
