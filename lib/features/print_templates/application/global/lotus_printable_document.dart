import '../../../../features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import '../../domain/print_template_pdf_profile.dart';
import '../../domain/print_template_registry.dart';

class LotusPrintableDocument {
  final ShopPrintDocumentProfile shopProfile;
  final PrintTemplateDefinition template;
  final PrintTemplatePdfProfile profile;
  final String title;
  final String subtitle;
  final String documentNumberLabel;
  final String documentNumber;
  final String documentDateLabel;
  final String documentDate;
  final String badgeLabel;
  final LotusPrintablePanel primaryPanel;
  final LotusPrintablePanel secondaryPanel;
  final LotusPrintableTable itemTable;
  final List<LotusPrintablePanel> settlementPanels;
  final List<LotusPrintablePolicySection> policySections;
  final String footerMessage;
  final bool showHeaderDocumentMeta;
  final bool showHeaderBadge;

  const LotusPrintableDocument({
    required this.shopProfile,
    required this.template,
    required this.profile,
    required this.title,
    required this.subtitle,
    required this.documentNumberLabel,
    required this.documentNumber,
    required this.documentDateLabel,
    required this.documentDate,
    required this.badgeLabel,
    required this.primaryPanel,
    required this.secondaryPanel,
    required this.itemTable,
    required this.settlementPanels,
    required this.policySections,
    required this.footerMessage,
    this.showHeaderDocumentMeta = true,
    this.showHeaderBadge = true,
  });
}

class LotusPrintablePanel {
  final String title;
  final List<LotusPrintableDetail> details;

  const LotusPrintablePanel({
    required this.title,
    required this.details,
  });
}

class LotusPrintableDetail {
  final String iconKey;
  final String label;
  final String value;
  final bool multiline;
  final bool highlight;

  const LotusPrintableDetail({
    required this.iconKey,
    required this.label,
    required this.value,
    this.multiline = false,
    this.highlight = false,
  });
}

class LotusPrintableTable {
  final String title;
  final List<String> headers;
  final List<List<String>> rows;

  const LotusPrintableTable({
    required this.title,
    required this.headers,
    required this.rows,
  });
}

class LotusPrintablePolicySection {
  final String title;
  final String body;

  const LotusPrintablePolicySection({
    required this.title,
    required this.body,
  });
}
