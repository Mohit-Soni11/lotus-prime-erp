import 'package:flutter/material.dart';

import '../../domain/gstr1_filing_models.dart';
import '../theme/gst_report_theme.dart';
import 'gst_report_panel.dart';

class Gstr1PortalReadinessPanel extends StatelessWidget {
  const Gstr1PortalReadinessPanel({
    super.key,
    required this.readiness,
  });

  final Gstr1Readiness readiness;

  @override
  Widget build(BuildContext context) {
    final ready = readiness.isPortalReady;
    final accent = ready ? GstReportColors.success : GstReportColors.danger;

    return GstReportPanel(
      title: 'GSTR-1 Portal Readiness',
      subtitle: ready
          ? 'All mandatory outward-supply checks are clear'
          : 'Resolve blockers before generating portal upload data',
      icon: ready ? Icons.verified_rounded : Icons.error_outline_rounded,
      trailing: _ReadinessPill(
        label: ready ? 'Portal Ready' : 'Action Required',
        accent: accent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 720
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: width,
                    child: _ReadinessCounter(
                      title: 'Blocking Issues',
                      value: readiness.blockerCount,
                      accent: readiness.blockerCount == 0
                          ? GstReportColors.success
                          : GstReportColors.danger,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _ReadinessCounter(
                      title: 'Review Warnings',
                      value: readiness.warningCount,
                      accent: readiness.warningCount == 0
                          ? GstReportColors.success
                          : GstReportColors.warning,
                    ),
                  ),
                ],
              );
            },
          ),
          if (readiness.blockers.isNotEmpty ||
              readiness.warnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...readiness.blockers.map(
              (message) => _ReadinessMessage(
                message: message,
                accent: GstReportColors.danger,
                icon: Icons.priority_high_rounded,
              ),
            ),
            ...readiness.warnings.map(
              (message) => _ReadinessMessage(
                message: message,
                accent: GstReportColors.warning,
                icon: Icons.info_outline_rounded,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadinessCounter extends StatelessWidget {
  const _ReadinessCounter({
    required this.title,
    required this.value,
    required this.accent,
  });

  final String title;
  final int value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.fact_check_outlined, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GstReportStyles.body.copyWith(
                color: GstReportColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '$value',
            style: GstReportStyles.sectionTitle.copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}

class _ReadinessMessage extends StatelessWidget {
  const _ReadinessMessage({
    required this.message,
    required this.accent,
    required this.icon,
  });

  final String message;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GstReportStyles.body.copyWith(
                color: GstReportColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
