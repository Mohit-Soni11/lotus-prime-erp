import 'package:flutter/material.dart';

import '../../domain/gst_filing_period.dart';
import '../../domain/gst_quarter_filing_ledger.dart';
import '../../domain/gst_report_models.dart';
import '../gst_report_formatters.dart';
import '../theme/gst_report_theme.dart';
import 'gst_quarter_final_settlement_card.dart';
import 'gst_report_panel.dart';

class GstQuarterFilingLedgerPanel extends StatelessWidget {
  const GstQuarterFilingLedgerPanel({
    super.key,
    required this.ledger,
    required this.stateCode,
  });

  final GstQuarterFilingLedger ledger;
  final String stateCode;

  @override
  Widget build(BuildContext context) {
    final filing = ledger.filing;
    return GstReportPanel(
      title: 'Quarter Payment & Filing Ledger',
      subtitle:
          '${filing.financialYearLabel} | ${filing.quarterLabel} ${filing.quarterRangeLabel}',
      icon: Icons.account_balance_wallet_outlined,
      trailing: _QuarterStatusPill(status: ledger.quarterReturnStatus),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _QuarterSummaryStrip(ledger: ledger, stateCode: stateCode),
          const SizedBox(height: 12),
          GstQuarterFinalSettlementCard(
            ledger: ledger,
            stateCode: stateCode,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 1180
                  ? (constraints.maxWidth - 24) / 3
                  : constraints.maxWidth >= 760
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final month in ledger.months)
                    SizedBox(
                      width: width,
                      child: _MonthLedgerCard(month: month),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _QuarterCloseCard(ledger: ledger, stateCode: stateCode),
        ],
      ),
    );
  }
}

class _QuarterSummaryStrip extends StatelessWidget {
  const _QuarterSummaryStrip({
    required this.ledger,
    required this.stateCode,
  });

  final GstQuarterFilingLedger ledger;
  final String stateCode;

  @override
  Widget build(BuildContext context) {
    final dueDate = ledger.filing.gstr3bDueDateForStateCode(stateCode);
    final balance =
        ledger.balanceTaxLiability < 0 ? 0.0 : ledger.balanceTaxLiability;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 940
            ? (constraints.maxWidth - 30) / 4
            : constraints.maxWidth >= 560
                ? (constraints.maxWidth - 10) / 2
                : constraints.maxWidth;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SummaryChip(
              width: width,
              label: 'Quarter GST Liability',
              value: GstReportFormatters.money(ledger.quarterTaxLiability),
            ),
            _SummaryChip(
              width: width,
              label: 'PMT-06 Paid Snapshot',
              value: GstReportFormatters.money(ledger.paidTaxSnapshot),
              accent: GstReportColors.success,
            ),
            _SummaryChip(
              width: width,
              label: 'Final 3B Balance',
              value: GstReportFormatters.money(balance),
              accent: GstReportColors.warning,
            ),
            _SummaryChip(
              width: width,
              label: 'Quarter Final Due',
              value: GstReportFormatters.date(dueDate),
              accent: GstReportColors.taxGreen,
            ),
          ],
        );
      },
    );
  }
}

class _MonthLedgerCard extends StatelessWidget {
  const _MonthLedgerCard({required this.month});

  final GstQuarterFilingMonthLedger month;

  @override
  Widget build(BuildContext context) {
    final filing = month.filing;
    return Container(
      height: 244,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isSelectedMonth(filing)
            ? GstReportColors.taxGreen.withValues(alpha: 0.065)
            : GstReportColors.bodySubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isSelectedMonth(filing)
              ? GstReportColors.taxGreen.withValues(alpha: 0.24)
              : GstReportColors.bodyBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: GstReportColors.taxGreen.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${filing.monthPositionInQuarter}',
                  style: GstReportStyles.body.copyWith(
                    color: GstReportColors.taxGreen,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      GstReportFormatters.monthYear(filing.month),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GstReportStyles.body.copyWith(
                        color: GstReportColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _monthSubtitle(month),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GstReportStyles.body.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LedgerLine(
            title: 'PMT-06 Monthly Payment',
            value: month.hasMonthlyPayment
                ? GstReportFormatters.money(_monthlyAmount(month))
                : 'Not required',
            note: month.hasMonthlyPayment
                ? 'Due ${GstReportFormatters.date(filing.monthlyTaxPaymentDueDate)}'
                : 'Settled through final GSTR-3B',
            status: month.hasMonthlyPayment
                ? month.monthlyPaymentStatus
                : null,
          ),
          const SizedBox(height: 8),
          _LedgerLine(
            title:
                filing.iffDueDate == null ? 'Quarter Return' : 'IFF B2B Optional',
            value: filing.iffDueDate == null
                ? 'Final month'
                : '${month.b2bInvoiceCount} B2B | ${GstReportFormatters.money(month.b2bTaxLiability)}',
            note: filing.iffDueDate == null
                ? 'GSTR-1 filed after quarter close'
                : 'Due ${GstReportFormatters.date(filing.iffDueDate!)}',
            status: filing.iffDueDate == null ? null : month.b2bIffStatus,
          ),
          const Spacer(),
          _SegmentStatusStrip(month: month),
        ],
      ),
    );
  }

