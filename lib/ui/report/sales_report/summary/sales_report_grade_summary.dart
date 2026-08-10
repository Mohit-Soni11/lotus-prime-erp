import 'package:flutter/material.dart';

import '../../../../logic/report/sales_report/sales_report_invoice_scope.dart';
import '../../../../models/reports/sales_report/sales_report_models.dart';
import '../../../../theme/reports/sales_report/sales_report_theme.dart';
import '../sales_report_formatters.dart';

const double _jewelleryGstRate = 0.03;
const String allSalesReportGrades = 'ALL';

class SalesReportGradeSummaryPanel extends StatelessWidget {
  final List<SalesReportInvoiceRow> invoices;
  final List<SalesReportItemRow> items;
  final String selectedGrade;
  final ValueChanged<String> onGradeSelected;

  const SalesReportGradeSummaryPanel({
    super.key,
    required this.invoices,
    required this.items,
    required this.selectedGrade,
    required this.onGradeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final summaries = buildSalesReportGradeSummaries(
      invoices: invoices,
      items: items,
    );
    if (summaries.isEmpty) return const SizedBox.shrink();

    final visibleSummaries = selectedGrade == allSalesReportGrades
        ? summaries
        : summaries
            .where((summary) => summary.grade == selectedGrade)
            .toList(growable: false);

    return Container(
      decoration: SalesReportStyles.panel(),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_graph_rounded,
                  color: SalesReportColors.brandGold,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grade Wise Sales',
                        style:
                            SalesReportStyles.pageTitle.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Invoice count, pieces, net weight, sale value and GST view',
                        style: SalesReportStyles.body,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _GradeChip(
                  label: 'All Grades',
                  selected: selectedGrade == allSalesReportGrades,
                  onTap: () => onGradeSelected(allSalesReportGrades),
                ),
                for (final summary in summaries)
                  _GradeChip(
                    label: summary.grade,
                    selected: selectedGrade == summary.grade,
                    onTap: () => onGradeSelected(summary.grade),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1180
                    ? 3
                    : constraints.maxWidth >= 760
                        ? 2
                        : 1;
                const spacing = 12.0;
                final width =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final summary in visibleSummaries)
                      SizedBox(
                        width: width,
                        child: _GradeSummaryCard(summary: summary),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

List<SalesReportGradeSummary> buildSalesReportGradeSummaries({
  required List<SalesReportInvoiceRow> invoices,
  required List<SalesReportItemRow> items,
}) {
  final totals = <String, _GradeAccumulator>{};

  for (final item in items) {
    final grade = _gradeLabel(item.purity);
    final acc = totals.putIfAbsent(grade, _GradeAccumulator.new);
    acc.invoiceIds.add(item.billId);
    acc.itemCount++;
    acc.pieces += item.quantity;
    acc.netWeight += item.netWeight;
    acc.saleAmount += item.itemTotal;
    if (!item.isGst) {
      acc.projectedGstAmount += item.itemTotal * _jewelleryGstRate;
    }
  }

  for (final entry in totals.entries) {
    final gradeItems = items
        .where((item) => _gradeLabel(item.purity) == entry.key)
        .toList(growable: false);
    final gradeInvoices = scopeSalesReportInvoicesToItems(
      invoices: invoices,
      items: gradeItems,
    );
    entry.value.recordedGstAmount = gradeInvoices.fold<double>(
      0,
      (total, invoice) => total + invoice.gstAmount,
    );
  }

  return totals.entries.map((entry) {
    final acc = entry.value;
    return SalesReportGradeSummary(
      grade: entry.key,
      invoiceCount: acc.invoiceIds.length,
      itemCount: acc.itemCount,
      pieces: acc.pieces,
      netWeight: acc.netWeight,
      saleAmount: acc.saleAmount,
      recordedGstAmount: acc.recordedGstAmount,
      projectedGstAmount: acc.projectedGstAmount,
    );
  }).toList()
    ..sort((a, b) => b.saleAmount.compareTo(a.saleAmount));
}

double salesReportRecordedGstForItems({
  required List<SalesReportInvoiceRow> invoices,
  required List<SalesReportItemRow> items,
}) {
  return scopeSalesReportInvoicesToItems(invoices: invoices, items: items)
      .fold<double>(0, (total, invoice) => total + invoice.gstAmount);
}

double salesReportProjectedGstForItems(List<SalesReportItemRow> items) {
  return items.where((item) => !item.isGst).fold<double>(
        0,
        (total, item) => total + item.itemTotal * _jewelleryGstRate,
      );
}

String _gradeLabel(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'UNSPECIFIED';
  return trimmed.toUpperCase();
}

class SalesReportGradeSummary {
  final String grade;
  final int invoiceCount;
  final int itemCount;
  final int pieces;
  final double netWeight;
  final double saleAmount;
  final double recordedGstAmount;
  final double projectedGstAmount;

  const SalesReportGradeSummary({
    required this.grade,
    required this.invoiceCount,
    required this.itemCount,
    required this.pieces,
    required this.netWeight,
    required this.saleAmount,
    required this.recordedGstAmount,
    required this.projectedGstAmount,
  });

  double get saleWithGstView =>
      saleAmount + recordedGstAmount + projectedGstAmount;
}

class _GradeAccumulator {
  final Set<int> invoiceIds = {};
  int itemCount = 0;
  int pieces = 0;
  double netWeight = 0;
  double saleAmount = 0;
  double recordedGstAmount = 0;
  double projectedGstAmount = 0;
}

class _GradeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GradeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      labelStyle: SalesReportStyles.body.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        color: selected
            ? SalesReportColors.textPrimary
            : SalesReportColors.textSecondary,
      ),
      selectedColor: SalesReportColors.brandGold.withValues(alpha: 0.18),
      backgroundColor: SalesReportColors.bodyPanel,
      side: BorderSide(
        color: selected
            ? SalesReportColors.brandGold.withValues(alpha: 0.45)
            : SalesReportColors.bodyBorder,
      ),
      onSelected: (_) => onTap(),
    );
  }
}

class _GradeSummaryCard extends StatelessWidget {
  final SalesReportGradeSummary summary;

  const _GradeSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SalesReportColors.bodySubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SalesReportColors.bodyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SalesReportColors.brandGold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  size: 18,
                  color: SalesReportColors.brandGold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${summary.grade} Grade',
                  style: SalesReportStyles.pageTitle.copyWith(fontSize: 17),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniMetric(label: 'Invoices', value: '${summary.invoiceCount}'),
              _MiniMetric(label: 'Pieces', value: '${summary.pieces}'),
              _MiniMetric(
                label: 'Net Weight',
                value: salesReportWeight(summary.netWeight),
              ),
              _MiniMetric(
                label: 'Sale Amount',
                value: salesReportMoney(summary.saleAmount),
              ),
              _MiniMetric(
                label: 'GST Total',
                value: salesReportMoney(summary.recordedGstAmount),
              ),
              _MiniMetric(
                label: 'Projected GST @3%',
                value: salesReportMoney(summary.projectedGstAmount),
              ),
              _MiniMetric(
                label: 'Sale + GST View',
                value: salesReportMoney(summary.saleWithGstView),
                emphasized: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _MiniMetric({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 118, minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: emphasized
            ? SalesReportColors.goldGradientStart.withValues(alpha: 0.13)
            : SalesReportColors.bodyPanel,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: emphasized
              ? SalesReportColors.brandGold.withValues(alpha: 0.35)
              : SalesReportColors.bodyBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SalesReportStyles.body.copyWith(
              fontSize: 10.5,
              color: SalesReportColors.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: SalesReportStyles.pageTitle.copyWith(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
