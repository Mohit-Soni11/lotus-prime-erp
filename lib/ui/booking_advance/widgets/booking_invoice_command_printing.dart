part of 'booking_invoice_command_panel.dart';

class _PrintControlsSection extends StatelessWidget {
  const _PrintControlsSection({required this.controller});

  final BookingInvoicePreviewController controller;

  @override
  Widget build(BuildContext context) {
    final copies = controller.printCopies;
    final duplicateEnabled = controller.includeDuplicateStamp;
    final useDriverSettings = controller.usePrinterDriverSettings;
    final colorMode = controller.printColorMode;
    final canDecrease = copies > 1;
    final canIncrease = copies < 5;
    final canMarkDuplicate = copies > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ShellSectionLabel('PRINT CONTROLS'),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: BookingAdvanceColors.shellPanelBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: BookingAdvanceColors.brandGold.withValues(alpha: 0.32),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const _PrintIconTile(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Print Run',
                          style: TextStyle(
                            color: BookingAdvanceColors.shellTextTitle,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          copies == 1 ? 'Single copy' : '$copies copies',
                          style: const TextStyle(
                            color: BookingAdvanceColors.shellTextMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(
                    label: duplicateEnabled ? 'Duplicate On' : 'Original',
                    active: duplicateEnabled,
                  ),
                ],
              ),
              const Divider(
                color: BookingAdvanceColors.shellBorder,
                height: 24,
              ),
              _PrintControlSurface(
                icon: Icons.copy_all_rounded,
                title: 'Copies',
                subtitle: 'Maximum 5 copies per print run',
                trailing: _CopyStepper(
                  value: copies,
                  canDecrease: canDecrease,
                  canIncrease: canIncrease,
                  onDecrease: () => controller.updatePrintOptions(
                    copies: copies - 1,
                  ),
                  onIncrease: () => controller.updatePrintOptions(
                    copies: copies + 1,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _PrintControlSurface(
                icon: Icons.verified_user_rounded,
                title: 'Duplicate Mark',
                subtitle: canMarkDuplicate
                    ? 'Stamp second and later copies'
                    : 'Available from 2 copies',
                trailing: Switch(
                  value: duplicateEnabled,
                  onChanged: canMarkDuplicate
                      ? (value) => controller.updatePrintOptions(
                            duplicate: value,
                          )
                      : null,
                  activeThumbColor: BookingAdvanceColors.brandGold,
                  activeTrackColor:
                      BookingAdvanceColors.brandGold.withValues(alpha: 0.32),
                  inactiveThumbColor: BookingAdvanceColors.shellTextMuted,
                  inactiveTrackColor: BookingAdvanceColors.shellBg,
                ),
              ),
              const SizedBox(height: 10),
              _PrintControlSurface(
                icon: Icons.invert_colors_rounded,
                title: 'Print Mode',
                subtitle: 'Choose colour or grayscale output',
                trailing: _PrintModeSelector(
                  value: colorMode,
                  onChanged: (value) => controller.updatePrintOptions(
                    colorMode: value,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _PrintControlSurface(
                icon: Icons.settings_applications_rounded,
                title: 'Printer Driver Settings',
                subtitle: 'Use saved paper, tray and printer defaults',
                trailing: Switch(
                  value: useDriverSettings,
                  onChanged: (value) => controller.updatePrintOptions(
                    useDriverSettings: value,
                  ),
                  activeThumbColor: BookingAdvanceColors.brandGold,
                  activeTrackColor:
                      BookingAdvanceColors.brandGold.withValues(alpha: 0.32),
                  inactiveThumbColor: BookingAdvanceColors.shellTextMuted,
                  inactiveTrackColor: BookingAdvanceColors.shellBg,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MetaPill(
                      icon: Icons.description_rounded,
                      label: _formatShortName(controller.selectedFormat),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetaPill(
                      icon: Icons.layers_rounded,
                      label: copies == 1 ? '1 copy' : '$copies copies',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetaPill(
                      icon: colorMode == LotusPrintColorMode.color
                          ? Icons.palette_rounded
                          : Icons.contrast_rounded,
                      label: colorMode == LotusPrintColorMode.color
                          ? 'Colour'
                          : 'B&W',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetaPill(
                      icon: duplicateEnabled
                          ? Icons.verified_rounded
                          : Icons.lock_open_rounded,
                      label: duplicateEnabled ? 'Stamped' : 'Clean',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
        color: BookingAdvanceColors.shellBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BookingAdvanceColors.shellBorder),
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
          color: selected ? BookingAdvanceColors.brandGold : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color:
                  selected ? Colors.black : BookingAdvanceColors.shellTextMuted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.black
                    : BookingAdvanceColors.shellTextMuted,
                fontSize: 11,
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

class _PrintControlSurface extends StatelessWidget {
  const _PrintControlSurface({
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
        color: BookingAdvanceColors.shellBg.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BookingAdvanceColors.shellBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: BookingAdvanceColors.brandGold, size: 18),
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
                    color: BookingAdvanceColors.shellTextTitle,
                    fontSize: 13,
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
                    color: BookingAdvanceColors.shellTextMuted,
                    fontSize: 11,
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
  const _CopyStepper({
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
        color: BookingAdvanceColors.shellPanelBg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: BookingAdvanceColors.shellBorder),
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
                  color: BookingAdvanceColors.brandGold,
                  fontSize: 15,
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
  const _StepperButton({
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
                ? BookingAdvanceColors.brandGold
                : BookingAdvanceColors.shellTextMuted.withValues(alpha: 0.38),
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
        color: BookingAdvanceColors.brandGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: BookingAdvanceColors.brandGold.withValues(alpha: 0.28),
        ),
      ),
      child: const Icon(
        Icons.print_rounded,
        color: BookingAdvanceColors.brandGold,
        size: 20,
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
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
        color: BookingAdvanceColors.shellBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BookingAdvanceColors.shellBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: BookingAdvanceColors.shellTextMuted),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: BookingAdvanceColors.shellTextTitle,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
