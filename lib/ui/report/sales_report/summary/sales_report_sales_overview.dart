import 'package:flutter/material.dart';

import '../../../../models/reports/sales_report/sales_report_models.dart';
import '../../../../theme/reports/sales_report/sales_report_theme.dart';
import '../sales_report_formatters.dart';

class SalesReportSalesOverview extends StatelessWidget {
  final SalesReportGstLiabilitySummary summary;
  final String periodLabel;
  static const Color _readableText = SalesReportColors.textPrimary;

  const SalesReportSalesOverview({
    super.key,
    required this.summary,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SalesReportColors.bodyPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: SalesReportColors.brandGold.withValues(alpha: 0.30),
        ),
        boxShadow: const [
          BoxShadow(
            color: SalesReportColors.shadow,
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: SalesReportColors.goldGradientStart
                      .withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: SalesReportColors.brandGold.withValues(alpha: 0.30),
                  ),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: SalesReportColors.brandGold,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sales Overview',
                      style: SalesReportStyles.pageTitle.copyWith(
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$periodLabel monthly normal, GST and due sales summary',
                      style: SalesReportStyles.body.copyWith(
                        color: _readableText,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _TotalBillsBadge(
                summary: summary,
                periodLabel: periodLabel,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = _buildCards(summary);
              final columns = constraints.maxWidth >= 1080
                  ? 3
                  : constraints.maxWidth >= 720
                      ? 2
                      : 1;
              const spacing = 10.0;
              final width =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final card in cards)
                    SizedBox(
                      width: width,
                      child: _SalesOverviewCard(card: card),
                    ),
                  if (cards.isEmpty) const _EmptySalesOverview(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<_SalesOverviewMetric> _buildCards(
    SalesReportGstLiabilitySummary summary,
  ) {
    final cards = <_SalesOverviewMetric>[];

    if (_hasValue(summary.nonGstSalesAmount) ||
        summary.nonGstInvoiceCount > 0) {
      cards.add(
        _SalesOverviewMetric(
          title: 'Normal Bill Sales',
          amount: salesReportMoney(summary.nonGstSalesAmount),
          detail: '${summary.nonGstInvoiceCount} normal bills',
          supportingTitle: _hasValue(summary.projectedGstAmount)
              ? 'Normal Bill GST Estimate'
              : null,
          supportingAmount: _hasValue(summary.projectedGstAmount)
              ? salesReportMoney(summary.projectedGstAmount)
              : null,
          supportingDetail: _hasValue(summary.projectedGstAmount)
              ? '${summary.projectedGstRatePercent.toStringAsFixed(2)}% planning estimate'
              : null,
          icon: Icons.receipt_rounded,
          accent: SalesReportColors.brandGold,
        ),
      );
    }

    if (_hasValue(summary.gstFinalAmount) || summary.gstInvoiceCount > 0) {
      cards.add(
        _SalesOverviewMetric(
          title: 'GST Bill Sales',
          amount: salesReportMoney(summary.gstFinalAmount),
          detail: '${summary.gstInvoiceCount} GST bills',
          supportingTitle:
              _hasValue(summary.recordedGstAmount) ? 'GST Collected' : null,
          supportingAmount: _hasValue(summary.recordedGstAmount)
              ? salesReportMoney(summary.recordedGstAmount)
              : null,
          supportingDetail: _hasValue(summary.gstTaxableAmount)
              ? 'Taxable sales ${salesReportMoney(summary.gstTaxableAmount)}'
              : null,
          icon: Icons.verified_rounded,
          accent: SalesReportColors.onlineGreen,
        ),
      );
    }

    if (_hasValue(summary.dueAmount)) {
      cards.add(
        _SalesOverviewMetric(
          title: 'Due Amount',
          amount: salesReportMoney(summary.dueAmount),
          detail: 'Pending from monthly sales',
          icon: Icons.pending_actions_rounded,
          accent: SalesReportColors.warning,
        ),
      );
    }

    return cards;
  }

  bool _hasValue(double value) => value.abs() > 0.005;
}

class _TotalBillsBadge extends StatelessWidget {
  final SalesReportGstLiabilitySummary summary;
  final String periodLabel;

  const _TotalBillsBadge({
    required this.summary,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SalesReportColors.brandGold.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: SalesReportColors.brandGold.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Total Bills',
            style: SalesReportStyles.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: SalesReportColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${summary.invoiceCount}',
            style: SalesReportStyles.pageTitle.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 1),
          Text(
            periodLabel,
            style: SalesReportStyles.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: SalesReportColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesOverviewMetric {
  final String title;
  final String amount;
  final String detail;
  final String? supportingTitle;
  final String? supportingAmount;
  final String? supportingDetail;
  final IconData icon;
  final Color accent;

  const _SalesOverviewMetric({
    required this.title,
    required this.amount,
    required this.detail,
    this.supportingTitle,
    this.supportingAmount,
    this.supportingDetail,
    required this.icon,
    required this.accent,
  });
}

class _SalesOverviewCard extends StatelessWidget {
  final _SalesOverviewMetric card;

  const _SalesOverviewCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card.accent.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: card.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(card.icon, color: card.accent, size: 23),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricBlock(
              title: card.title,
              amount: card.amount,
              detail: card.detail,
              alignment: CrossAxisAlignment.start,
              textAlign: TextAlign.left,
            ),
          ),
          if (card.supportingTitle != null &&
              card.supportingAmount != null) ...[
            const SizedBox(width: 12),
            Container(
              width: 1,
              height: 62,
              color: card.accent.withValues(alpha: 0.22),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: _MetricBlock(
                title: card.supportingTitle!,
                amount: card.supportingAmount!,
                detail: card.supportingDetail,
                alignment: CrossAxisAlignment.end,
                textAlign: TextAlign.right,
                compact: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  final String title;
  final String amount;
  final String? detail;
  final CrossAxisAlignment alignment;
  final TextAlign textAlign;
  final bool compact;

  const _MetricBlock({
    required this.title,
    required this.amount,
    this.detail,
    required this.alignment,
    required this.textAlign,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: alignment,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: SalesReportStyles.body.copyWith(
            fontSize: compact ? 12.5 : 13.5,
            fontWeight: FontWeight.w800,
            color: SalesReportColors.textPrimary,
          ),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment == CrossAxisAlignment.end
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Text(
            amount,
            style: SalesReportStyles.pageTitle.copyWith(
              fontSize: compact ? 18 : 21,
              color: SalesReportColors.textPrimary,
            ),
          ),
        ),
        if (detail != null) ...[
          const SizedBox(height: 3),
          Text(
            detail!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
            style: SalesReportStyles.body.copyWith(
              fontSize: compact ? 12 : 13,
              color: SalesReportColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptySalesOverview extends StatelessWidget {
  const _EmptySalesOverview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: SalesReportColors.bodySubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SalesReportColors.bodyBorder),
      ),
      child: Text(
        'No sales activity recorded for this month.',
        style: SalesReportStyles.body.copyWith(
          color: SalesReportColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
