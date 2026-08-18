import 'package:flutter/material.dart';

import '../../domain/gst_filing_period.dart';
import '../../domain/gst_quarter_filing_ledger.dart';
import '../gst_report_formatters.dart';
import '../theme/gst_report_theme.dart';

class GstQuarterFinalSettlementCard extends StatelessWidget {
  const GstQuarterFinalSettlementCard({
    super.key,
    required this.ledger,
    required this.stateCode,
  });

  final GstQuarterFilingLedger ledger;
  final String stateCode;

  @override
  Widget build(BuildContext context) {
    final filing = ledger.filing;
    final closingMonth = ledger.closingMonth;
    final balance =
        ledger.balanceTaxLiability < 0 ? 0.0 : ledger.balanceTaxLiability;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GstReportColors.warning.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: GstReportColors.warning.withValues(alpha: 0.20),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 920;
          final header = _SettlementHeader(
            filing: filing,
            closingMonth: closingMonth,
            stateCode: stateCode,
          );
          final formula = _SettlementFormula(
            quarterTax: ledger.quarterTaxLiability,
            paidTax: ledger.paidTaxSnapshot,
            balanceTax: balance,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: 12),
                formula,
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: header),
              const SizedBox(width: 14),
              Expanded(flex: 5, child: formula),
            ],
          );
        },
      ),
    );
  }
}

class _SettlementHeader extends StatelessWidget {
  const _SettlementHeader({
    required this.filing,
    required this.closingMonth,
    required this.stateCode,
  });

  final GstFilingPeriod filing;
  final GstQuarterFilingMonthLedger closingMonth;
  final String stateCode;

  @override
  Widget build(BuildContext context) {
    final finalFilingMonth = DateTime(
      filing.quarterEndMonth.year,
      filing.quarterEndMonth.month + 1,
    );

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: GstReportColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(
            Icons.calculate_outlined,
            color: GstReportColors.warning,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Final 3B Settlement',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GstReportStyles.body.copyWith(
                  color: GstReportColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${GstReportFormatters.monthYear(finalFilingMonth)} filing includes ${GstReportFormatters.monthYear(closingMonth.filing.month)} closing month.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GstReportStyles.body.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(
                'GSTR-1 ${GstReportFormatters.date(filing.gstr1QuarterDueDate)} | GSTR-3B ${GstReportFormatters.date(filing.gstr3bDueDateForStateCode(stateCode))}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GstReportStyles.body.copyWith(
                  color: GstReportColors.textPrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettlementFormula extends StatelessWidget {
  const _SettlementFormula({
    required this.quarterTax,
    required this.paidTax,
    required this.balanceTax,
  });

  final double quarterTax;
  final double paidTax;
  final double balanceTax;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 580) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FormulaChip(
                width: constraints.maxWidth,
                label: 'Quarter GST',
                value: GstReportFormatters.money(quarterTax),
                accent: GstReportColors.information,
              ),
              _FormulaChip(
                width: constraints.maxWidth,
                label: 'Less PMT-06 Paid',
                value: GstReportFormatters.money(paidTax),
                accent: GstReportColors.success,
              ),
              _FormulaChip(
                width: constraints.maxWidth,
                label: 'Final 3B Balance',
                value: GstReportFormatters.money(balanceTax),
                accent: GstReportColors.warning,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _FormulaChip(
                label: 'Quarter GST',
                value: GstReportFormatters.money(quarterTax),
                accent: GstReportColors.information,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.remove_rounded,
              color: GstReportColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FormulaChip(
                label: 'PMT-06 Paid',
                value: GstReportFormatters.money(paidTax),
                accent: GstReportColors.success,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.drag_handle_rounded,
              color: GstReportColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FormulaChip(
                label: 'Final 3B Balance',
                value: GstReportFormatters.money(balanceTax),
                accent: GstReportColors.warning,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FormulaChip extends StatelessWidget {
  const _FormulaChip({
    required this.label,
    required this.value,
    required this.accent,
    this.width,
  });

  final String label;
  final String value;
  final Color accent;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: GstReportColors.bodyPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GstReportStyles.body.copyWith(
              color: GstReportColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GstReportStyles.body.copyWith(
              color: GstReportColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
