import '../../../../core/pdf/lotus_pdf_text_renderer.dart';
import '../../../../features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import '../../../../logic/purchase/purchase_entry_controller.dart';
import '../../../../models/purchase/purchase_enums/purchase_enums.dart';
import '../../../../models/purchase/purchase_entry/purchase_item_model.dart';
import '../../../../models/setting/billing_setup/purchase_billing_model.dart';
import '../../domain/print_template_pdf_profile.dart';
import '../../domain/print_template_registry.dart';

class PurchaseVoucherTemplateRenderContext {
  final PurchaseEntryController controller;
  final List<PurchaseItemModel> lines;
  final Map<PurchaseMetalType, PurchaseBillingModel> settingsByMetal;
  final ShopPrintDocumentProfile shopProfile;
  final LotusPdfTextRenderer textRenderer;
  final PrintTemplateDefinition selectedTemplate;
  final PrintTemplatePdfProfile templateProfile;
  final String sourceLabel;
  final String documentTitle;
  final String documentNumber;
  final String documentDate;

  const PurchaseVoucherTemplateRenderContext({
    required this.controller,
    required this.lines,
    required this.settingsByMetal,
    required this.shopProfile,
    required this.textRenderer,
    required this.selectedTemplate,
    required this.templateProfile,
    required this.sourceLabel,
    required this.documentTitle,
    required this.documentNumber,
    required this.documentDate,
  });
}
