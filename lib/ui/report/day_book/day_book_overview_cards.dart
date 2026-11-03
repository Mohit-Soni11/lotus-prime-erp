import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/reports/day_book/day_book_models.dart';
import '../../../models/reports/day_book/day_book_overview_metrics.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';

class DayBookOverviewCards extends StatelessWidget {
  const DayBookOverviewCards({super.key, required this.summary});

  final DayBookSummary summary;

  @override
  Widget build(BuildContext context) {
    final metrics = DayBookOverviewMetrics.fromSummary(summary);
    final primary = [
      _OverviewCardData(
        title: 'Total Sales',
        value: _currency(metrics.totalSales),
        detail: 'Regular + tax invoice value',
        icon: DayBookIcons.sales,
        accent: DayBookColors.information,
        tint: DayBookColors.informationSoft,
      ),
      _OverviewCardData(
        title: 'Sales Collected',
        value: _currency(metrics.salesCollection),
        detail: "Posted receipts for today's invoices",
        icon: DayBookIcons.cashIn,
        accent: DayBookColors.positive,
        tint: DayBookColors.positiveSoft,
      ),
      _OverviewCardData(
        title: 'Counter Cash',
        value: _currency(metrics.closingCounterCash),
        detail: 'Opening + cash in − cash out',
        icon: DayBookIcons.closingBalance,
        accent: DayBookColors.goldMetal,
        tint: DayBookColors.brandGoldSoft,
      ),
    ];
    final secondary = [
      _OverviewCardData(
        title: 'Opening Cash',
        value: _currency(metrics.openingCounterCash),
        detail: 'Start of day',
        icon: DayBookIcons.openingBalance,
        accent: DayBookColors.information,
        tint: DayBookColors.informationSoft,
      ),
      _OverviewCardData(
        title: 'Regular Invoices',
        value: _currency(metrics.regularInvoiceValue),
        detail: '${metrics.regularInvoiceCount} issued',
        icon: DayBookIcons.regularInvoice,
        accent: DayBookColors.purple,
        tint: DayBookColors.purpleSoft,
      ),
      _OverviewCardData(
        title: 'Tax Invoices',
        value: _currency(metrics.taxInvoiceValue),
        detail: '${metrics.taxInvoiceCount} issued',
        icon: DayBookIcons.taxInvoice,
        accent: DayBookColors.goldMetal,
        tint: DayBookColors.goldMetalSoft,
      ),
      _OverviewCardData(
        title: 'GST Invoice Collection',
        value: _currency(metrics.gstInvoiceCollection),
        detail: 'Invoice tax: ${_currency(metrics.invoiceTax)}',
        icon: DayBookIcons.tax,
        accent: DayBookColors.positive,
        tint: DayBookColors.positiveSoft,
      ),
      _OverviewCardData(
        title: 'Due Collection',
        value: _currency(metrics.dueCollection),
        detail: 'Older invoices received today',
        icon: DayBookIcons.dueCollection,
        accent: DayBookColors.upiMode,
        tint: DayBookColors.informationSoft,
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final primaryColumns = width >= 900
          ? 3
          : width >= 560
              ? 2
              : 1;
      final secondaryColumns = width >= 1200
          ? 5
          : width >= 800
              ? 3
              : width >= 520
                  ? 2
                  : 1;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardRow(items: primary, columns: primaryColumns, prominent: true),
          const SizedBox(height: 10),
          _CardRow(items: secondary, columns: secondaryColumns),
        ],
      );
    });
  }
}

String _currency(double value) {
  return NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: value == value.roundToDouble() ? 0 : 2,
  ).format(value);
}

class _CardRow extends StatelessWidget {
  const _CardRow({
    required this.items,
    required this.columns,
    this.prominent = false,
  });

  final List<_OverviewCardData> items;
  final int columns;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const gap = 10.0;
      final cardWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final item in items)
            SizedBox(
              width: cardWidth,
              child: _OverviewCard(data: item, prominent: prominent),
            ),
        ],
      );
    });
  }
}

class _OverviewCardData {
  const _OverviewCardData({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.accent,
    required this.tint,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color accent;
  final Color tint;
}

class _OverviewCard extends StatefulWidget {
  const _OverviewCard({required this.data, required this.prominent});

  final _OverviewCardData data;
  final bool prominent;

  @override
  State<_OverviewCard> createState() => _OverviewCardState();
}

class _OverviewCardState extends State<_OverviewCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration:
            reducedMotion ? Duration.zero : const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        constraints: BoxConstraints(minHeight: widget.prominent ? 126 : 118),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DayBookColors.bodyPanel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered
                ? data.accent.withValues(alpha: 0.55)
                : DayBookColors.bodyBorder,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  DayBookColors.shadow.withValues(alpha: _hovered ? 1 : 0.55),
              blurRadius: _hovered ? 18 : 9,
              offset: Offset(0, _hovered ? 6 : 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: data.tint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(data.icon, size: 19, color: data.accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    data.title,
                    maxLines: 2,
                    style: DayBookStyles.labelStrong.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: DayBookColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: widget.prominent ? 30 : 26,
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  data.value,
                  style: DayBookStyles.valueLarge.copyWith(
                    fontSize: widget.prominent ? 25 : 20,
                    color: DayBookColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              data.detail,
              maxLines: 2,
              style: DayBookStyles.label.copyWith(
                fontSize: 12.5,
                color: DayBookColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
