import 'package:flutter/material.dart';

import '../../domain/gst_audit_workspace_models.dart';
import '../../domain/gst_report_models.dart';
import '../theme/gst_report_theme.dart';
import 'gst_report_panel.dart';

class GstAuditActionPanel extends StatelessWidget {
  const GstAuditActionPanel({
    super.key,
    required this.items,
  });

  final List<GstAuditActionItem> items;

  @override
  Widget build(BuildContext context) {
    return GstReportPanel(
      title: 'Action Required',
      subtitle: items.isEmpty
          ? 'No blocking GST issue found for this filing period'
          : 'Fix these items before return filing or export',
      icon: Icons.task_alt_rounded,
      trailing: _TotalPill(count: items.length),
      child: items.isEmpty
          ? const GstReportEmptyState(
              message: 'All GST audit controls are clear for this period.',
              icon: Icons.verified_outlined,
            )
          : Column(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  _ActionTile(item: items[index]),
                  if (index != items.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.item});

  final GstAuditActionItem item;

  @override
  Widget build(BuildContext context) {
    final accent = _severityColor(item.severity);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(_severityIcon(item.severity), color: accent, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GstReportStyles.body.copyWith(
                    color: GstReportColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _ModulePill(label: item.module, accent: accent),
                    if (item.invoiceNo.isNotEmpty)
                      _InvoicePill(invoiceNo: item.invoiceNo),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  item.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GstReportStyles.body.copyWith(fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.arrow_forward_rounded, color: accent, size: 15),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.nextStep,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GstReportStyles.body.copyWith(
                          color: GstReportColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModulePill extends StatelessWidget {
  const _ModulePill({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GstReportStyles.body.copyWith(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InvoicePill extends StatelessWidget {
  const _InvoicePill({required this.invoiceNo});

  final String invoiceNo;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: GstReportColors.bodyPanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GstReportColors.bodyBorder),
      ),
      child: Text(
        invoiceNo,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GstReportStyles.body.copyWith(
          color: GstReportColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TotalPill extends StatelessWidget {
  const _TotalPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final accent = count == 0 ? GstReportColors.success : GstReportColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Text(
        count == 0 ? 'Clear' : '$count Open',
        style: GstReportStyles.body.copyWith(
          color: accent,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

Color _severityColor(GstAuditSeverity severity) {
  switch (severity) {
    case GstAuditSeverity.critical:
      return GstReportColors.danger;
    case GstAuditSeverity.warning:
      return GstReportColors.warning;
    case GstAuditSeverity.info:
      return GstReportColors.success;
  }
}

IconData _severityIcon(GstAuditSeverity severity) {
  switch (severity) {
    case GstAuditSeverity.critical:
      return Icons.error_outline_rounded;
    case GstAuditSeverity.warning:
      return Icons.warning_amber_rounded;
    case GstAuditSeverity.info:
      return Icons.check_circle_outline_rounded;
  }
}
