import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lotus_erp/constants/app_routes.dart';
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
    _controller = MetalValuationController(initialFilter: _filter)
      ..startLiveRefresh()
      ..load();
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
    final row = batch;
    final showSold = (row?.soldUnits ?? 0) > 0 || (row?.soldNetWeight ?? 0) > 0;
    return Container(
      decoration: valuationPanelDecoration(color: Colors.white),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: MetalValuationColors.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: MetalValuationColors.gold.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                MetalValuationMetalImage(
                  metalType: metalType,
                  borderColor: Colors.white,
                  fallbackColor: MetalValuationColors.goldDark,
                  size: 48,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Batch Valuation',
                        style: MetalValuationText.sectionTitle.copyWith(
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatDate(row?.createdAt)}  |  ${row?.supplierName ?? 'Not recorded'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MetalValuationText.body.copyWith(
                          color: MetalValuationColors.mutedInk,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: MetalValuationColors.line),
                      ),
                      child: Text(
                        batchCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MetalValuationText.label.copyWith(
                          color: MetalValuationColors.goldDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _BatchHeaderSection(
            title: 'Procurement Valuation',
            children: [
              _HeaderMetric(
                  label: 'Procured Units', value: '${row?.totalUnits ?? 0}'),
              _HeaderMetric(
                label: 'Procured Net Weight',
                value: formatGram(row?.totalNetWeight ?? 0),
                valueColor: MetalValuationColors.green,
              ),
              _HeaderMetric(
                label: 'Procurement Fine',
                value: formatGram(row?.valuationFineWeight ?? 0),
                valueColor: MetalValuationColors.goldDark,
              ),
              _HeaderMetric(
                label: 'Metal Rate',
                value: _batchRateLabel(row),
                valueColor: MetalValuationColors.goldDark,
              ),
              _HeaderMetric(
                label: 'Making Charges',
                value: formatMoney(row?.makingAmount ?? 0),
              ),
              _HeaderMetric(
                label: 'Procurement Cost',
                value: formatMoney(row?.totalCost ?? 0),
                valueColor: MetalValuationColors.goldDark,
              ),
            ],
          ),
          if (showSold) ...[
            const SizedBox(height: 12),
            _BatchHeaderSection(
              title: 'Sales Cost Recovery',
              children: [
                _HeaderMetric(
                    label: 'Sold Units', value: '${row?.soldUnits ?? 0}'),
                _HeaderMetric(
                  label: 'Sold Net Weight',
                  value: formatGram(row?.soldNetWeight ?? 0),
                  valueColor: MetalValuationColors.red,
                ),
                _HeaderMetric(
                  label: 'Recovered Fine',
                  value: formatGram(row?.soldValuationFineWeight ?? 0),
                  valueColor: MetalValuationColors.goldDark,
                ),
                _HeaderMetric(
                  label: 'Cost Basis',
                  value: formatMoney(row?.soldCost ?? 0),
                ),
                _HeaderMetric(
                  label: 'Sales Value',
                  value: formatMoney(row?.saleValue ?? 0),
                  valueColor: MetalValuationColors.goldDark,
                ),
                _HeaderMetric(
                  label: 'Gross Profit',
                  value: formatMoney(row?.profit ?? 0),
                  valueColor: (row?.profit ?? 0) >= 0
                      ? MetalValuationColors.green
                      : MetalValuationColors.red,
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _BatchHeaderSection(
            title: 'Closing Stock Valuation',
            children: [
              _HeaderMetric(
                label: 'Balance Units',
                value: '${row?.availableUnits ?? 0}',
              ),
              _HeaderMetric(
                label: 'Balance Net Weight',
                value: formatGram(row?.availableNetWeight ?? 0),
                valueColor: MetalValuationColors.green,
              ),
              _HeaderMetric(
                label: 'Balance Valuation Fine',
                value: formatGram(row?.availableValuationFineWeight ?? 0),
                valueColor: MetalValuationColors.goldDark,
              ),
              _HeaderMetric(
                label: 'Closing Stock Cost',
                value: formatMoney(row?.availableCost ?? 0),
                valueColor: MetalValuationColors.goldDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BatchHeaderSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _BatchHeaderSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MetalValuationColors.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MetalValuationColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: MetalValuationText.sectionTitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 640
                  ? 2
                  : constraints.maxWidth < 1040
                      ? 3
                      : 6;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: columns,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: columns == 2 ? 3.0 : 3.8,
                children: children,
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

String _batchRateLabel(BatchValuationRow? row) {
  if (row == null || row.ratePerGram <= 0) return formatMoney(0);
  if (row.rateVariantCount > 1) return 'Mixed rates';
  return '${formatMoney(row.ratePerGram)}/g';
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
