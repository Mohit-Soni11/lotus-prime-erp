import 'package:flutter/material.dart';

import '../../domain/gstr3b_filing_models.dart';
import '../../domain/gst_report_models.dart';
import '../gst_report_formatters.dart';
import '../theme/gst_report_theme.dart';
import 'gst_report_metric_card.dart';
import 'gstr3b_filing_sections.dart';
import 'gstr3b_portal_verification_panel.dart';

class Gstr3bSummaryView extends StatelessWidget {
  const Gstr3bSummaryView({
    super.key,
    required this.snapshot,
  });

  final GstReportSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final filing = Gstr3bFilingSnapshot.fromReport(snapshot);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Gstr3bExecutiveSummary(filing: filing),
        const SizedBox(height: 16),
        Gstr3bReadinessPanel(readiness: filing.readiness),
        const SizedBox(height: 16),
        Gstr3bPortalVerificationPanel(notes: filing.portalNotes),
        const SizedBox(height: 16),
        Gstr3bTable31Panel(rows: filing.table31Rows),
        const SizedBox(height: 16),
        Gstr3bTable32Panel(rows: filing.table32Rows),
        const SizedBox(height: 16),
        Gstr3bItcPanel(rows: filing.itcRows),
        const SizedBox(height: 16),
        Gstr3bExemptInwardPanel(rows: filing.exemptInwardRows),
        const SizedBox(height: 16),
        Gstr3bPaymentPanel(rows: filing.paymentRows),
        const SizedBox(height: 16),
        const Gstr3bFilingChecklistPanel(),
      ],
    );
  }
}

class _Gstr3bExecutiveSummary extends StatelessWidget {
  const _Gstr3bExecutiveSummary({required this.filing});

  static const double _cardHeight = 140;

  final Gstr3bFilingSnapshot filing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 1200
            ? (constraints.maxWidth - 42) / 4
            : constraints.maxWidth >= 760
                ? (constraints.maxWidth - 14) / 2
                : constraints.maxWidth;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _SummaryBox(
              width: width,
              child: GstReportMetricCard(
                title: 'Outward Taxable Value',
                value: GstReportFormatters.money(filing.outwardTaxableValue),
                subtitle: 'Table 3.1(a)',
                icon: Icons.trending_up_rounded,
                accentColor: GstReportColors.information,
              ),
            ),
            _SummaryBox(
              width: width,
              child: GstReportMetricCard(
                title: 'Output GST Liability',
                value: GstReportFormatters.money(filing.outputTax),
                subtitle: 'Before purchase ITC',
                icon: Icons.account_balance_wallet_outlined,
                accentColor: GstReportColors.danger,
              ),
            ),
            _SummaryBox(
              width: width,
              child: GstReportMetricCard(
                title: 'ITC Applied',
                value: GstReportFormatters.money(0),
                subtitle: 'Manual until purchase module',
                icon: Icons.inventory_2_outlined,
                accentColor: GstReportColors.warning,
              ),
            ),
            _SummaryBox(
              width: width,
              child: GstReportMetricCard(
                title: 'Cash Payable',
                value: GstReportFormatters.money(filing.netCashPayable),
                subtitle: 'Portal ledger finalizes',
                icon: Icons.payments_outlined,
                accentColor: GstReportColors.taxGreen,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({
    required this.width,
    required this.child,
  });

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: _Gstr3bExecutiveSummary._cardHeight,
      child: child,
    );
  }
}
