part of '../girvi_list_screen.dart';

class _DetailTicketHeader extends StatelessWidget {
  final String ticketNo;
  final String customerName;
  final String customerMeta;

  const _DetailTicketHeader({
    required this.ticketNo,
    required this.customerName,
    required this.customerMeta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Row(
        children: [
          const _LedgerIconBox(
            icon: GirviIcons.customer,
            color: GirviColors.info,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticketNo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GirviStyles.ticketNumber,
                ),
                const SizedBox(height: 4),
                Text(
                  customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: GirviColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  customerMeta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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

class _SettlementFocusBlock extends StatelessWidget {
  final String totalPayable;
  final String principalDue;
  final String interestDue;
  final Color totalPayableColor;
  final Color principalDueColor;
  final Color interestDueColor;

  const _SettlementFocusBlock({
    required this.totalPayable,
    required this.principalDue,
    required this.interestDue,
    required this.totalPayableColor,
    required this.principalDueColor,
    required this.interestDueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: totalPayableColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: totalPayableColor.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net Payable',
            style: GoogleFonts.inter(
              color: GirviColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              totalPayable,
              style: GoogleFonts.manrope(
                color: totalPayableColor,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniSettlementValue(
                  label: 'Principal',
                  value: principalDue,
                  color: principalDueColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniSettlementValue(
                  label: 'Interest',
                  value: interestDue,
                  color: interestDueColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniSettlementValue extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniSettlementValue({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: GirviColors.textDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.manrope(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTimelinePanel extends StatelessWidget {
  final String startDate;
  final String maturityDate;
  final String lastInterestPaid;
  final String statusTitle;
  final String statusValue;
  final Color statusColor;

  const _AccountTimelinePanel({
    required this.startDate,
    required this.maturityDate,
    required this.lastInterestPaid,
    required this.statusTitle,
    required this.statusValue,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final timelineStatus = _splitTimelineStatus(statusValue);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _LedgerIconBox(
                icon: GirviIcons.info,
                color: GirviColors.info,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Timeline',
                      style: GoogleFonts.manrope(
                        color: GirviColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Key dates and current account age',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: GirviColors.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 330;
              final tileWidth = twoColumns
                  ? (constraints.maxWidth - 10) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: tileWidth,
                    child: _TimelineValueTile(
                      icon: Icons.event_available_rounded,
                      label: 'Start Date',
                      value: startDate,
                      color: GirviColors.info,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _TimelineValueTile(
                      icon: Icons.event_rounded,
                      label: 'Maturity Date',
                      value: maturityDate,
                      color: GirviColors.brandGold,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _TimelineValueTile(
                      icon: Icons.payments_rounded,
                      label: 'Last Interest',
                      value: lastInterestPaid,
                      color: GirviColors.success,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _TimelineValueTile(
                      icon: Icons.update_rounded,
                      label: statusTitle,
                      valueLines: timelineStatus.lines,
                      color: statusColor,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static _TimelineValueParts _splitTimelineStatus(String value) {
    final deliveryMatch = RegExp(
      r'^(Ready since|Delivered on|Released on) (.+)$',
    ).firstMatch(value);
    if (deliveryMatch != null) {
      return _TimelineValueParts.fromLines([
        deliveryMatch.group(1)!,
        deliveryMatch.group(2)!,
      ]);
    }

    final ageMatch = RegExp(
      r'^(?:(\d+ years?) )?(?:(\d+ months?) )?(?:(\d+ days?))$',
    ).firstMatch(value);
    if (ageMatch == null) return _TimelineValueParts(value);
    final parts = <String>[
      if (ageMatch.group(1) != null) ageMatch.group(1)!,
      if (ageMatch.group(2) != null) ageMatch.group(2)!,
      if (ageMatch.group(3) != null) ageMatch.group(3)!,
    ];
    return _TimelineValueParts.fromLines(parts);
  }
}

class _TimelineValueParts {
  final List<String> lines;

  _TimelineValueParts(String value) : lines = <String>[value];

  const _TimelineValueParts.fromLines(this.lines);
}

class _TimelineValueTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<String> valueLines;
  final Color color;

  _TimelineValueTile({
    required this.icon,
    required this.label,
    String? value,
    List<String>? valueLines,
    required this.color,
  })  : assert(value != null || valueLines != null),
        valueLines = valueLines ?? <String>[value!];

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                for (var index = 0;
                    index < valueLines.length && index < 3;
                    index++) ...[
                  if (index > 0) const SizedBox(height: 1),
                  Text(
                    valueLines[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      color: color,
                      fontSize: 14,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
