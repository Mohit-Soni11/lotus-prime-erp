part of '../girvi_list_screen.dart';

extension _GirviLedgerFormatters on _GirviListScreenState {
  String _money(double value, {bool precise = false}) {
    final formatter = precise ? _preciseMoneyFormat : _moneyFormat;
    return 'Rs ${formatter.format(value)}';
  }

  String _date(DateTime? value) {
    if (value == null) return 'Not set';
    return _dateFormat.format(value);
  }

  String _compactCustomerLocation(GirviLoanWithCustomer item) {
    final city = item.customerCity?.trim();
    if (city == null || city.isEmpty) return item.customerMobile;
    return '${item.customerMobile} | $city';
  }

  String _ticketTimelineTitle(GirviLoanModel loan) {
    return switch (loan.girviStatus) {
      GirviStatus.readyForDelivery || GirviStatus.released => 'Delivery Status',
      _ => 'Account Age',
    };
  }

  String _ticketTimelineValue(GirviLoanModel loan) {
    if (loan.girviStatus == GirviStatus.readyForDelivery) {
      final readyDate = loan.releaseDate ?? loan.updatedAt;
      return readyDate == null
          ? 'Ready for Delivery'
          : 'Ready since ${_date(readyDate)}';
    }
    if (loan.girviStatus == GirviStatus.released) {
      final deliveredDate = loan.deliveredAt ?? loan.releaseDate;
      return deliveredDate == null
          ? 'Delivered'
          : 'Delivered on ${_date(deliveredDate)}';
    }
    if (loan.releaseDate != null) {
      return 'Released on ${_date(loan.releaseDate)}';
    }
    final today = DateUtils.dateOnly(DateTime.now());
    final startDate = DateUtils.dateOnly(loan.startDate);
    final accountAge = GirviLoanModel.elapsedPeriodBetween(startDate, today);
    return _durationLabel(accountAge);
  }

  Color _ticketTimelineColor(
    GirviLoanModel loan, {
    bool hasDueAmount = false,
  }) {
    if (loan.girviStatus == GirviStatus.readyForDelivery ||
        loan.girviStatus == GirviStatus.released) {
      return GirviColors.success;
    }
    return (loan.isOverdue || hasDueAmount)
        ? GirviColors.danger
        : GirviColors.textDark;
  }

  String _durationLabel(GirviElapsedPeriod period) {
    if (period.isZero) return '0 days';
    final parts = <String>[
      if (period.years > 0)
        '${period.years} year${period.years == 1 ? '' : 's'}',
      if (period.months > 0)
        '${period.months} month${period.months == 1 ? '' : 's'}',
      if (period.days > 0) '${period.days} day${period.days == 1 ? '' : 's'}',
    ];
    return parts.join(' ');
  }

  Color _dueAmountColor(double value) {
    return value > 0.005 ? GirviColors.danger : GirviColors.success;
  }

  Color _filterColor(GirviFilter filter) {
    switch (filter) {
      case GirviFilter.all:
        return GirviColors.brandGold;
      case GirviFilter.active:
        return GirviColors.success;
      case GirviFilter.overdue:
        return GirviColors.danger;
      case GirviFilter.readyForDelivery:
        return GirviColors.info;
      case GirviFilter.released:
        return GirviColors.statusReleased;
    }
  }

  IconData _filterIcon(GirviFilter filter) {
    switch (filter) {
      case GirviFilter.all:
        return GirviIcons.list;
      case GirviFilter.active:
        return GirviIcons.active;
      case GirviFilter.overdue:
        return GirviIcons.overdue;
      case GirviFilter.readyForDelivery:
        return GirviIcons.markDone;
      case GirviFilter.released:
        return GirviIcons.released;
    }
  }

  IconData _loanStatusIcon(GirviLoanModel loan) {
    switch (loan.girviStatus) {
      case GirviStatus.active:
        return loan.isOverdue ? GirviIcons.overdue : GirviIcons.active;
      case GirviStatus.overdue:
        return GirviIcons.overdue;
      case GirviStatus.partialRelease:
        return GirviIcons.release;
      case GirviStatus.readyForDelivery:
        return GirviIcons.markDone;
      case GirviStatus.released:
        return GirviIcons.released;
      case GirviStatus.auctioned:
        return GirviIcons.released;
    }
  }
}

class _GirviLedgerLoadingState extends StatelessWidget {
  const _GirviLedgerLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: GirviColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GirviColors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: GirviColors.brandGold,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Loading Pledge Ledger',
              style: GoogleFonts.manrope(
                color: GirviColors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GirviLedgerErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _GirviLedgerErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: GirviColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GirviColors.dangerBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: GirviColors.danger,
              size: 38,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: GirviColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(GirviIcons.refresh, size: 18),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: GirviColors.brandGold,
                foregroundColor: GirviColors.shellBg,
                textStyle: GoogleFonts.manrope(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _LedgerSurface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: GirviColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

class _LedgerSectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _LedgerSectionHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LedgerIconBox(icon: icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GirviStyles.sectionTitle),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: GirviColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _LedgerIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _LedgerIconBox({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _LedgerStatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _LedgerStatusBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _LedgerEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LedgerIconBox(icon: icon, color: GirviColors.textHint),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.manrope(
                color: GirviColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: GirviColors.textMuted,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
