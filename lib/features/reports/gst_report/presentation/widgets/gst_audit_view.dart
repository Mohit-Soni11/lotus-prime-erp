import 'package:flutter/material.dart';

import '../../domain/gst_audit_workspace_models.dart';
import '../../domain/gst_report_models.dart';
import '../gst_report_formatters.dart';
import '../theme/gst_report_theme.dart';
import 'gst_audit_action_panel.dart';
import 'gst_audit_control_board.dart';
import 'gst_audit_coverage_panel.dart';
import 'gst_audit_summary_cards.dart';
import 'gst_report_panel.dart';

class GstAuditView extends StatelessWidget {
  const GstAuditView({
    super.key,
    required this.snapshot,
  });

  final GstReportSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final audit = GstAuditWorkspaceSnapshot.fromReport(snapshot);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AuditStatusPanel(
          audit: audit,
          periodLabel: GstReportFormatters.periodLabel(snapshot.period),
        ),
        const SizedBox(height: 16),
        GstAuditSummaryCards(audit: audit),
        const SizedBox(height: 16),
        GstAuditControlBoard(items: audit.controlItems),
        const SizedBox(height: 16),
        GstAuditActionPanel(items: audit.actionItems),
        const SizedBox(height: 16),
        GstAuditCoveragePanel(items: audit.coverageItems),
      ],
    );
  }
}

class _AuditStatusPanel extends StatelessWidget {
  const _AuditStatusPanel({
    required this.audit,
    required this.periodLabel,
  });

  final GstAuditWorkspaceSnapshot audit;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    final accent =
        audit.isReadyForPortal ? GstReportColors.success : GstReportColors.danger;

    return GstReportPanel(
      title: 'GST Audit Command Center',
      subtitle: periodLabel,
      icon: GstReportIcons.audit,
      trailing: _ReadinessPill(
        label: audit.portalStatusLabel,
        accent: accent,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                audit.isReadyForPortal
                    ? Icons.verified_rounded
                    : Icons.priority_high_rounded,
                color: accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    audit.isReadyForPortal
                        ? 'This GST period is ready for portal review.'
                        : 'Resolve critical issues before filing this GST period.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GstReportStyles.body.copyWith(
                      color: GstReportColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Audit covers invoice tax snapshots, customer GSTIN, place of supply, HSN Table 12, GSTR-1 and GSTR-3B readiness.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GstReportStyles.body.copyWith(fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadinessPill extends StatelessWidget {
  const _ReadinessPill({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: GstReportStyles.body.copyWith(
          color: accent,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
