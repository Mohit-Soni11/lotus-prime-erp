import 'dart:io';

import 'package:pdf/widgets.dart' as pw;

import '../../../../core/pdf/lotus_pdf_text_renderer.dart';
import '../../domain/print_template_registry.dart';
import 'lotus_printable_document.dart';

class LotusPrintTemplateRenderContext {
  final LotusPrintableDocument document;
  final LotusPdfTextRenderer textRenderer;

  const LotusPrintTemplateRenderContext({
    required this.document,
    required this.textRenderer,
  });
}

typedef LotusPrintTemplateRenderer = List<pw.Widget> Function(
  LotusPrintTemplateRenderContext context, {
  required bool isDuplicateCopy,
});

class LotusPrintTemplateRendererRegistry {
  LotusPrintTemplateRendererRegistry._();

  static final Map<String, LotusPrintTemplateRenderer> _a4Renderers = {
    PrintTemplateRegistry.defaultTemplateId: (context,
        {required isDuplicateCopy}) {
      return const LotusClassicDocumentPdfLayout().build(
        context,
        isDuplicateCopy: isDuplicateCopy,
      );
    },
    PrintTemplateRegistry.lotusEconomy.id: (context,
        {required isDuplicateCopy}) {
      return const LotusEconomyDocumentPdfLayout().build(
        context,
        isDuplicateCopy: isDuplicateCopy,
      );
    },
    PrintTemplateRegistry.lotusSignature.id: (context,
        {required isDuplicateCopy}) {
      return const LotusSignatureDocumentPdfLayout().build(
        context,
        isDuplicateCopy: isDuplicateCopy,
      );
    },
  };

  static Future<void> warmPolicyText(
    LotusPrintableDocument document,
    LotusPdfTextRenderer textRenderer,
  ) async {
    final lines = document.policySections
        .expand((section) => section.body.split('\n'))
        .map((line) => line.trimRight())
        .where((line) => line.isNotEmpty)
        .toSet();
    if (lines.isEmpty) return;
    await textRenderer.warmTextLines(
      lines,
      specs: [
        LotusPdfTextSpec(
          fontSize: document.profile.policyFontSize,
          color: document.profile.bodyTextColor,
          bold: false,
          maxWidth: 500,
        ),
      ],
    );
  }

  static List<pw.Widget> buildA4({
    required String templateId,
    required LotusPrintTemplateRenderContext context,
    required bool isDuplicateCopy,
  }) {
    final resolvedTemplate = PrintTemplateRegistry.byId(templateId);
    final renderer = _a4Renderers[resolvedTemplate.id] ??
        _a4Renderers[PrintTemplateRegistry.defaultTemplateId]!;
    return renderer(context, isDuplicateCopy: isDuplicateCopy);
  }
}

class LotusClassicDocumentPdfLayout {
  const LotusClassicDocumentPdfLayout();

  List<pw.Widget> build(
    LotusPrintTemplateRenderContext context, {
    required bool isDuplicateCopy,
  }) {
    return _LotusDocumentLayoutEngine.buildStandard(
      context,
      isDuplicateCopy: isDuplicateCopy,
    );
  }
}

class LotusEconomyDocumentPdfLayout {
  const LotusEconomyDocumentPdfLayout();

  List<pw.Widget> build(
    LotusPrintTemplateRenderContext context, {
    required bool isDuplicateCopy,
  }) {
    return _LotusDocumentLayoutEngine.buildStandard(
      context,
      isDuplicateCopy: isDuplicateCopy,
    );
  }
}

class LotusSignatureDocumentPdfLayout {
  const LotusSignatureDocumentPdfLayout();

  List<pw.Widget> build(
    LotusPrintTemplateRenderContext context, {
    required bool isDuplicateCopy,
  }) {
    return _LotusDocumentLayoutEngine.buildSignature(
      context,
      isDuplicateCopy: isDuplicateCopy,
    );
  }
}

