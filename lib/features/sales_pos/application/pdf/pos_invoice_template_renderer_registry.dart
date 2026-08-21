import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../features/print_templates/domain/print_template_registry.dart';
import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import '../services/pos_invoice_scope_service.dart';
import 'pos_invoice_print_config.dart';
import 'pos_invoice_pdf_text_renderer.dart';
import 'pos_lotus_economy_invoice_pdf_layout.dart';
import 'pos_lotus_classic_invoice_pdf_layout.dart';
import 'pos_lotus_signature_invoice_pdf_layout.dart';

class PosInvoiceTemplateRenderContext {
  final PosInvoiceScopeService scopeService;
  final Map<MetalType, BillSettings> metalPrintSettings;
  final bool includePolicyBlock;
  final PosInvoicePdfTextRenderer? textRenderer;

  const PosInvoiceTemplateRenderContext({
    required this.scopeService,
    required this.metalPrintSettings,
    this.includePolicyBlock = true,
    this.textRenderer,
  });
}

typedef PosInvoiceTemplateRenderer = pw.Widget Function(
  PosInvoiceModel invoice,
  PosInvoiceTemplateRenderContext context,
);

typedef PosInvoiceTemplatePolicyPageRenderer = void Function({
  required pw.Document doc,
  required PosInvoiceModel invoice,
  required PdfPageFormat pageFormat,
  required PosInvoiceTemplateRenderContext context,
  required bool includeDuplicateStamp,
});

class PosInvoiceTemplateRendererRegistry {
  PosInvoiceTemplateRendererRegistry._();

  static final Map<String, PosInvoiceTemplateRenderer> _a4Renderers = {
    PrintTemplateRegistry.defaultTemplateId: (invoice, context) {
      return PosLotusClassicInvoicePdfLayout(
        scopeService: context.scopeService,
        metalPrintSettings: context.metalPrintSettings,
        textRenderer: context.textRenderer,
      ).build(
        invoice,
        includePolicyBlock: context.includePolicyBlock,
      );
    },
    PrintTemplateRegistry.lotusEconomy.id: (invoice, context) {
      return PosLotusEconomyInvoicePdfLayout(
        scopeService: context.scopeService,
        metalPrintSettings: context.metalPrintSettings,
        textRenderer: context.textRenderer,
      ).build(
        invoice,
        includePolicyBlock: context.includePolicyBlock,
      );
    },
    PrintTemplateRegistry.lotusSignature.id: (invoice, context) {
      return PosLotusSignatureInvoicePdfLayout(
        scopeService: context.scopeService,
        metalPrintSettings: context.metalPrintSettings,
        textRenderer: context.textRenderer,
      ).build(
        invoice,
        includePolicyBlock: context.includePolicyBlock,
      );
    },
  };

  static final Map<String, PosInvoiceTemplatePolicyPageRenderer>
      _a4PolicyRenderers = {
    PrintTemplateRegistry.lotusSignature.id: ({
      required doc,
      required invoice,
      required pageFormat,
      required context,
      required includeDuplicateStamp,
    }) {
      PosLotusSignatureInvoicePdfLayout(
        scopeService: context.scopeService,
        metalPrintSettings: context.metalPrintSettings,
        textRenderer: context.textRenderer,
      ).addPolicyPages(
        doc,
        invoice,
        pageFormat,
        includeDuplicateStamp: includeDuplicateStamp,
      );
    },
  };

  static pw.Widget? tryBuildA4({
    required String templateId,
    required PosInvoiceModel invoice,
    required PosInvoiceTemplateRenderContext context,
  }) {
    final resolvedTemplate = PrintTemplateRegistry.byId(templateId);
    final renderer = _a4Renderers[resolvedTemplate.id];
    if (renderer == null) return null;
    return renderer(invoice, context);
  }

  static bool hasA4Renderer(String templateId) {
    return _a4Renderers.containsKey(PrintTemplateRegistry.byId(templateId).id);
  }

  static bool tryAddA4PolicyPages({
    required String templateId,
    required pw.Document doc,
    required PosInvoiceModel invoice,
    required PdfPageFormat pageFormat,
    required PosInvoiceTemplateRenderContext context,
    required bool includeDuplicateStamp,
  }) {
    final resolvedTemplate = PrintTemplateRegistry.byId(templateId);
    final renderer = _a4PolicyRenderers[resolvedTemplate.id];
    if (renderer == null) return false;
    renderer(
      doc: doc,
      invoice: invoice,
      pageFormat: pageFormat,
      context: context,
      includeDuplicateStamp: includeDuplicateStamp,
    );
    return true;
  }
}
