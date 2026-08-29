import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_controller.dart';
import 'package:lotus_erp/theme/purchase/purchase_entry/purchase_entry_theme.dart';

class CustomerMetalPurchaseMonthSelector extends StatelessWidget {
  final CustomerMetalPurchaseLedgerController controller;

  const CustomerMetalPurchaseMonthSelector({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final selectedDate = controller.startDate ?? DateTime(now.year, now.month);
    final selectedMonth = selectedDate.month;
    final selectedYear = selectedDate.year;
    final isCurrentMonth =
        selectedMonth == now.month && selectedYear == now.year;

    return SizedBox(
      width: 330,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _MonthNavButton(
                tooltip: 'Previous month',
                icon: Icons.chevron_left_rounded,
                onPressed: () => _navigateMonth(-1),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SelectedMonthTile(
                  label: '${_monthName(selectedMonth)} $selectedYear',
                  isCurrentMonth: isCurrentMonth,
                  onTap: isCurrentMonth
                      ? null
                      : () => controller.setMonthYear(
                            month: now.month,
                            year: now.year,
                          ),
                ),
              ),
              const SizedBox(width: 8),
              _MonthNavButton(
                tooltip: 'Next month',
                icon: Icons.chevron_right_rounded,
                onPressed: _canMoveNext(selectedDate, now)
                    ? () => _navigateMonth(1)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _CalendarPickerTile(
                  value: selectedMonth,
                  label: 'Month',
                  icon: Icons.calendar_month_rounded,
                  valueLabel: _monthName(selectedMonth),
                  onTap: () async {
                    final month = await _showMonthPicker(
                      context,
                      selectedMonth: selectedMonth,
                      selectedYear: selectedYear,
                      currentDate: now,
                    );
                    if (month != null && context.mounted) {
                      controller.setMonthYear(
                        month: month,
                        year: selectedYear,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 132,
                child: _CalendarPickerTile(
                  value: selectedYear,
                  label: 'Year',
                  icon: Icons.event_note_rounded,
                  valueLabel: selectedYear.toString(),
                  onTap: () async {
                    final year = await _showYearPicker(
                      context,
                      selectedYear: selectedYear,
                      currentYear: now.year,
                    );
                    if (year != null && context.mounted) {
                      final boundedMonth =
                          year == now.year && selectedMonth > now.month
                              ? now.month
                              : selectedMonth;
                      controller.setMonthYear(
                        month: boundedMonth,
                        year: year,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateMonth(int offset) {
    final now = DateTime.now();
    final current = controller.startDate ?? DateTime(now.year, now.month);
    final target = DateTime(current.year, current.month + offset, 1);
    controller.setMonthYear(month: target.month, year: target.year);
  }
}

class _CalendarPickerTile extends StatelessWidget {
  final int value;
  final String label;
  final String valueLabel;
  final IconData icon;
  final VoidCallback onTap;

  const _CalendarPickerTile({
    required this.value,
    required this.label,
    required this.valueLabel,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      value: '$value',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: PurchaseEntryColors.bodyBorder),
            ),
            child: Row(
              children: [
                Icon(icon, size: 17, color: PurchaseEntryColors.shellMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    valueLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                      color: PurchaseEntryColors.textMain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedMonthTile extends StatelessWidget {
  final String label;
  final bool isCurrentMonth;
  final VoidCallback? onTap;

  const _SelectedMonthTile({
    required this.label,
    required this.isCurrentMonth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 17,
                color: PurchaseEntryColors.purchaseAccent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    color: PurchaseEntryColors.textMain,
                  ),
                ),
              ),
              if (isCurrentMonth) const _CurrentBadge(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentBadge extends StatelessWidget {
  const _CurrentBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: PurchaseEntryColors.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Current',
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          color: PurchaseEntryColors.success,
        ),
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _MonthNavButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 42,
        height: 42,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: PurchaseEntryColors.textMain,
            disabledForegroundColor:
                PurchaseEntryColors.shellMuted.withValues(alpha: 0.45),
            backgroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFF3F4F6),
            side: BorderSide(
              color: onPressed == null
                  ? PurchaseEntryColors.bodyBorder.withValues(alpha: 0.65)
                  : PurchaseEntryColors.bodyBorder,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Icon(icon, size: 22),
        ),
      ),
    );
  }
}

List<int> _availableYears(int currentYear, int selectedYear) {
  final years = {
    selectedYear,
    for (var offset = 0; offset < 12; offset++) currentYear - offset,
  }.toList()
    ..sort((a, b) => b.compareTo(a));
  return years;
}

bool _canMoveNext(DateTime selectedDate, DateTime now) {
  if (selectedDate.year > now.year) {
    return false;
  }
  if (selectedDate.year == now.year && selectedDate.month >= now.month) {
    return false;
  }
  return true;
}

Future<int?> _showMonthPicker(
  BuildContext context, {
  required int selectedMonth,
  required int selectedYear,
  required DateTime currentDate,
}) {
  final maxMonth = selectedYear == currentDate.year ? currentDate.month : 12;
  return showDialog<int>(
    context: context,
    builder: (context) {
      return _CalendarGridDialog(
        title: 'Select Month',
        children: [
          for (var month = 1; month <= maxMonth; month++)
            _CalendarGridOption(
              label: _monthName(month).substring(0, 3),
              selected: month == selectedMonth,
              onTap: () => Navigator.pop(context, month),
            ),
        ],
      );
    },
  );
}

Future<int?> _showYearPicker(
  BuildContext context, {
  required int selectedYear,
  required int currentYear,
}) {
  return showDialog<int>(
    context: context,
    builder: (context) {
      return _CalendarGridDialog(
        title: 'Select Year',
        children: [
          for (final year in _availableYears(currentYear, selectedYear))
            _CalendarGridOption(
              label: year.toString(),
              selected: year == selectedYear,
              onTap: () => Navigator.pop(context, year),
            ),
        ],
      );
    },
  );
}

class _CalendarGridDialog extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _CalendarGridDialog({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: PurchaseEntryColors.purchaseAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                        color: PurchaseEntryColors.textMain,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.65,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: children,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarGridOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CalendarGridOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: selected
                ? PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.10)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? PurchaseEntryColors.purchaseAccent
                  : PurchaseEntryColors.bodyBorder,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                color: selected
                    ? PurchaseEntryColors.purchaseAccent
                    : PurchaseEntryColors.textMain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _monthName(int month) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return months[(month - 1).clamp(0, 11)];
}