  String _monthSubtitle(GstQuarterFilingMonthLedger month) {
    final base =
        '${month.invoiceCount} invoices | ${GstReportFormatters.money(month.taxLiability)} GST';
    if (!month.filing.isQuarterClosingMonth) return base;
    return '$base | closing month';
  }

  double _monthlyAmount(GstQuarterFilingMonthLedger month) {
    return month.monthlyPaymentStatus.completed
        ? month.monthlyPaymentStatus.amountSnapshot
        : month.taxLiability;
  }

  bool _isSelectedMonth(GstFilingPeriod filing) {
    final now = DateTime.now();
    return filing.month.year == now.year && filing.month.month == now.month;
  }
}

class _QuarterCloseCard extends StatelessWidget {
  const _QuarterCloseCard({
    required this.ledger,
    required this.stateCode,
  });

  final GstQuarterFilingLedger ledger;
  final String stateCode;

  @override
  Widget build(BuildContext context) {
    final filing = ledger.filing;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GstReportColors.taxGreen.withValues(alpha: 0.065),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: GstReportColors.taxGreen.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GstReportColors.taxGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.fact_check_rounded,
              color: GstReportColors.taxGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quarter Final Filing',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GstReportStyles.body.copyWith(
                    color: GstReportColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'GSTR-1 due ${GstReportFormatters.date(filing.gstr1QuarterDueDate)} | GSTR-3B due ${GstReportFormatters.date(filing.gstr3bDueDateForStateCode(stateCode))}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GstReportStyles.body.copyWith(fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _StatusPill(
            status: ledger.quarterReturnStatus,
            fallbackLabel: 'Pending',
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.width,
    required this.label,
    required this.value,
    this.accent = GstReportColors.information,
  });

  final double width;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GstReportStyles.body.copyWith(
              color: GstReportColors.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GstReportStyles.body.copyWith(
              color: GstReportColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerLine extends StatelessWidget {
  const _LedgerLine({
    required this.title,
    required this.value,
    required this.note,
    required this.status,
  });

  final String title;
  final String value;
  final String note;
  final GstFilingTaskStatus? status;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GstReportStyles.body.copyWith(
                    color: GstReportColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GstReportStyles.body.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GstReportStyles.body.copyWith(
                  color: GstReportColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              if (status == null)
                Text(
                  'Info',
                  style: GstReportStyles.body.copyWith(
                    color: GstReportColors.information,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                )
              else
                _StatusPill(status: status!, compact: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentStatusStrip extends StatelessWidget {
  const _SegmentStatusStrip({required this.month});

  final GstQuarterFilingMonthLedger month;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatus(
            label: 'B2B',
            completed: month.b2bReturnStatus.completed,
            count: month.b2bInvoiceCount,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStatus(
            label: 'B2C',
            completed: month.b2cReturnStatus.completed,
            count: month.b2cInvoiceCount,
          ),
        ),
      ],
    );
  }
}

class _MiniStatus extends StatelessWidget {
  const _MiniStatus({
    required this.label,
    required this.completed,
    required this.count,
  });

  final String label;
  final bool completed;
  final int count;

  @override
  Widget build(BuildContext context) {
    final color = completed ? GstReportColors.success : GstReportColors.textMuted;
    return Container(
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        completed ? '$label Filed' : '$label $count inv',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GstReportStyles.body.copyWith(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _QuarterStatusPill extends StatelessWidget {
  const _QuarterStatusPill({required this.status});

  final GstFilingTaskStatus status;

  @override
  Widget build(BuildContext context) {
    return _StatusPill(status: status, fallbackLabel: 'Quarter Pending');
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.status,
    this.compact = false,
    this.fallbackLabel = 'Pending',
  });

  final GstFilingTaskStatus status;
  final bool compact;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final completed = status.completed;
    final color = completed ? GstReportColors.success : GstReportColors.warning;
    final label = completed ? 'Done' : fallbackLabel;
    final date = status.completedAt;
    final text = completed && date != null && !compact
        ? 'Done ${GstReportFormatters.date(date)}'
        : label;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GstReportStyles.body.copyWith(
          color: color,
          fontSize: compact ? 10.5 : 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
