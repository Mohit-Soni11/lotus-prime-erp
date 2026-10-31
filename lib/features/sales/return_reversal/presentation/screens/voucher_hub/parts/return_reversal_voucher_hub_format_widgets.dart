part of '../../return_reversal_voucher_preview_screen.dart';

class _ShellSectionLabel extends StatelessWidget {
  final String label;

  const _ShellSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: SalesPosColors.shellTextMuted,
        fontSize: SalesPosStyles.fontCaption,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }
}

class _FormatIcon extends StatelessWidget {
  final PrintFormat format;

  const _FormatIcon({required this.format});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: SalesPosColors.brandGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SalesPosColors.brandGold.withValues(alpha: 0.28),
        ),
      ),
      child: Icon(format.icon, color: SalesPosColors.brandGold, size: 20),
    );
  }
}

class _ShellChangeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ShellChangeButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: SalesPosColors.brandGold.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: SalesPosColors.brandGold.withValues(alpha: 0.32),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: SalesPosColors.brandGold,
                fontSize: SalesPosStyles.fontCaption,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: SalesPosColors.brandGold,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatDetailPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FormatDetailPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: SalesPosColors.shellBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SalesPosColors.shellBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: SalesPosColors.shellTextMuted, size: 14),
          const SizedBox(width: 7),
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

class _DocumentChoiceSurface extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _DocumentChoiceSurface({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = enabled
        ? (selected ? SalesPosColors.brandGold : SalesPosColors.shellTextMuted)
        : SalesPosColors.shellTextMuted.withValues(alpha: 0.42);
    return Tooltip(
      message: enabled ? title : 'Sales invoice source required',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 70),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? SalesPosColors.brandGold.withValues(alpha: 0.11)
                : SalesPosColors.shellBg
                    .withValues(alpha: enabled ? 0.58 : 0.30),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? SalesPosColors.brandGold
                  : SalesPosColors.shellBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 19),
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
                      style: TextStyle(
                        color: enabled
                            ? SalesPosColors.shellTextTitle
                            : SalesPosColors.shellTextMuted,
                        fontSize: SalesPosStyles.fontLabel,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: enabled
                            ? SalesPosColors.shellTextMuted
                            : SalesPosColors.shellTextMuted
                                .withValues(alpha: 0.58),
                        fontSize: SalesPosStyles.fontCaption,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : enabled
                        ? Icons.radio_button_unchecked_rounded
                        : Icons.lock_rounded,
                color: accent,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceMetalChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _InvoiceMetalChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        selected ? SalesPosColors.brandGold : SalesPosColors.shellTextMuted;
    return Tooltip(
      message: enabled ? '$label invoice' : 'Only one metal is available',
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? SalesPosColors.brandGold.withValues(alpha: 0.12)
                : SalesPosColors.shellBg.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected
                  ? SalesPosColors.brandGold
                  : SalesPosColors.shellBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: enabled
                      ? SalesPosColors.shellTextTitle
                      : SalesPosColors.shellTextMuted,
                  fontSize: SalesPosStyles.fontCaption,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrintIconTile extends StatelessWidget {
  const _PrintIconTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: SalesPosColors.brandGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SalesPosColors.brandGold.withValues(alpha: 0.28),
        ),
      ),
      child: const Icon(
        Icons.print_rounded,
        color: SalesPosColors.brandGold,
        size: 20,
      ),
    );
  }
}

class _PrintModeSelector extends StatelessWidget {
  const _PrintModeSelector({
    required this.value,
    required this.onChanged,
  });

  final LotusPrintColorMode value;
  final ValueChanged<LotusPrintColorMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: SalesPosColors.shellBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SalesPosColors.shellBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PrintModeOption(
            label: 'Colour',
            icon: Icons.palette_rounded,
            selected: value == LotusPrintColorMode.color,
            onTap: () => onChanged(LotusPrintColorMode.color),
          ),
          _PrintModeOption(
            label: 'B&W',
            icon: Icons.contrast_rounded,
            selected: value == LotusPrintColorMode.blackAndWhite,
            onTap: () => onChanged(LotusPrintColorMode.blackAndWhite),
          ),
        ],
      ),
    );
  }
}

class _PrintModeOption extends StatelessWidget {
  const _PrintModeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: selected ? SalesPosColors.brandGold : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.black : SalesPosColors.shellTextMuted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : SalesPosColors.shellTextMuted,
                fontSize: SalesPosStyles.fontCaption,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
