import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../constants/app_routes.dart';
import '../../../features/print_templates/application/print_template_preview_pdf_service.dart';
import '../../../features/print_templates/data/print_template_repository.dart';
import '../../../features/print_templates/domain/print_template_registry.dart';
import '../../../theme/settings/settings_dashboard/settings_theme.dart';

class PrintTemplatesScreen extends StatefulWidget {
  const PrintTemplatesScreen({super.key});

  @override
  State<PrintTemplatesScreen> createState() => _PrintTemplatesScreenState();
}

class _PrintTemplatesScreenState extends State<PrintTemplatesScreen> {
  final PrintTemplateRepository _repository = PrintTemplateRepository();
  final PrintTemplatePreviewPdfService _previewService =
      PrintTemplatePreviewPdfService();
  bool _isApplying = false;
  String? _notice;

  Future<void> _applyDefault(PrintTemplateDefinition template) async {
    setState(() {
      _isApplying = true;
      _notice = null;
    });

    await _repository.applyDefaultTemplate(templateId: template.id);

    if (!mounted) return;
    setState(() {
      _isApplying = false;
      _notice =
          '${template.shortName} is now the default print template for Sales, Purchase and Girvi billing.';
    });
  }

  Future<void> _showTemplatePreview(PrintTemplateDefinition template) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (context) => _TemplatePreviewDialog(
        template: template,
        previewService: _previewService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SettingsColors.pageBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Header(
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }
                  context.go(RoutePaths.settings);
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_notice != null) ...[
                    _NoticeBanner(message: _notice!),
                    const SizedBox(height: 16),
                  ],
                  _OverviewPanel(
                    templateCount: PrintTemplateRegistry.templates.length,
                    defaultTemplate:
                        PrintTemplateRegistry.lotusClassic.shortName,
                  ),
                  const SizedBox(height: 18),
                  ...PrintTemplateRegistry.templates.map(
                    (template) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _TemplateCard(
                        template: template,
                        isApplying: _isApplying,
                        onView: () => _showTemplatePreview(template),
                        onApply: () => _applyDefault(template),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        border: Border(
          bottom: BorderSide(color: Color(0xFF263244)),
        ),
      ),
      child: Row(
        children: [
          _IconButton(
            icon: Icons.arrow_back_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: 14),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Color(0xFFD4AF37),
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRINT TEMPLATES',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Manage shared invoice and receipt formats',
                  style: TextStyle(
                    color: Color(0xFFB8C1D1),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF182234),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  final int templateCount;
  final String defaultTemplate;

  const _OverviewPanel({
    required this.templateCount,
    required this.defaultTemplate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          _MetricTile(
            label: 'Available Templates',
            value: templateCount.toString(),
          ),
          const SizedBox(width: 12),
          _MetricTile(
            label: 'System Default',
            value: defaultTemplate,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'The default template is shared by billing modules through their print template setting.',
              style: TextStyle(
                color: Color(0xFF334155),
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF7EF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE9D8A6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final PrintTemplateDefinition template;
  final bool isApplying;
  final VoidCallback onView;
  final VoidCallback onApply;

  const _TemplateCard({
    required this.template,
    required this.isApplying,
    required this.onView,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TemplateThumbnail(template: template),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        template.name,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (template.isSystemDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: const Text(
                          'System Default',
                          style: TextStyle(
                            color: Color(0xFF166534),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  template.description,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 13.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: template.supportedDocuments
                      .map((type) => _DocumentChip(label: type.label))
                      .toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        template.designReference,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: onView,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('View'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF111827),
                        side: const BorderSide(color: Color(0xFFD6B24A)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: isApplying ? null : onApply,
                      icon: isApplying
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline_rounded),
                      label: Text(isApplying ? 'Applying' : 'Set as Default'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
    final pageColor = isEconomy ? Colors.white : const Color(0xFF172437);
    final accentColor =
        isEconomy ? const Color(0xFF111827) : const Color(0xFFC89421);
    final lineColor = isEconomy
        ? const Color(0xFFCBD5E1)
        : Colors.white.withValues(alpha: 0.86);

    return Container(
      width: 78,
      height: 104,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: pageColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: isEconomy ? 2 : 16,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(
            5,
            (index) => Container(
              height: index == 0 ? 6 : 4,
              width: index.isEven ? double.infinity : 44,
              margin: const EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(
                color: index == 0 ? accentColor : lineColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Container(
                  height: 10,
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 3),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isEconomy ? const Color(0xFFCBD5E1) : accentColor,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplatePreviewDialog extends StatefulWidget {
  final PrintTemplateDefinition template;
  final PrintTemplatePreviewPdfService previewService;

  const _TemplatePreviewDialog({
    required this.template,
    required this.previewService,
  });

  @override
  State<_TemplatePreviewDialog> createState() => _TemplatePreviewDialogState();
}

class _TemplatePreviewDialogState extends State<_TemplatePreviewDialog> {
  late PrintTemplateDocumentType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.template.supportedDocuments.first;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = size.width > 1040 ? 1040.0 : size.width - 32;
    final dialogHeight = size.height > 820 ? 820.0 : size.height - 32;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: const Color(0xFF111827),
            child: Column(
              children: [
                _TemplatePreviewHeader(
                  template: widget.template,
                  selectedType: _selectedType,
                  onClose: () => Navigator.of(context).pop(),
                ),
                _TemplateTypeSelector(
                  supportedDocuments: widget.template.supportedDocuments,
                  selectedType: _selectedType,
                  onChanged: (type) => setState(() => _selectedType = type),
                ),
                Expanded(
                  child: PdfPreview(
                    key:
                        ValueKey('${widget.template.id}-${_selectedType.name}'),
                    build: (format) => widget.previewService.build(
                      template: widget.template,
                      documentType: _selectedType,
                      pageFormat: format,
                    ),
                    initialPageFormat: PdfPageFormat.a4,
                    allowPrinting: false,
                    allowSharing: false,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    canDebug: false,
                    useActions: false,
                    maxPageWidth: 760,
                    pdfFileName:
                        '${widget.template.id}_${_selectedType.name}_preview.pdf',
                    scrollViewDecoration: const BoxDecoration(
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplatePreviewHeader extends StatelessWidget {
  final PrintTemplateDefinition template;
  final PrintTemplateDocumentType selectedType;
  final VoidCallback onClose;

  const _TemplatePreviewHeader({
    required this.template,
    required this.selectedType,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        border: Border(
          bottom: BorderSide(color: Color(0xFF263244)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.38),
              ),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: Color(0xFFD4AF37),
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${selectedType.label} preview in the shared print template format',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFB8C1D1),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close preview',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _TemplateTypeSelector extends StatelessWidget {
  final List<PrintTemplateDocumentType> supportedDocuments;
  final PrintTemplateDocumentType selectedType;
  final ValueChanged<PrintTemplateDocumentType> onChanged;

  const _TemplateTypeSelector({
    required this.supportedDocuments,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      color: const Color(0xFF172033),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: supportedDocuments
              .map(
                (type) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(type.label),
                    selected: selectedType == type,
                    onSelected: (_) => onChanged(type),
                    selectedColor: const Color(0xFFD4AF37),
                    backgroundColor: const Color(0xFF111827),
                    side: BorderSide(
                      color: selectedType == type
                          ? const Color(0xFFD4AF37)
                          : const Color(0xFF334155),
                    ),
                    labelStyle: TextStyle(
                      color: selectedType == type
                          ? const Color(0xFF111827)
                          : Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _DocumentChip extends StatelessWidget {
  final String label;

  const _DocumentChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  final String message;

  const _NoticeBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF2563EB),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