class _LotusDocumentLayoutEngine {
  static List<pw.Widget> buildStandard(
    LotusPrintTemplateRenderContext context, {
    required bool isDuplicateCopy,
  }) {
    final document = context.document;
    final profile = document.profile;
    return [
      if (isDuplicateCopy) _duplicateStamp(profile),
      _standardHeader(document),
      if (_hasPanelDetails(document.primaryPanel)) ...[
        pw.SizedBox(height: profile.sectionGap),
        _panel(document.primaryPanel, profile),
      ],
      if (_hasPanelDetails(document.secondaryPanel)) ...[
        pw.SizedBox(height: profile.sectionGap),
        _panel(document.secondaryPanel, profile),
      ],
      pw.SizedBox(height: profile.sectionGap),
      _itemTable(document.itemTable, profile),
      pw.SizedBox(height: profile.sectionGap),
      for (final panel
          in document.settlementPanels.where(_hasPanelDetails)) ...[
        _panel(panel, profile),
        pw.SizedBox(height: profile.sectionGap),
      ],
      ..._policySections(context),
      _footer(document),
    ];
  }

  static List<pw.Widget> buildSignature(
    LotusPrintTemplateRenderContext context, {
    required bool isDuplicateCopy,
  }) {
    final document = context.document;
    final profile = document.profile;
    final hasPrimaryPanel = _hasPanelDetails(document.primaryPanel);
    final hasSecondaryPanel = _hasPanelDetails(document.secondaryPanel);
    final settlementPanels = document.settlementPanels
        .where(_hasPanelDetails)
        .take(2)
        .toList(growable: false);
    return [
      if (isDuplicateCopy) _duplicateStamp(profile),
      pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(14, 16, 14, 12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: profile.accentColor, width: 0.9),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _signatureHeader(document),
            pw.SizedBox(height: 14),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (hasPrimaryPanel)
                  pw.Expanded(
                      child: _signaturePanel(document.primaryPanel, profile)),
                if (hasPrimaryPanel && hasSecondaryPanel)
                  pw.SizedBox(width: 14),
                if (hasSecondaryPanel)
                  pw.Expanded(
                      child: _signaturePanel(document.secondaryPanel, profile)),
              ],
            ),
            pw.SizedBox(height: 14),
            _sectionTitle(document.itemTable.title, profile),
            pw.SizedBox(height: 8),
            _itemTable(document.itemTable, profile),
            pw.SizedBox(height: 14),
            if (settlementPanels.isNotEmpty)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  for (var index = 0;
                      index < settlementPanels.length;
                      index++) ...[
                    if (index > 0) pw.SizedBox(width: 14),
                    pw.Expanded(
                      child: _signaturePanel(
                        settlementPanels[index],
                        profile,
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
      ..._policySections(context),
      _footer(document),
    ];
  }

  static pw.Widget _standardHeader(LotusPrintableDocument document) {
    final profile = document.profile;
    final shopName = _shopName(document);
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(profile.headerPadding),
      decoration: pw.BoxDecoration(
        color: profile.headerColor,
        border: pw.Border.all(
          color: profile.headerBorderColor,
          width: profile.headerBorderWidth,
        ),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(profile.radius)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (shopName.isNotEmpty)
                  pw.Text(
                    shopName,
                    style: pw.TextStyle(
                      color: profile.headerPrimaryTextColor,
                      fontSize: profile.titleFontSize,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                for (final line in document.shopProfile.headerLines.take(6))
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      line,
                      style: pw.TextStyle(
                        fontSize: 8.8,
                        color: profile.headerSecondaryTextColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                document.title,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  color: profile.headerPrimaryTextColor,
                  fontSize: profile.documentTitleFontSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                document.subtitle,
                style: pw.TextStyle(
                  color: profile.headerSecondaryTextColor,
                  fontSize: profile.bodyFontSize,
                ),
              ),
              pw.SizedBox(height: 8),
              if (document.showHeaderDocumentMeta) ...[
                _metaText(
                  document.documentNumberLabel,
                  document.documentNumber,
                  profile,
                ),
                _metaText(
                  document.documentDateLabel,
                  document.documentDate,
                  profile,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _signatureHeader(LotusPrintableDocument document) {
    final profile = document.profile;
    final shopName = _shopName(document);
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: profile.accentColor, width: 1),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 124,
            padding: const pw.EdgeInsets.only(right: 14),
            child: _brandMark(document),
          ),
          pw.Container(width: 1, height: 124, color: profile.borderColor),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (shopName.isNotEmpty) ...[
                        pw.Text(
                          shopName,
                          maxLines: 1,
                          overflow: pw.TextOverflow.clip,
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 0.8,
                            color: profile.bodyTextColor,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                      ],
                      if (document.shopProfile.primaryAddress.isNotEmpty)
                        _headerLine(
                          'location',
                          _compact(document.shopProfile.primaryAddress),
                          profile,
                        ),
                      if (_shopPhoneLine(document).isNotEmpty)
                        _headerLine('phone', _shopPhoneLine(document), profile),
                      if (document.shopProfile
                          .valueOf('business_email')
                          .isNotEmpty)
                        _headerLine(
                          'mail',
                          document.shopProfile.valueOf('business_email'),
                          profile,
                        ),
                      if (document.shopProfile.gstin.isNotEmpty)
                        _headerLine('gst',
                            'GSTIN: ${document.shopProfile.gstin}', profile),
                    ],
                  ),
                ),
                pw.SizedBox(width: 14),
                pw.Container(
                  width: 150,
                  padding: const pw.EdgeInsets.only(top: 3),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        document.title,
                        textAlign: pw.TextAlign.right,
                        maxLines: 2,
                        overflow: pw.TextOverflow.clip,
                        style: pw.TextStyle(
                          fontSize: 16.5,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.4,
                          color: profile.bodyTextColor,
                        ),
                      ),
                      pw.Container(
                        width: 58,
                        height: 1,
                        margin: const pw.EdgeInsets.only(top: 6, bottom: 4),
                        color: profile.accentColor,
                      ),
                      if (document.showHeaderBadge &&
                          document.badgeLabel.trim().isNotEmpty)
                        pw.Text(
                          document.badgeLabel,
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            fontSize: 10.8,
                            fontWeight: pw.FontWeight.bold,
                            color: profile.accentColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      if (document.showHeaderDocumentMeta) ...[
                        pw.SizedBox(height: 13),
                        _invoiceMeta(
                          document.documentNumberLabel,
                          document.documentNumber,
                          profile,
                        ),
                        _invoiceMeta(
                          document.documentDateLabel,
                          document.documentDate,
                          profile,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _panel(
    LotusPrintablePanel panel,
    dynamic profile,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(profile.panelPadding),
      decoration: pw.BoxDecoration(
        color: profile.panelColor,
        border: pw.Border.all(
            color: profile.borderColor, width: profile.borderWidth),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(profile.radius)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            panel.title,
            style: pw.TextStyle(
              color: profile.accentColor,
              fontSize: profile.labelFontSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 7),
          for (final detail in panel.details)
            if (detail.value.trim().isNotEmpty)
              _standardDetail(detail, profile),
        ],
      ),
    );
  }

  static pw.Widget _signaturePanel(
    LotusPrintablePanel panel,
    dynamic profile,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: profile.borderColor, width: 0.8),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle(panel.title, profile),
          pw.SizedBox(height: 10),
          for (var index = 0; index < panel.details.length; index++)
            if (panel.details[index].value.trim().isNotEmpty)
              _signatureDetail(
                panel.details[index],
                profile,
                showDivider: index < panel.details.length - 1,
              ),
        ],
      ),
    );
  }

  static pw.Widget _itemTable(LotusPrintableTable table, dynamic profile) {
    return pw.TableHelper.fromTextArray(
      headerDecoration: pw.BoxDecoration(color: profile.tableHeaderColor),
      headerStyle: pw.TextStyle(
        color: profile.tableHeaderTextColor,
        fontSize: profile.tableFontSize,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(
        color: profile.bodyTextColor,
        fontSize: profile.tableFontSize,
        fontWeight:
            profile.isSignature ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: pw.EdgeInsets.all(profile.tableCellPadding),
      border: pw.TableBorder.all(
        color: profile.tableBorderColor,
        width: profile.tableBorderWidth,
      ),
      headers: table.headers,
      data: table.rows,
    );
  }

  static List<pw.Widget> _policySections(
    LotusPrintTemplateRenderContext context,
  ) {
    final document = context.document;
    final profile = document.profile;
    final sections = document.policySections
        .where((section) => section.body.trim().isNotEmpty)
        .toList(growable: false);
    if (sections.isEmpty) return const [];
    return [
      pw.SizedBox(height: 16),
      pw.Container(
        width: double.infinity,
        padding: pw.EdgeInsets.all(profile.panelPadding),
        decoration: pw.BoxDecoration(
          color: profile.policyPanelColor,
          border: pw.Border.all(
              color: profile.borderColor, width: profile.borderWidth),
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(profile.radius)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            for (final section in sections) ...[
              pw.Text(
                section.title,
                style: pw.TextStyle(
                  fontSize: profile.labelFontSize,
                  fontWeight: pw.FontWeight.bold,
                  color: profile.accentColor,
                ),
              ),
              pw.SizedBox(height: 2),
              ..._policyBody(section.body, context),
              pw.SizedBox(height: 7),
            ],
          ],
        ),
      ),
    ];
  }

  static List<pw.Widget> _policyBody(
    String body,
    LotusPrintTemplateRenderContext context,
  ) {
    final profile = context.document.profile;
    final textStyle = pw.TextStyle(
      fontSize: profile.policyFontSize,
      color: profile.bodyTextColor,
      lineSpacing: 1.3,
    );
    return [
      for (final line
          in body.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n'))
        if (line.trim().isEmpty)
          pw.SizedBox(height: 4)
        else
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2.5),
            child: context.textRenderer.text(
              line.trimRight(),
              style: textStyle,
              maxWidth: 500,
            ),
          ),
    ];
  }

  static pw.Widget _footer(LotusPrintableDocument document) {
    final profile = document.profile;
    return pw.Column(
      children: [
        pw.SizedBox(height: 12),
        pw.Divider(color: profile.borderColor),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(
                document.footerMessage,
                style: pw.TextStyle(
                  fontSize: 9.5,
                  color: profile.bodyTextColor,
                ),
              ),
            ),
            pw.Text(
              'E&OE',
              style: pw.TextStyle(
                fontSize: 9.5,
                color: profile.accentColor,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _duplicateStamp(dynamic profile) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: profile.duplicateStampColor,
        border: pw.Border.all(color: profile.accentColor, width: 0.8),
      ),
      child: pw.Text(
        'DUPLICATE COPY',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: profile.duplicateStampTextColor,
        ),
      ),
    );
  }

  static pw.Widget _standardDetail(
      LotusPrintableDetail detail, dynamic profile) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              detail.label,
              style: pw.TextStyle(
                color: profile.bodyTextColor,
                fontSize: profile.bodyFontSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text(
            detail.value,
            style: pw.TextStyle(
              color: detail.highlight
                  ? profile.accentColor
                  : profile.bodyTextColor,
              fontSize: profile.bodyFontSize,
              fontWeight:
                  detail.highlight ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _signatureDetail(
    LotusPrintableDetail detail,
    dynamic profile, {
    required bool showDivider,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 6),
        decoration: showDivider
            ? pw.BoxDecoration(
                border: pw.Border(
                  bottom:
                      pw.BorderSide(color: profile.borderColor, width: 0.45),
                ),
              )
            : null,
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _iconBadge(detail.iconKey, profile),
            pw.SizedBox(width: 8),
            pw.SizedBox(
              width: 82,
              child: pw.Text(
                detail.label,
                maxLines: 2,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(
                  fontSize: 9.8,
                  fontWeight: pw.FontWeight.bold,
                  color: profile.bodyTextColor,
                ),
              ),
            ),
            pw.SizedBox(width: 5),
            pw.Text(
              ':',
              style: pw.TextStyle(
                fontSize: 10.1,
                fontWeight: pw.FontWeight.bold,
                color: profile.bodyTextColor,
              ),
            ),
            pw.SizedBox(width: 7),
            pw.Expanded(
              child: pw.Text(
                detail.value,
                maxLines: detail.multiline ? 4 : 2,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(
                  fontSize: 10.4,
                  fontWeight: pw.FontWeight.bold,
                  color: detail.highlight
                      ? profile.accentColor
                      : profile.bodyTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _sectionTitle(String title, dynamic profile) {
    return pw.Row(
      children: [
        _iconBadge(_sectionIconKey(title), profile, size: 24, padding: 3),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12.2,
            fontWeight: pw.FontWeight.bold,
            color: profile.accentColor,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  static pw.Widget _headerLine(String iconKey, String value, dynamic profile) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _iconBadge(iconKey, profile, size: 18, padding: 3),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              value,
              maxLines: 2,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(
                fontSize: 10.2,
                fontWeight: pw.FontWeight.bold,
                color: profile.bodyTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _invoiceMeta(String label, String value, dynamic profile) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10.3,
              fontWeight: pw.FontWeight.bold,
              color: profile.bodyTextColor,
            ),
          ),
          pw.SizedBox(width: 5),
          pw.Text(
            ':',
            style: pw.TextStyle(
              fontSize: 10.3,
              fontWeight: pw.FontWeight.bold,
              color: profile.bodyTextColor,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Container(
            width: 98,
            child: pw.Text(
              value,
              maxLines: 2,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(
                fontSize: 10.7,
                fontWeight: pw.FontWeight.bold,
                color: profile.bodyTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _metaText(String label, String value, dynamic profile) {
    return pw.Text(
      '$label: $value',
      style: pw.TextStyle(
        color: profile.headerPrimaryTextColor,
        fontSize: profile.bodyFontSize,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  static pw.Widget _brandMark(LotusPrintableDocument document) {
    final profile = document.profile;
    final logo = _loadLogoImage(document.shopProfile.logoPath);
    if (logo != null) {
      return pw.Container(
        height: 94,
        width: 104,
        alignment: pw.Alignment.center,
        child: pw.Image(logo, fit: pw.BoxFit.contain),
      );
    }
    final shopName = _shopName(document);
    if (shopName.isEmpty) {
      return pw.SizedBox(height: 94, width: 104);
    }
    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Container(
          width: 46,
          height: 46,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: profile.accentColor, width: 1),
            shape: pw.BoxShape.circle,
          ),
          child: pw.Text(
            _initials(shopName),
            style: pw.TextStyle(
              fontSize: 17,
              fontWeight: pw.FontWeight.bold,
              color: profile.accentColor,
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          _firstBrandWord(shopName),
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 19,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1.2,
            color: profile.accentColor,
          ),
        ),
        pw.Text(
          'JEWELLERS',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 7.5,
            letterSpacing: 2,
            color: profile.accentColor,
          ),
        ),
      ],
    );
  }

  static pw.Widget _iconBadge(
    String iconKey,
    dynamic profile, {
    double size = 19,
    double padding = 3.2,
  }) {
    return pw.Container(
      width: size,
      height: size,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: profile.accentColor, width: 0.7),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Padding(
        padding: pw.EdgeInsets.all(padding),
        child: pw.SvgImage(svg: _headerIconSvg(iconKey)),
      ),
    );
  }

  static pw.MemoryImage? _loadLogoImage(String? rawPath) {
    final path = rawPath?.trim() ?? '';
    if (path.isEmpty) return null;
    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      return pw.MemoryImage(file.readAsBytesSync());
    } catch (_) {
      return null;
    }
  }

  static String _shopName(LotusPrintableDocument document) {
    final name = document.shopProfile.primaryName.trim();
    if (name.isNotEmpty) return name;
    return document.useFallbackShopName ? 'Lotus ERP' : '';
  }

  static bool _hasPanelDetails(LotusPrintablePanel panel) {
    return panel.details.any((detail) => detail.value.trim().isNotEmpty);
  }

  static String _shopPhoneLine(LotusPrintableDocument document) {
    final primary = document.shopProfile.primaryPhone.trim();
    final helpDesk = document.shopProfile.valueOf('help_desk_number').trim();
    final phones = <String>[
      if (primary.isNotEmpty) _formatPhone(primary),
      if (helpDesk.isNotEmpty && _digitsOnly(helpDesk) != _digitsOnly(primary))
        _formatPhone(helpDesk),
    ];
    return phones.join('  |  ');
  }

  static String _formatPhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.startsWith('+')) return trimmed;
    final digits = _digitsOnly(trimmed);
    if (digits.length == 10) return '+91 $digits';
    return trimmed;
  }

  static String _compact(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  static String _initials(String value) {
    final words = value
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) return 'LE';
    if (words.length == 1) {
      return words.first
          .substring(0, words.first.length.clamp(1, 2))
          .toUpperCase();
    }
    return '${words.first[0]}${words[1][0]}'.toUpperCase();
  }

  static String _firstBrandWord(String value) {
    final words = value
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .toList(growable: false);
    return words.isEmpty ? 'LOTUS' : words.first.toUpperCase();
  }

  static String _sectionIconKey(String title) {
    final normalized = title.toLowerCase();
    if (normalized.contains('seller') || normalized.contains('bill')) {
      return 'customer';
    }
    if (normalized.contains('voucher') || normalized.contains('invoice')) {
      return 'invoice';
    }
    if (normalized.contains('item')) return 'items';
    if (normalized.contains('payout') || normalized.contains('payment')) {
      return 'payment';
    }
    if (normalized.contains('amount')) return 'amount';
    if (normalized.contains('terms')) return 'policy';
    return 'invoice';
  }

  static String _headerIconSvg(String iconKey) {
    const stroke = '#B8781A';
    switch (iconKey) {
      case 'location':
        return '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 21s6-5.2 6-11a6 6 0 0 0-12 0c0 5.8 6 11 6 11z"/><circle cx="12" cy="10" r="2.2"/></svg>';
      case 'phone':
        return '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.7 19.7 0 0 1-8.6-3.1 19.1 19.1 0 0 1-5.9-5.9A19.7 19.7 0 0 1 2.2 4.2 2 2 0 0 1 4.2 2h3a2 2 0 0 1 2 1.7c.1 1 .4 2 .7 2.8a2 2 0 0 1-.5 2.1L8.1 9.9a16 16 0 0 0 6 6l1.3-1.3a2 2 0 0 1 2.1-.5c.9.3 1.8.6 2.8.7A2 2 0 0 1 22 16.9z"/></svg>';
      case 'mail':
        return '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3 7 9 6 9-6"/></svg>';
      case 'gst':
        return '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="3" width="16" height="18" rx="2"/><path d="M8 8h8"/><path d="M8 12h8"/><path d="M8 16h4"/></svg>';
      case 'customer':
        return '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21a8 8 0 0 0-16 0"/><circle cx="12" cy="7" r="4"/></svg>';
      case 'calendar':
        return '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4"/><path d="M8 3v4"/><path d="M3 10h18"/></svg>';
      case 'status':
        return '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="m8 12 2.5 2.5L16 9"/></svg>';
      case 'items':
        return '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m21 8-9-5-9 5 9 5 9-5z"/><path d="M3 8v8l9 5 9-5V8"/><path d="M12 13v8"/></svg>';
      case 'payment':
        return '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="6" width="18" height="12" rx="2"/><path d="M3 10h18"/><path d="M7 15h4"/></svg>';
      case 'amount':
        return '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="3" width="16" height="18" rx="2"/><path d="M8 8h8"/><path d="M8 12h8"/><path d="M8 16h5"/></svg>';
      case 'policy':
        return '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 3h10l3 3v15H4V3h3z"/><path d="M16 3v4h4"/><path d="M8 11h8"/><path d="M8 15h6"/></svg>';
      case 'invoice':
      default:
        return '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 3h10l3 3v15H4V3h3z"/><path d="M16 3v4h4"/><path d="M8 11h8"/><path d="M8 15h6"/></svg>';
    }
  }
}
