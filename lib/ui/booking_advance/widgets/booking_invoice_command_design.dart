part of 'booking_invoice_command_panel.dart';

class _DesignSection extends StatelessWidget {
  const _DesignSection({required this.controller});

  final BookingInvoicePreviewController controller;

  @override
  Widget build(BuildContext context) {
    final selectedTemplate = controller.selectedTemplate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ShellSectionLabel('INVOICE DESIGN'),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showDesignPicker(context, selectedTemplate),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BookingAdvanceColors.shellPanelBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _templateAccent(selectedTemplate).withValues(
                    alpha: selectedTemplate.isSystemDefault ? 0.50 : 0.64),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _DesignIcon(template: selectedTemplate),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedTemplate.shortName,
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
                            selectedTemplate.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _templateAccent(selectedTemplate),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ChangeButton(
                      onTap: () => _showDesignPicker(context, selectedTemplate),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _FormatDetailPill(
                        icon: Icons.auto_awesome_rounded,
                        label: _templateTone(selectedTemplate),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: _FormatDetailPill(
                        icon: Icons.description_rounded,
                        label: 'Booking ready',
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

  Future<void> _showDesignPicker(
    BuildContext context,
    PrintTemplateDefinition selectedTemplate,
  ) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close invoice design selector',
      barrierColor: Colors.black.withValues(alpha: 0.48),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, __) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: _DesignPickerPanel(
              selectedTemplate: selectedTemplate,
              onSelect: (template) {
                controller.switchTemplate(template.id);
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

class _DesignPickerPanel extends StatelessWidget {
  const _DesignPickerPanel({
    required this.selectedTemplate,
    required this.onSelect,
    required this.onClose,
  });

  final PrintTemplateDefinition selectedTemplate;
  final ValueChanged<PrintTemplateDefinition> onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final panelWidth = width < 560 ? width - 24 : 420.0;
    final templates = PrintTemplateRegistry.forDocument(
      PrintTemplateDocumentType.bookingAdvance,
    );

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
                      Icons.palette_rounded,
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
                          'INVOICE DESIGN',
                          style: TextStyle(
                            color: BookingAdvanceColors.shellTextTitle,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Booking invoice visual template',
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
                  final template = templates[index];
                  final selected = template.id == selectedTemplate.id;
                  return _DesignOptionTile(
                    template: template,
                    selected: selected,
                    onTap: () => onSelect(template),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemCount: templates.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesignOptionTile extends StatelessWidget {
  const _DesignOptionTile({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final PrintTemplateDefinition template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _templateAccent(template);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.10)
              : BookingAdvanceColors.shellBg.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accent : BookingAdvanceColors.shellBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            _DesignIcon(template: template),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.shortName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? accent
                          : BookingAdvanceColors.shellTextTitle,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    template.description,
                    maxLines: 3,
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
              color: selected ? accent : BookingAdvanceColors.shellTextMuted,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}

class _DesignIcon extends StatelessWidget {
  const _DesignIcon({required this.template});

  final PrintTemplateDefinition template;

  @override
  Widget build(BuildContext context) {
    final accent = _templateAccent(template);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Icon(
        _templateIcon(template),
        color: accent,
        size: 21,
      ),
    );
  }
}

Color _templateAccent(PrintTemplateDefinition template) {
  return switch (template.id) {
    PrintTemplateRegistry.defaultTemplateId => BookingAdvanceColors.brandGold,
    'lotus_economy' => BookingAdvanceColors.shellTextMuted,
    'lotus_signature' => const Color(0xFFB87518),
    _ => BookingAdvanceColors.brandGold,
  };
}

IconData _templateIcon(PrintTemplateDefinition template) {
  return switch (template.id) {
    PrintTemplateRegistry.defaultTemplateId => Icons.workspace_premium_rounded,
    'lotus_economy' => Icons.article_outlined,
    'lotus_signature' => Icons.diamond_outlined,
    _ => Icons.description_rounded,
  };
}

String _templateTone(PrintTemplateDefinition template) {
  return switch (template.id) {
    PrintTemplateRegistry.defaultTemplateId => 'Premium classic',
    'lotus_economy' => 'Low ink',
    'lotus_signature' => 'Luxury gold',
    _ => 'System design',
  };
}
