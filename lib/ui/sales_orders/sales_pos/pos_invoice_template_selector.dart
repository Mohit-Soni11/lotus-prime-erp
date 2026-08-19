import 'package:flutter/material.dart';

import '../../../features/print_templates/domain/print_template_registry.dart';
import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';

class PosInvoiceTemplateSelector extends StatelessWidget {
  final String selectedTemplateId;
  final PrintTemplateDocumentType documentType;
  final ValueChanged<String> onChanged;
  final String title;

  const PosInvoiceTemplateSelector({
    super.key,
    required this.selectedTemplateId,
    required this.onChanged,
    this.documentType = PrintTemplateDocumentType.salesInvoice,
    this.title = 'INVOICE TEMPLATE',
  });

  @override
  Widget build(BuildContext context) {
    final templates = PrintTemplateRegistry.forDocument(documentType);
    if (templates.isEmpty) return const SizedBox.shrink();

    final selectedTemplate = _resolveSelectedTemplate(templates);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: SalesPosColors.shellTextMuted,
            fontSize: SalesPosStyles.fontCaption,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () =>
              _showTemplatePicker(context, templates, selectedTemplate),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SalesPosColors.shellPanelBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: SalesPosColors.brandGold.withValues(alpha: 0.45),
              ),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _TemplateThumbnail(template: selectedTemplate),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  selectedTemplate.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: SalesPosColors.shellTextTitle,
                                    fontSize: SalesPosStyles.fontLabel,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            selectedTemplate.shortName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: SalesPosColors.brandGold,
                              fontSize: SalesPosStyles.fontCaption,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ChangeButton(
                      enabled: templates.length > 1,
                      onTap: () => _showTemplatePicker(
                        context,
                        templates,
                        selectedTemplate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _InfoPill(
                      icon: Icons.article_outlined,
                      label: documentType.label,
                    ),
                    const SizedBox(width: 8),
                    _InfoPill(
                      icon: selectedTemplate.isSystemDefault
                          ? Icons.verified_rounded
                          : Icons.layers_rounded,
                      label: selectedTemplate.isSystemDefault
                          ? 'Default'
                          : '${templates.length} design${templates.length == 1 ? '' : 's'}',
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

  PrintTemplateDefinition _resolveSelectedTemplate(
    List<PrintTemplateDefinition> templates,
  ) {
    for (final template in templates) {
      if (template.id == selectedTemplateId) return template;
    }
    final fallback = PrintTemplateRegistry.byId(selectedTemplateId);
    if (fallback.supports(documentType)) return fallback;
    return templates.first;
  }

  Future<void> _showTemplatePicker(
    BuildContext context,
    List<PrintTemplateDefinition> templates,
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
            child: _TemplatePickerPanel(
              title: title,
              documentType: documentType,
              templates: templates,
              selectedTemplateId: selectedTemplate.id,
              onSelect: (templateId) {
                onChanged(templateId);
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

class _TemplatePickerPanel extends StatelessWidget {
  final String title;
  final PrintTemplateDocumentType documentType;
  final List<PrintTemplateDefinition> templates;
  final String selectedTemplateId;
  final ValueChanged<String> onSelect;
  final VoidCallback onClose;

  const _TemplatePickerPanel({
    required this.title,
    required this.documentType,
    required this.templates,
    required this.selectedTemplateId,
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
                      color: SalesPosColors.brandGold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: SalesPosColors.brandGold,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: SalesPosColors.shellTextTitle,
                            fontSize: SalesPosStyles.fontInput,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${documentType.label} design library',
                          style: const TextStyle(
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
                  final template = templates[index];
                  return _TemplateOptionTile(
                    template: template,
                    selected: template.id == selectedTemplateId,
                    onTap: () => onSelect(template.id),
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

class _TemplateOptionTile extends StatelessWidget {
  final PrintTemplateDefinition template;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateOptionTile({
    required this.template,
    required this.selected,
    required this.onTap,
  });

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
            _TemplateThumbnail(template: template),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          template.name,
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
                      ),
                      if (template.isSystemDefault)
                        const _SmallBadge(label: 'Default'),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    template.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SalesPosColors.shellTextMuted,
                      fontSize: SalesPosStyles.fontCaption,
                      height: 1.15,
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
  }
}

class _ChangeButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _ChangeButton({
    required this.enabled,
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
              enabled ? 'Change' : 'View',
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

class _TemplateThumbnail extends StatelessWidget {
  final PrintTemplateDefinition template;

  const _TemplateThumbnail({required this.template});

  @override
  Widget build(BuildContext context) {
    final isEconomy = template.id == PrintTemplateRegistry.lotusEconomy.id;
    final isSignature = template.id == PrintTemplateRegistry.lotusSignature.id;
    final pageColor =
        isEconomy || isSignature ? Colors.white : const Color(0xFF172437);
    final accentColor = isEconomy
        ? SalesPosColors.shellTextTitle
        : isSignature
            ? const Color(0xFFB87819)
            : SalesPosColors.brandGold;
    final lineColor = isEconomy
        ? SalesPosColors.shellBorder
        : isSignature
            ? const Color(0xFFE8D7B3)
            : Colors.white.withValues(alpha: 0.82);

    return Container(
      width: 36,
      height: 46,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: pageColor,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.75),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: isEconomy ? 1.5 : (isSignature ? 1.2 : 6),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 4),
          ...List.generate(
            3,
            (index) => Container(
              height: 2.8,
              width: index == 1 ? 16 : double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 1.3),
              decoration: BoxDecoration(
                color: lineColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (isSignature) ...[
            const Spacer(),
            Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor, width: 0.8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;

  const _SmallBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: SalesPosColors.brandGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: SalesPosColors.brandGold.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: SalesPosColors.brandGold,
          fontSize: SalesPosStyles.fontCaption,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
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
      ),
    );
  }
}
