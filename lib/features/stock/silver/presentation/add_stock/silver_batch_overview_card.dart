import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lotus_erp/features/stock/silver/application/silver_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_silver/silver_stock_theme.dart';

class SilverBatchOverviewCard extends StatelessWidget {
  final SilverStockController ctrl;

  const SilverBatchOverviewCard({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final createdAt = ctrl.batchCreatedAt;
    final grade = ctrl.purityDisplay.trim().isEmpty
        ? 'Grade Pending'
        : ctrl.purityDisplay.trim();
    final statusTone =
        ctrl.rowsWithErrorsCount > 0 ? SilverStockColors.danger : _gradeTone();
    final statusLabel = ctrl.rowsWithErrorsCount > 0
        ? 'Needs Review'
        : ctrl.enteredRowCount > 0
            ? 'In Progress'
            : 'Draft';

    return Container(
      decoration: BoxDecoration(
        color: SilverStockColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SilverStockColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: SilverStockColors.shadowLight,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: SilverStockColors.shadowMedium,
            blurRadius: 22,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Row(
                children: [
                  _HeaderIcon(tone: _gradeTone()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1. Batch Overview',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _titleStyle(14),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Silver intake - ${ctrl.enteredRowCount} entered row${ctrl.enteredRowCount == 1 ? '' : 's'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _bodyStyle(12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusPill(label: statusLabel, tone: statusTone),
                ],
              ),
            ),
            const Divider(height: 1, color: SilverStockColors.cardBorder),
            Padding(
              padding: const EdgeInsets.all(14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 820;
                  final metrics = [
                    _MetricData(
                      label: 'Batch Code',
                      value: ctrl.isLoadingBatchCode
                          ? '${ctrl.batchCode}...'
                          : ctrl.batchCode,
                      icon: SilverStockIcons.invoiceSystem,
                      tone: SilverStockColors.paymentPrimary,
                    ),
                    _MetricData(
                      label: 'Date',
                      value: DateFormat('dd MMM yyyy').format(createdAt),
                      icon: Icons.calendar_today_rounded,
                      tone: SilverStockColors.accentCompliance,
                    ),
                    _MetricData(
                      label: 'Time',
                      value: DateFormat('hh:mm a').format(createdAt),
                      icon: Icons.access_time_rounded,
                      tone: SilverStockColors.success,
                    ),
                    _MetricData(
                      label: 'Grade',
                      value: grade,
                      icon: _gradeIcon(),
                      tone: _gradeTone(),
                    ),
                    _MetricData(
                      label: 'Pieces',
                      value: '${ctrl.totalQuantity}',
                      icon: Icons.tag_rounded,
                      tone: SilverStockColors.accentInventory,
                    ),
                    _MetricData(
                      label: 'Gross Weight',
                      value: '${ctrl.totalGrossWeight.toStringAsFixed(3)} g',
                      icon: SilverStockIcons.weight,
                      tone: SilverStockColors.paymentPrimary,
                    ),
                    _MetricData(
                      label: 'Net Weight',
                      value: '${ctrl.totalNetWeight.toStringAsFixed(3)} g',
                      icon: SilverStockIcons.netWeight,
                      tone: SilverStockColors.success,
                    ),
                  ];

                  if (compact) {
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: metrics
                          .map(
                            (metric) => SizedBox(
                              width: (constraints.maxWidth - 10) / 2,
                              child: _MetricTile(data: metric),
                            ),
                          )
                          .toList(),
                    );
                  }

                  return Row(
                    children: [
                      for (var index = 0; index < metrics.length; index++) ...[
                        Expanded(child: _MetricTile(data: metrics[index])),
                        if (index != metrics.length - 1) const _MetricDivider(),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _gradeIcon() {
    final normalized = ctrl.purityDisplay.trim().toUpperCase();
    if (normalized.contains('925') || normalized.contains('92.5')) {
      return Icons.verified_rounded;
    }
    if (normalized.contains('999') || normalized.contains('99.9')) {
      return Icons.workspace_premium_rounded;
    }
    if (normalized.contains('800') || normalized.contains('80')) {
      return Icons.temple_hindu_rounded;
    }
    if (normalized.contains('700') || normalized.contains('70')) {
      return Icons.soup_kitchen_rounded;
    }
    if (normalized.isNotEmpty) {
      return Icons.business_center_rounded;
    }
    return SilverStockIcons.stockModule;
  }

  Color _gradeTone() {
    final normalized = ctrl.purityDisplay.trim().toUpperCase();
    if (normalized.contains('925') || normalized.contains('92.5')) {
      return const Color(0xFF0F8A72);
    }
    if (normalized.contains('800') || normalized.contains('80')) {
      return const Color(0xFF8B5CF6);
    }
    if (normalized.contains('700') || normalized.contains('70')) {
      return const Color(0xFF2563EB);
    }
    if (normalized.isNotEmpty &&
        !(normalized.contains('999') || normalized.contains('99.9'))) {
      return SilverStockColors.textMuted;
    }
    return SilverStockColors.brandSilver;
  }
}

class _MetricData {
  final String label;
  final String value;
  final IconData icon;
  final Color tone;

  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });
}

class _MetricTile extends StatelessWidget {
  final _MetricData data;

  const _MetricTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: data.tone.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: data.tone.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: data.tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(data.icon, color: data.tone, size: 15),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _labelStyle(),
                ),
                const SizedBox(height: 4),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _valueStyle(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final Color tone;

  const _HeaderIcon({required this.tone});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: tone.withValues(alpha: 0.20)),
      ),
      child: Icon(Icons.receipt_long_rounded, color: tone, size: 18),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color tone;

  const _StatusPill({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: tone,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 46,
      margin: const EdgeInsets.symmetric(horizontal: 7),
      color: SilverStockColors.cardBorder,
    );
  }
}

TextStyle _titleStyle(double size) {
  return GoogleFonts.manrope(
    fontSize: size,
    fontWeight: FontWeight.w900,
    color: SilverStockColors.textDark,
  );
}

TextStyle _bodyStyle(double size) {
  return GoogleFonts.inter(
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: SilverStockColors.textBody,
  );
}

TextStyle _labelStyle() {
  return GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.5,
    color: SilverStockColors.textMuted,
  );
}

TextStyle _valueStyle() {
  return GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w900,
    color: SilverStockColors.textDark,
  );
}
