import 'package:pdf/pdf.dart';

import 'print_template_registry.dart';

class PrintTemplatePdfProfile {
  final String templateId;
  final PdfColor accentColor;
  final PdfColor headerColor;
  final PdfColor headerBorderColor;
  final PdfColor headerPrimaryTextColor;
  final PdfColor headerSecondaryTextColor;
  final PdfColor panelColor;
  final PdfColor policyPanelColor;
  final PdfColor summaryColor;
  final PdfColor borderColor;
  final PdfColor bodyTextColor;
  final PdfColor tableHeaderColor;
  final PdfColor tableHeaderTextColor;
  final PdfColor tableBorderColor;
  final PdfColor duplicateStampColor;
  final PdfColor duplicateStampTextColor;
  final double headerBorderWidth;
  final double borderWidth;
  final double tableBorderWidth;
  final double radius;
  final double headerPadding;
  final double panelPadding;
  final double tableCellPadding;
  final double sectionGap;
  final double titleFontSize;
  final double documentTitleFontSize;
  final double labelFontSize;
  final double bodyFontSize;
  final double tableFontSize;
  final double policyFontSize;
  final double summaryWidth;

  const PrintTemplatePdfProfile({
    required this.templateId,
    required this.accentColor,
    required this.headerColor,
    required this.headerBorderColor,
    required this.headerPrimaryTextColor,
    required this.headerSecondaryTextColor,
    required this.panelColor,
    required this.policyPanelColor,
    required this.summaryColor,
    required this.borderColor,
    required this.bodyTextColor,
    required this.tableHeaderColor,
    required this.tableHeaderTextColor,
    required this.tableBorderColor,
    required this.duplicateStampColor,
    required this.duplicateStampTextColor,
    required this.headerBorderWidth,
    required this.borderWidth,
    required this.tableBorderWidth,
    required this.radius,
    required this.headerPadding,
    required this.panelPadding,
    required this.tableCellPadding,
    required this.sectionGap,
    required this.titleFontSize,
    required this.documentTitleFontSize,
    required this.labelFontSize,
    required this.bodyFontSize,
    required this.tableFontSize,
    required this.policyFontSize,
    required this.summaryWidth,
  });

  bool get isClassic => templateId == PrintTemplateRegistry.lotusClassic.id;

  bool get isEconomy => templateId == PrintTemplateRegistry.lotusEconomy.id;

  bool get isSignature => templateId == PrintTemplateRegistry.lotusSignature.id;

  factory PrintTemplatePdfProfile.forTemplate(String templateId) {
    final template = PrintTemplateRegistry.byId(templateId);

    if (template.id == PrintTemplateRegistry.lotusEconomy.id) {
      return economy;
    }
    if (template.id == PrintTemplateRegistry.lotusSignature.id) {
      return signature;
    }
    return classic;
  }

  static const classic = PrintTemplatePdfProfile(
    templateId: PrintTemplateRegistry.defaultTemplateId,
    accentColor: PdfColor.fromInt(0xFFD4AF37),
    headerColor: PdfColor.fromInt(0xFF111827),
    headerBorderColor: PdfColor.fromInt(0xFFD4AF37),
    headerPrimaryTextColor: PdfColors.white,
    headerSecondaryTextColor: PdfColor.fromInt(0xFFE5E7EB),
    panelColor: PdfColor.fromInt(0xFFF9F6F0),
    policyPanelColor: PdfColors.white,
    summaryColor: PdfColor.fromInt(0xFFFFF8E1),
    borderColor: PdfColor.fromInt(0xFFD4AF37),
    bodyTextColor: PdfColors.black,
    tableHeaderColor: PdfColor.fromInt(0xFF111827),
    tableHeaderTextColor: PdfColors.white,
    tableBorderColor: PdfColor.fromInt(0xFFD4AF37),
    duplicateStampColor: PdfColor.fromInt(0xFFFFF8E1),
    duplicateStampTextColor: PdfColors.black,
    headerBorderWidth: 1,
    borderWidth: 0.75,
    tableBorderWidth: 0.55,
    radius: 6,
    headerPadding: 12,
    panelPadding: 11,
    tableCellPadding: 5.2,
    sectionGap: 16,
    titleFontSize: 18.5,
    documentTitleFontSize: 16,
    labelFontSize: 9,
    bodyFontSize: 8.8,
    tableFontSize: 8,
    policyFontSize: 8.4,
    summaryWidth: 240,
  );

  static const economy = PrintTemplatePdfProfile(
    templateId: 'lotus_economy',
    accentColor: PdfColors.black,
    headerColor: PdfColors.white,
    headerBorderColor: PdfColors.black,
    headerPrimaryTextColor: PdfColors.black,
    headerSecondaryTextColor: PdfColors.black,
    panelColor: PdfColors.white,
    policyPanelColor: PdfColors.white,
    summaryColor: PdfColors.white,
    borderColor: PdfColors.grey700,
    bodyTextColor: PdfColors.black,
    tableHeaderColor: PdfColors.grey300,
    tableHeaderTextColor: PdfColors.black,
    tableBorderColor: PdfColors.grey700,
    duplicateStampColor: PdfColors.grey300,
    duplicateStampTextColor: PdfColors.black,
    headerBorderWidth: 0.9,
    borderWidth: 0.7,
    tableBorderWidth: 0.45,
    radius: 0,
    headerPadding: 9,
    panelPadding: 9,
    tableCellPadding: 4.2,
    sectionGap: 12,
    titleFontSize: 17,
    documentTitleFontSize: 15,
    labelFontSize: 8.6,
    bodyFontSize: 8.6,
    tableFontSize: 7.8,
    policyFontSize: 8.2,
    summaryWidth: 230,
  );

  static const signature = PrintTemplatePdfProfile(
    templateId: 'lotus_signature',
    accentColor: PdfColor(0.72, 0.47, 0.10),
    headerColor: PdfColors.white,
    headerBorderColor: PdfColor(0.72, 0.47, 0.10),
    headerPrimaryTextColor: PdfColors.black,
    headerSecondaryTextColor: PdfColors.black,
    panelColor: PdfColors.white,
    policyPanelColor: PdfColors.white,
    summaryColor: PdfColor(0.98, 0.95, 0.88),
    borderColor: PdfColor(0.76, 0.67, 0.53),
    bodyTextColor: PdfColors.black,
    tableHeaderColor: PdfColor(0.98, 0.95, 0.88),
    tableHeaderTextColor: PdfColors.black,
    tableBorderColor: PdfColor(0.76, 0.67, 0.53),
    duplicateStampColor: PdfColor(0.98, 0.95, 0.88),
    duplicateStampTextColor: PdfColors.black,
    headerBorderWidth: 0,
    borderWidth: 0.8,
    tableBorderWidth: 0.55,
    radius: 7,
    headerPadding: 13,
    panelPadding: 11,
    tableCellPadding: 5.5,
    sectionGap: 16,
    titleFontSize: 19,
    documentTitleFontSize: 16.5,
    labelFontSize: 9.2,
    bodyFontSize: 9,
    tableFontSize: 8.1,
    policyFontSize: 8.4,
    summaryWidth: 245,
  );
}
