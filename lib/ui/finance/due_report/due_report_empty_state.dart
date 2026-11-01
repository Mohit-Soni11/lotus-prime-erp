import 'package:flutter/material.dart';

import '../../../theme/finance/due_report/due_report_theme.dart';

class DueReportEmptyState extends StatelessWidget {
  const DueReportEmptyState({
    super.key,
    required this.hasOutstandingBills,
    required this.onClearFilters,
  });

  final bool hasOutstandingBills;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final filtered = hasOutstandingBills;
    final accent = filtered ? DueReportColors.info : DueReportColors.success;
    final soft =
        filtered ? DueReportColors.infoSoft : DueReportColors.successSoft;

    return Container(
      width: double.infinity,
      decoration: DueReportStyles.panel(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withValues(alpha: 0.2)),
                ),
                child: Icon(
                  filtered ? Icons.search_off_rounded : DueReportIcons.empty,
                  color: accent,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                filtered
                    ? 'No matching due bills'
                    : 'All customer balances are clear',
                textAlign: TextAlign.center,
                style: DueReportStyles.sectionTitle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 7),
              Text(
                filtered
                    ? 'Try another search or clear the selected filter.'
                    : 'There are no outstanding sales bills to collect.',
                textAlign: TextAlign.center,
                style: DueReportStyles.label.copyWith(fontSize: 14),
              ),
              if (filtered) ...[
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                  label: const Text('Clear filters'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DueReportColors.textPrimary,
                    side: const BorderSide(color: DueReportColors.gold),
                    backgroundColor: DueReportColors.goldSoft,
                    textStyle: DueReportStyles.label.copyWith(fontSize: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
