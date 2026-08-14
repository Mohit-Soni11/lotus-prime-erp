import 'package:flutter/material.dart';

import '../../domain/gst_report_models.dart';
import '../theme/gst_report_theme.dart';

class GstReportNavigationTabs extends StatelessWidget {
  const GstReportNavigationTabs({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final GstReportTab selectedTab;
  final ValueChanged<GstReportTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: GstReportColors.bodyPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GstReportColors.bodyBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;
          return Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tab in GstReportTab.values)
                SizedBox(
                  width: compact
                      ? (constraints.maxWidth - 6) / 2
                      : (constraints.maxWidth - 24) / 5,
                  child: _TabButton(
                    tab: tab,
                    selected: selectedTab == tab,
                    onPressed: () => onTabSelected(tab),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.selected,
    required this.onPressed,
  });

  final GstReportTab tab;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      height: 44,
      decoration: BoxDecoration(
        color: selected ? GstReportColors.taxGreen : GstReportColors.bodySubtle,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color:
              selected ? GstReportColors.taxGreen : GstReportColors.bodyBorder,
        ),
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(
          _iconFor(tab),
          size: 18,
          color: selected ? Colors.white : GstReportColors.textSecondary,
        ),
        label: Text(
          _labelFor(tab),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: TextButton.styleFrom(
          foregroundColor:
              selected ? Colors.white : GstReportColors.textPrimary,
          textStyle: GstReportStyles.body.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 12.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
    );
  }

  static IconData _iconFor(GstReportTab tab) {
    switch (tab) {
      case GstReportTab.dashboard:
        return GstReportIcons.dashboard;
      case GstReportTab.gstr1:
        return GstReportIcons.gstr1;
      case GstReportTab.gstr3b:
        return GstReportIcons.gstr3b;
      case GstReportTab.hsnRegister:
        return GstReportIcons.hsn;
      case GstReportTab.audit:
        return GstReportIcons.audit;
    }
  }

  static String _labelFor(GstReportTab tab) {
    switch (tab) {
      case GstReportTab.dashboard:
        return 'Dashboard';
      case GstReportTab.gstr1:
        return 'GSTR-1';
      case GstReportTab.gstr3b:
        return 'GSTR-3B';
      case GstReportTab.hsnRegister:
        return 'HSN Register';
      case GstReportTab.audit:
        return 'Audit';
    }
  }
}
