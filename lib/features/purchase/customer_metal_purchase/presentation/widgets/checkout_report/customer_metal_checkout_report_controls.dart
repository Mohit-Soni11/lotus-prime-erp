part of '../../screens/customer_metal_checkout_report_screen.dart';

class _CheckoutReportControls extends StatelessWidget {
  final VoidCallback? onPrint;
  final int selectedYear;
  final int selectedMonth;
  final _CheckoutMonthSummary selectedSummary;
  final String periodRangeLabel;
  final VoidCallback onChangePeriod;

  const _CheckoutReportControls({
    required this.onPrint,
    required this.selectedYear,
    required this.selectedMonth,
    required this.selectedSummary,
    required this.periodRangeLabel,
    required this.onChangePeriod,
  });

  @override
  Widget build(BuildContext context) {
    final lineLabel = selectedSummary.lineCount == 1 ? 'line' : 'lines';
    final batchLabel = selectedSummary.batchCount == 1 ? 'batch' : 'batches';

    return CustomerMetalPurchaseFilterSurface(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 780;
          final titleBlock = Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: PurchaseEntryColors.purchaseAccent
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: PurchaseEntryColors.purchaseAccent,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report Controls',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                        color: PurchaseEntryColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_monthName(selectedMonth)} $selectedYear | ${selectedSummary.lineCount} $lineLabel | ${selectedSummary.batchCount} $batchLabel | $periodRangeLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final controls = Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _ControlActionButton(
                icon: Icons.calendar_month_rounded,
                label: '${_monthName(selectedMonth)} $selectedYear',
                onPressed: onChangePeriod,
                trailingIcon: Icons.keyboard_arrow_down_rounded,
              ),
              _ControlActionButton(
                icon: Icons.print_rounded,
                label: 'Download Report',
                onPressed: onPrint,
                filled: true,
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleBlock,
                const SizedBox(height: 12),
                controls,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 18),
              controls,
            ],
          );
        },
      ),
    );
  }
}

class _ControlActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final bool filled;

  const _ControlActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.trailingIcon,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 42),
          backgroundColor: PurchaseEntryColors.purchaseAccent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE5E0D8),
          disabledForegroundColor: Colors.black54,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 42),
        foregroundColor: Colors.black,
        backgroundColor:
            PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.08),
        side: BorderSide(
          color: PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.38),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: PurchaseEntryColors.purchaseAccent),
          const SizedBox(width: 8),
          Text(label),
          if (trailingIcon != null) ...[
            const SizedBox(width: 7),
            Icon(trailingIcon, size: 18, color: Colors.black),
          ],
        ],
      ),
    );
  }
}
