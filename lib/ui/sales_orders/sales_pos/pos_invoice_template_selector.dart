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
        Column(
          children: templates
              .map(
                (template) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _InvoiceTemplateCard(
                    template: template,
                    isSelected: selectedTemplateId == template.id,
                    onTap: () => onChanged(template.id),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _InvoiceTemplateCard extends StatelessWidget {
  final PrintTemplateDefinition template;
  final bool isSelected;
  final VoidCallback onTap;

  const _InvoiceTemplateCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? SalesPosColors.brandGold.withValues(alpha: 0.10)
              : SalesPosColors.bodyPanelBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? SalesPosColors.brandGold
                : SalesPosColors.bodyBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            _TemplateThumbnail(isSelected: isSelected),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? SalesPosColors.brandGold
                          : SalesPosColors.bodyTextMain,
                      fontSize: SalesPosStyles.fontLabel,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SalesPosColors.shellTextMuted,
                      fontSize: SalesPosStyles.fontCaption,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected
                  ? SalesPosColors.brandGold
                  : SalesPosColors.shellTextMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateThumbnail extends StatelessWidget {
  final bool isSelected;

  const _TemplateThumbnail({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF172437),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: SalesPosColors.brandGold.withValues(
            alpha: isSelected ? 1 : 0.85,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 8,
            margin: const EdgeInsets.fromLTRB(7, 7, 7, 5),
            decoration: BoxDecoration(
              color: SalesPosColors.brandGold,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Container(height: 1, color: SalesPosColors.brandGold),
          const SizedBox(height: 5),
          ...List.generate(
            3,
            (index) => Container(
              height: 3.5,
              margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
