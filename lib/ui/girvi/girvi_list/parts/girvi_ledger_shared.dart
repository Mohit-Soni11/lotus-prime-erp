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

  String _maturityLabel(GirviLoanModel loan) {
    if (loan.releaseDate != null) {
      return 'Released ${_date(loan.releaseDate)}';
    }
    if (loan.maturityDate == null) return 'No maturity date';
    if (loan.isOverdue) return '${loan.daysToMaturity.abs()} days overdue';
    if (loan.daysToMaturity == 0) return 'Due today';
    return '${loan.daysToMaturity} days left';
  }

  Color _filterColor(GirviFilter filter) {
    switch (filter) {
      case GirviFilter.all:
        return GirviColors.brandGold;
      case GirviFilter.active:
        return GirviColors.success;
      case GirviFilter.overdue:
        return GirviColors.danger;
      case GirviFilter.settlementPending:
        return GirviColors.warning;
      case GirviFilter.readyForDelivery:
        return GirviColors.info;
      case GirviFilter.released:
        return GirviColors.statusReleased;
      case GirviFilter.auctioned:
        return GirviColors.statusAuctioned;
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
      case GirviFilter.settlementPending:
        return GirviIcons.release;
      case GirviFilter.readyForDelivery:
        return GirviIcons.markDone;
      case GirviFilter.released:
        return GirviIcons.released;
      case GirviFilter.auctioned:
        return GirviIcons.auctioned;
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
        return GirviIcons.auctioned;
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
              'Loading Girvi Ledger',
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
