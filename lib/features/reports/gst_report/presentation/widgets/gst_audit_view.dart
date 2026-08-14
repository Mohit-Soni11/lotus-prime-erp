import 'package:flutter/material.dart';

import '../../domain/gst_report_models.dart';
import '../theme/gst_report_theme.dart';
import 'gst_report_panel.dart';

class GstAuditView extends StatelessWidget {
  const GstAuditView({
    super.key,
    required this.snapshot,
  });

  final GstReportSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final findings = snapshot.auditFindings;
    return GstReportPanel(
      title: 'GST Audit / Error Check',
      subtitle: 'Resolve critical findings before preparing return files',
      icon: GstReportIcons.audit,
      child: Column(
        children: [
          for (var index = 0; index < findings.length; index++) ...[
            _AuditTile(finding: findings[index]),
            if (index != findings.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.finding});

  final GstAuditFinding finding;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(finding.severity);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_iconFor(finding.severity), color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        finding.title,
                        style: GstReportStyles.body.copyWith(
                          color: GstReportColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (finding.invoiceNo.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      _InvoicePill(invoiceNo: finding.invoiceNo),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(finding.message, style: GstReportStyles.body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _colorFor(GstAuditSeverity severity) {
    switch (severity) {
      case GstAuditSeverity.critical:
        return GstReportColors.danger;
      case GstAuditSeverity.warning:
        return GstReportColors.warning;
      case GstAuditSeverity.info:
        return GstReportColors.success;
    }
  }

  static IconData _iconFor(GstAuditSeverity severity) {
    switch (severity) {
      case GstAuditSeverity.critical:
        return Icons.error_outline_rounded;
      case GstAuditSeverity.warning:
        return Icons.warning_amber_rounded;
      case GstAuditSeverity.info:
        return Icons.check_circle_outline_rounded;
    }
  }
}

class _InvoicePill extends StatelessWidget {
  const _InvoicePill({required this.invoiceNo});

  final String invoiceNo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: GstReportColors.bodyPanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GstReportColors.bodyBorder),
      ),
      child: Text(
        invoiceNo,
        style: GstReportStyles.body.copyWith(
          color: GstReportColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
