part of 'booking_invoice_command_panel.dart';

class _FormatSection extends StatelessWidget {
  const _FormatSection({required this.controller});

  final BookingInvoicePreviewController controller;

  @override
  Widget build(BuildContext context) {
    final selectedFormat = controller.selectedFormat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ShellSectionLabel('DOCUMENT FORMAT'),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showFormatPicker(context, selectedFormat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BookingAdvanceColors.shellPanelBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: BookingAdvanceColors.brandGold.withValues(alpha: 0.45),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _FormatIcon(format: selectedFormat),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedFormat.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: BookingAdvanceColors.shellTextTitle,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatShortName(selectedFormat),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: BookingAdvanceColors.brandGold,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ChangeButton(
                      onTap: () => _showFormatPicker(context, selectedFormat),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _FormatDetailPill(
                        icon: Icons.straighten_rounded,
                        label: _formatPaperSpec(selectedFormat),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FormatDetailPill(
                        icon: Icons.verified_rounded,
                        label: _formatUseCase(selectedFormat),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showFormatPicker(
    BuildContext context,
    PrintFormat selectedFormat,
  ) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close document format selector',
      barrierColor: Colors.black.withValues(alpha: 0.48),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, __) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: _FormatPickerPanel(
              selectedFormat: selectedFormat,
              onSelect: (format) {
                controller.switchFormat(format);
                Navigator.of(dialogContext).pop();
              },
              onClose: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.12, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }
}

class _FormatPickerPanel extends StatelessWidget {
  const _FormatPickerPanel({
    required this.selectedFormat,
    required this.onSelect,
    required this.onClose,
  });

  final PrintFormat selectedFormat;
  final ValueChanged<PrintFormat> onSelect;
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
        color: BookingAdvanceColors.shellPanelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BookingAdvanceColors.shellBorder),
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
                      color: BookingAdvanceColors.brandGold
                          .withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.straighten_rounded,
                      color: BookingAdvanceColors.brandGold,
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
                            color: BookingAdvanceColors.shellTextTitle,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Booking paper and receipt layout',
                          style: TextStyle(
                            color: BookingAdvanceColors.shellTextMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: BookingAdvanceColors.shellTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: BookingAdvanceColors.shellBorder, height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(14),
                itemBuilder: (context, index) {
                  final format = PrintFormat.values[index];
                  final selected = format == selectedFormat;
                  return _FormatOptionTile(
                    format: format,
                    selected: selected,
                    onTap: () => onSelect(format),
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

class _FormatOptionTile extends StatelessWidget {
  const _FormatOptionTile({
    required this.format,
    required this.selected,
    required this.onTap,
  });

  final PrintFormat format;
  final bool selected;
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
              ? BookingAdvanceColors.brandGold.withValues(alpha: 0.10)
              : BookingAdvanceColors.shellBg.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? BookingAdvanceColors.brandGold
                : BookingAdvanceColors.shellBorder,
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
                          ? BookingAdvanceColors.brandGold
                          : BookingAdvanceColors.shellTextTitle,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${_formatShortName(format)}  |  ${_formatPaperSpec(format)}  |  ${_formatUseCase(format)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: BookingAdvanceColors.shellTextMuted,
                      fontSize: 11,
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
              color: selected
                  ? BookingAdvanceColors.brandGold
                  : BookingAdvanceColors.shellTextMuted,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatIcon extends StatelessWidget {
  const _FormatIcon({required this.format});

  final PrintFormat format;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: BookingAdvanceColors.brandGold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: BookingAdvanceColors.brandGold.withValues(alpha: 0.28),
        ),
      ),
      child: Icon(
        format.icon,
        color: BookingAdvanceColors.brandGold,
        size: 21,
      ),
    );
  }
}

class _ChangeButton extends StatelessWidget {
  const _ChangeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: BookingAdvanceColors.brandGold.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: BookingAdvanceColors.brandGold.withValues(alpha: 0.32),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Change',
              style: TextStyle(
                color: BookingAdvanceColors.brandGold,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: BookingAdvanceColors.brandGold,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatDetailPill extends StatelessWidget {
  const _FormatDetailPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: BookingAdvanceColors.shellBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BookingAdvanceColors.shellBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: BookingAdvanceColors.shellTextMuted, size: 15),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: BookingAdvanceColors.shellTextTitle,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatShortName(PrintFormat format) {
  return switch (format) {
    PrintFormat.a4 => 'A4',
    PrintFormat.thermal3inch => '80 mm',
    PrintFormat.thermal2inch => '57 mm',
  };
}

String _formatPaperSpec(PrintFormat format) {
  return switch (format) {
    PrintFormat.a4 => '210 x 297 mm',
    PrintFormat.thermal3inch => '80 mm roll',
    PrintFormat.thermal2inch => '57 mm roll',
  };
}

String _formatUseCase(PrintFormat format) {
  return switch (format) {
    PrintFormat.a4 => 'Full invoice',
    PrintFormat.thermal3inch => 'Counter print',
    PrintFormat.thermal2inch => 'Compact receipt',
  };
}
