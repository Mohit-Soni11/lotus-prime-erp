import 'package:flutter/material.dart';

import '../../domain/gst_audit_workspace_models.dart';
import '../gst_report_formatters.dart';
import '../theme/gst_report_theme.dart';
import 'gst_report_metric_card.dart';

class GstAuditSummaryCards extends StatelessWidget {
  const GstAuditSummaryCards({
    super.key,
    required this.audit,
  });

  static const double _cardHeight = 132;

  final GstAuditWorkspaceSnapshot audit;

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
            _MetricBox(
              width: width,
              child: GstReportMetricCard(
                title: 'Critical Issues',
                value: GstReportFormatters.count(audit.criticalCount),
                subtitle: audit.criticalCount == 0
                    ? 'No filing blocker'
                    : 'Must fix before filing',
                icon: Icons.error_outline_rounded,
                accentColor: audit.criticalCount == 0
                    ? GstReportColors.success
                    : GstReportColors.danger,
              ),
            ),
            _MetricBox(
              width: width,
              child: GstReportMetricCard(
                title: 'Review Warnings',
                value: GstReportFormatters.count(audit.warningCount),
                subtitle: audit.warningCount == 0
                    ? 'No manual review'
                    : 'Verify before portal entry',
                icon: Icons.warning_amber_rounded,
                accentColor: audit.warningCount == 0
                    ? GstReportColors.success
                    : GstReportColors.warning,
              ),
            ),
            _MetricBox(
              width: width,
              child: GstReportMetricCard(
                title: 'Passed Controls',
                value: GstReportFormatters.count(audit.passedCount),
                subtitle: 'Automated GST checks clear',
                icon: Icons.verified_rounded,
                accentColor: GstReportColors.success,
              ),
            ),
            _MetricBox(
              width: width,
              child: GstReportMetricCard(
                title: 'Output GST Liability',
                value: GstReportFormatters.money(audit.outputGstLiability),
                subtitle: audit.portalStatusLabel,
                icon: Icons.account_balance_wallet_outlined,
                accentColor: audit.isReadyForPortal
                    ? GstReportColors.taxGreen
                    : GstReportColors.danger,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.width,
    required this.child,
  });

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: GstAuditSummaryCards._cardHeight,
      child: child,
    );
  }
}
