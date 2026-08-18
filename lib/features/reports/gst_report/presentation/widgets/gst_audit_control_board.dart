import 'package:flutter/material.dart';

import '../../domain/gst_audit_workspace_models.dart';
import '../theme/gst_report_theme.dart';
import 'gst_report_panel.dart';

class GstAuditControlBoard extends StatelessWidget {
  const GstAuditControlBoard({
    super.key,
    required this.items,
  });

  final List<GstAuditControlItem> items;

  @override
  Widget build(BuildContext context) {
    return GstReportPanel(
      title: 'Filing Control Board',
      subtitle: 'Module-level readiness for return preparation',
      icon: Icons.rule_folder_outlined,
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
                  child: _ControlTile(item: item),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ControlTile extends StatelessWidget {
  const _ControlTile({required this.item});

  final GstAuditControlItem item;

  @override
  Widget build(BuildContext context) {
    final accent = _statusColor(item.status);
    return Container(
      height: 142,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_statusIcon(item.status), color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GstReportStyles.body.copyWith(
                    color: GstReportColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusPill(status: item.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GstReportStyles.body.copyWith(fontSize: 12.5),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _MetricChip(
                  label: item.primaryMetric,
                  accent: accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricChip(
                  label: item.secondaryMetric,
                  accent: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: GstReportColors.bodyPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GstReportStyles.body.copyWith(
          color: GstReportColors.textPrimary,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final GstAuditControlStatus status;

  @override
  Widget build(BuildContext context) {
    final accent = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Text(
        _statusLabel(status),
        style: GstReportStyles.body.copyWith(
          color: accent,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
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
      return Icons.check_circle_outline_rounded;
    case GstAuditControlStatus.review:
      return Icons.manage_search_rounded;
    case GstAuditControlStatus.blocked:
      return Icons.error_outline_rounded;
  }
}

String _statusLabel(GstAuditControlStatus status) {
  switch (status) {
    case GstAuditControlStatus.clear:
      return 'Clear';
    case GstAuditControlStatus.review:
      return 'Review';
    case GstAuditControlStatus.blocked:
      return 'Blocked';
  }
}
