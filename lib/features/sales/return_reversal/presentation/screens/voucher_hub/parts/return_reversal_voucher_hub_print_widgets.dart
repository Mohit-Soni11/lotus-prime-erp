part of '../../return_reversal_voucher_preview_screen.dart';

class _PrintControlSurface extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _PrintControlSurface({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SalesPosColors.shellBg.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SalesPosColors.shellBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: SalesPosColors.brandGold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SalesPosColors.shellTextTitle,
                    fontSize: SalesPosStyles.fontLabel,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SalesPosColors.shellTextMuted,
                    fontSize: SalesPosStyles.fontCaption,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _CopyStepper extends StatelessWidget {
  final int value;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _CopyStepper({
    required this.value,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: SalesPosColors.shellPanelBg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: SalesPosColors.shellBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            enabled: canDecrease,
            onTap: onDecrease,
          ),
          SizedBox(
            width: 38,
            child: Center(
              child: Text(
                '$value',
                style: const TextStyle(
                  color: SalesPosColors.brandGold,
                  fontSize: SalesPosStyles.fontInput,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            enabled: canIncrease,
            onTap: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: icon == Icons.add_rounded ? 'Add copy' : 'Remove copy',
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? SalesPosColors.brandGold
                : SalesPosColors.shellTextMuted.withValues(alpha: 0.38),
          ),
        ),
      ),
    );
  }
}

class _PrintStatusBadge extends StatelessWidget {
  final String label;
  final bool isActive;

  const _PrintStatusBadge({
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? SalesPosColors.brandGold.withValues(alpha: 0.14)
            : SalesPosColors.shellBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? SalesPosColors.brandGold.withValues(alpha: 0.34)
              : SalesPosColors.shellBorder,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive
              ? SalesPosColors.brandGold
              : SalesPosColors.shellTextMuted,
          fontSize: SalesPosStyles.fontCaption,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _PrintMetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PrintMetaPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: SalesPosColors.shellBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SalesPosColors.shellBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: SalesPosColors.brandGold, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SalesPosColors.shellTextTitle,
                fontSize: SalesPosStyles.fontCaption,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentFormatPickerPanel extends StatelessWidget {
  final PrintFormat selectedFormat;
  final String Function(PrintFormat) formatShortName;
  final String Function(PrintFormat) formatPaperSpec;
  final String Function(PrintFormat) formatUseCase;
  final ValueChanged<PrintFormat> onSelect;
  final VoidCallback onClose;

  const _DocumentFormatPickerPanel({
    required this.selectedFormat,
    required this.formatShortName,
    required this.formatPaperSpec,
    required this.formatUseCase,
    required this.onSelect,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final panelWidth = width < 560 ? width - 24 : 420.0;

    return Container(
      width: panelWidth,
      height: double.infinity,
      margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
      decoration: BoxDecoration(
        color: SalesPosColors.shellPanelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SalesPosColors.shellBorder),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 28,
            offset: Offset(-10, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: SalesPosColors.brandGold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.straighten_rounded,
                      color: SalesPosColors.brandGold,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DOCUMENT FORMAT',
                          style: TextStyle(
                            color: SalesPosColors.shellTextTitle,
                            fontSize: SalesPosStyles.fontInput,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Voucher paper and receipt layout',
                          style: TextStyle(
                            color: SalesPosColors.shellTextMuted,
                            fontSize: SalesPosStyles.fontCaption,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: SalesPosColors.shellTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: SalesPosColors.shellBorder, height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(14),
                itemBuilder: (context, index) {
                  final format = PrintFormat.values[index];
                  final selected = format == selectedFormat;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onSelect(format),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selected
                            ? SalesPosColors.brandGold.withValues(alpha: 0.10)
                            : SalesPosColors.shellBg.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? SalesPosColors.brandGold
                              : SalesPosColors.shellBorder,
                          width: selected ? 1.4 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          _FormatIcon(format: format),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  format.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: selected
                                        ? SalesPosColors.brandGold
                                        : SalesPosColors.shellTextTitle,
                                    fontSize: SalesPosStyles.fontLabel,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${formatPaperSpec(format)} - ${formatUseCase(format)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: SalesPosColors.shellTextMuted,
                                    fontSize: SalesPosStyles.fontCaption,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: selected
                                ? SalesPosColors.brandGold
                                : SalesPosColors.shellTextMuted,
                            size: 21,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemCount: PrintFormat.values.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const List<String> _monthShort = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];
