import 'package:flutter/material.dart';

import '../../domain/gstr3b_filing_models.dart';
import '../theme/gst_report_theme.dart';
import 'gst_report_panel.dart';

class Gstr3bPortalVerificationPanel extends StatelessWidget {
  const Gstr3bPortalVerificationPanel({
    super.key,
    required this.notes,
  });

  final List<Gstr3bPortalVerificationNote> notes;

  @override
  Widget build(BuildContext context) {
    return GstReportPanel(
      title: 'Portal Verification Notes',
      subtitle: 'Not counted as audit warnings; verify these only during final filing',
      icon: Icons.info_outline_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth >= 980
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;
          final height = constraints.maxWidth >= 980 ? 198.0 : 228.0;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var index = 0; index < notes.length; index++)
                SizedBox(
                  width: width,
                  height: height,
                  child: _PortalNoteTile(
                    note: notes[index],
                    index: index,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PortalNoteTile extends StatelessWidget {
  const _PortalNoteTile({
    required this.note,
    required this.index,
  });

  final Gstr3bPortalVerificationNote note;
  final int index;

  @override
  Widget build(BuildContext context) {
    final accent = index.isEven
        ? GstReportColors.information
        : GstReportColors.taxGreen;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: GstReportColors.bodyPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        boxShadow: const [
          BoxShadow(
            color: GstReportColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            left: 0,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_iconFor(note.title), color: accent, size: 20),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GstReportStyles.body.copyWith(
                          color: GstReportColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(accent: accent),
                  ],
                ),
                const SizedBox(height: 12),
                _NoteLine(
                  label: 'When',
                  value: note.whenRequired,
                  accent: accent,
                ),
                const SizedBox(height: 9),
                _NoteLine(
                  label: 'Portal',
                  value: note.portalAction,
                  accent: accent,
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.055),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accent.withValues(alpha: 0.14)),
                  ),
                  child: Text(
                    note.erpStatus,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GstReportStyles.body.copyWith(
                      color: GstReportColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Text(
        'Portal Check',
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

class _NoteLine extends StatelessWidget {
  const _NoteLine({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GstReportStyles.body.copyWith(
              color: accent,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GstReportStyles.body.copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

IconData _iconFor(String title) {
  final value = title.toLowerCase();
  if (value.contains('itc') || value.contains('gstr-2b')) {
    return Icons.inventory_2_outlined;
  }
  return Icons.account_balance_wallet_outlined;
}
