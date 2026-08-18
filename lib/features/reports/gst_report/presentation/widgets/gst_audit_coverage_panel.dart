import 'package:flutter/material.dart';

import '../../domain/gst_audit_workspace_models.dart';
import '../theme/gst_report_theme.dart';
import 'gst_report_panel.dart';

class GstAuditCoveragePanel extends StatelessWidget {
  const GstAuditCoveragePanel({
    super.key,
    required this.items,
  });

  final List<GstAuditCoverageItem> items;

  @override
  Widget build(BuildContext context) {
    return GstReportPanel(
      title: 'Audit Coverage',
      subtitle: 'Automated checks covered before GSTR filing',
      icon: Icons.security_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth >= 1200
              ? (constraints.maxWidth - 24) / 3
              : constraints.maxWidth >= 760
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final item in items)
                SizedBox(
                  width: width,
                  child: _CoverageTile(item: item),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CoverageTile extends StatelessWidget {
  const _CoverageTile({required this.item});

  final GstAuditCoverageItem item;

  @override
  Widget build(BuildContext context) {
    final accent = _statusColor(item.status);
    return Container(
      height: 98,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: GstReportColors.bodySubtle,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_statusIcon(item.status), color: accent, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                const SizedBox(height: 5),
                Text(
                  item.note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GstReportStyles.body.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(_statusBadgeIcon(item.status), color: accent, size: 18),
        ],
      ),
    );
  }
}

Color _statusColor(GstAuditControlStatus status) {
  switch (status) {
    case GstAuditControlStatus.clear:
      return GstReportColors.success;
    case GstAuditControlStatus.review:
      return GstReportColors.warning;
    case GstAuditControlStatus.blocked:
      return GstReportColors.danger;
  }
}

IconData _statusIcon(GstAuditControlStatus status) {
  switch (status) {
    case GstAuditControlStatus.clear:
      return Icons.verified_user_outlined;
    case GstAuditControlStatus.review:
      return Icons.manage_search_rounded;
    case GstAuditControlStatus.blocked:
      return Icons.report_problem_outlined;
  }
}

IconData _statusBadgeIcon(GstAuditControlStatus status) {
  switch (status) {
    case GstAuditControlStatus.clear:
      return Icons.check_circle_rounded;
    case GstAuditControlStatus.review:
      return Icons.info_outline_rounded;
    case GstAuditControlStatus.blocked:
      return Icons.cancel_rounded;
  }
}
