part of '../girvi_invoice_hub_screen.dart';

class _GirviDocumentFormatPickerPanel extends StatelessWidget {
  const _GirviDocumentFormatPickerPanel({
    required this.selectedFormat,
    required this.labelFor,
    required this.shortNameFor,
    required this.paperSpecFor,
    required this.useCaseFor,
    required this.onSelect,
    required this.onClose,
  });

  final GirviInvoiceFormat selectedFormat;
  final String Function(GirviInvoiceFormat) labelFor;
  final String Function(GirviInvoiceFormat) shortNameFor;
  final String Function(GirviInvoiceFormat) paperSpecFor;
  final String Function(GirviInvoiceFormat) useCaseFor;
  final ValueChanged<GirviInvoiceFormat> onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final panelWidth = width < 560 ? width - 24 : 420.0;

    return Container(
      width: panelWidth,
      height: double.infinity,
      margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
      decoration: BoxDecoration(
        color: GirviColors.shellPanelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GirviColors.shellBorder),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: GirviColors.brandGold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.print_rounded,
                      color: GirviColors.brandGold,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DOCUMENT FORMAT',
                          style: GoogleFonts.inter(
                            color: GirviColors.shellTextTitle,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Choose Girvi invoice paper and counter copy size',
                          style: GoogleFonts.inter(
                            color: GirviColors.shellTextMuted,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: GirviColors.shellTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: GirviColors.shellBorder, height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(14),
                itemBuilder: (context, index) {
                  final format = GirviInvoiceFormat.values[index];
                  return _GirviDocumentFormatOptionTile(
                    format: format,
                    selected: format == selectedFormat,
                    label: labelFor(format),
                    shortName: shortNameFor(format),
                    paperSpec: paperSpecFor(format),
                    useCase: useCaseFor(format),
                    onTap: () => onSelect(format),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemCount: GirviInvoiceFormat.values.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GirviDocumentFormatOptionTile extends StatelessWidget {
  const _GirviDocumentFormatOptionTile({
    required this.format,
    required this.selected,
    required this.label,
    required this.shortName,
    required this.paperSpec,
    required this.useCase,
    required this.onTap,
  });

  final GirviInvoiceFormat format;
  final bool selected;
  final String label;
  final String shortName;
  final String paperSpec;
  final String useCase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? GirviColors.brandGold.withValues(alpha: 0.10)
              : GirviColors.shellBg.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? GirviColors.brandGold : GirviColors.shellBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            _GirviFormatIcon(format: format),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: selected
                          ? GirviColors.brandGold
                          : GirviColors.shellTextTitle,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$shortName  |  $paperSpec  |  $useCase',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: GirviColors.shellTextMuted,
                      fontSize: 12.5,
                      height: 1.25,
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
              color:
                  selected ? GirviColors.brandGold : GirviColors.shellTextMuted,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}

class _GirviFormatIcon extends StatelessWidget {
  const _GirviFormatIcon({required this.format});

  final GirviInvoiceFormat format;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: GirviColors.brandGold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: GirviColors.brandGold.withValues(alpha: 0.28),
        ),
      ),
      child: Icon(
        format == GirviInvoiceFormat.a4
            ? Icons.description_outlined
            : Icons.view_compact_alt_rounded,
        color: GirviColors.brandGold,
        size: 21,
      ),
    );
  }
}

class _GirviFormatChangeButton extends StatelessWidget {
  const _GirviFormatChangeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: GirviColors.brandGold.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: GirviColors.brandGold.withValues(alpha: 0.32),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Change',
              style: GoogleFonts.inter(
                color: GirviColors.brandGold,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: GirviColors.brandGold,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _GirviMetaPill extends StatelessWidget {
  const _GirviMetaPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: GirviColors.shellBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.shellBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: GirviColors.shellTextMuted),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: GirviColors.shellTextTitle,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GirviPrintModeSelector extends StatelessWidget {
  const _GirviPrintModeSelector({
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
        color: GirviColors.shellBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GirviColors.shellBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GirviPrintModeOption(
            label: 'Colour',
            icon: Icons.palette_rounded,
            selected: value == LotusPrintColorMode.color,
            onTap: () => onChanged(LotusPrintColorMode.color),
          ),
          _GirviPrintModeOption(
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

class _GirviPrintModeOption extends StatelessWidget {
  const _GirviPrintModeOption({
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
          color: selected ? GirviColors.brandGold : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.black : GirviColors.shellTextMuted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                color: selected ? Colors.black : GirviColors.shellTextMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GirviPrintControlSurface extends StatelessWidget {
  const _GirviPrintControlSurface({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: GirviColors.shellBg.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GirviColors.shellBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: GirviColors.brandGold, size: 18),
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
                  style: GoogleFonts.inter(
                    color: GirviColors.shellTextTitle,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.shellTextMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
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

class _GirviCopyStepper extends StatelessWidget {
  const _GirviCopyStepper({
    required this.value,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int value;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: GirviColors.shellPanelBg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: GirviColors.shellBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GirviStepperButton(
            icon: Icons.remove_rounded,
            enabled: canDecrease,
            onTap: onDecrease,
          ),
          SizedBox(
            width: 38,
            child: Center(
              child: Text(
                '$value',
                style: GoogleFonts.manrope(
                  color: GirviColors.brandGold,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          _GirviStepperButton(
            icon: Icons.add_rounded,
            enabled: canIncrease,
            onTap: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _GirviStepperButton extends StatelessWidget {
  const _GirviStepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

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
                ? GirviColors.brandGold
                : GirviColors.shellTextMuted.withValues(alpha: 0.38),
          ),
        ),
      ),
    );
  }
}

class _GirviPrintStatusBadge extends StatelessWidget {
  const _GirviPrintStatusBadge({
    required this.label,
    required this.isActive,
  });

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? GirviColors.brandGold.withValues(alpha: 0.14)
            : GirviColors.shellBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? GirviColors.brandGold.withValues(alpha: 0.40)
              : GirviColors.shellBorder,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: isActive ? GirviColors.brandGold : GirviColors.shellTextMuted,
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _GirviPrintMetaPill extends StatelessWidget {
  const _GirviPrintMetaPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: GirviColors.shellBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.shellBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: GirviColors.shellTextMuted),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: GirviColors.shellTextTitle,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
