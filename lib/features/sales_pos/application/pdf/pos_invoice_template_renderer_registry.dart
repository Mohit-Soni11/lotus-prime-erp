import 'package:pdf/widgets.dart' as pw;

import '../../../../features/print_templates/domain/print_template_registry.dart';
import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import '../services/pos_invoice_scope_service.dart';
import 'pos_invoice_print_config.dart';
import 'pos_lotus_classic_invoice_pdf_layout.dart';

class PosInvoiceTemplateRenderContext {
  final PosInvoiceScopeService scopeService;
  final Map<MetalType, BillSettings> metalPrintSettings;
  final bool includePolicyBlock;

  const PosInvoiceTemplateRenderContext({
    required this.scopeService,
    required this.metalPrintSettings,
    this.includePolicyBlock = true,
  });
}

typedef PosInvoiceTemplateRenderer = pw.Widget Function(
  PosInvoiceModel invoice,
  PosInvoiceTemplateRenderContext context,
);

class PosInvoiceTemplateRendererRegistry {
  PosInvoiceTemplateRendererRegistry._();

  static final Map<String, PosInvoiceTemplateRenderer> _a4Renderers = {
    PrintTemplateRegistry.defaultTemplateId: (invoice, context) {
      return PosLotusClassicInvoicePdfLayout(
        scopeService: context.scopeService,
        metalPrintSettings: context.metalPrintSettings,
      ).build(
        invoice,
        includePolicyBlock: context.includePolicyBlock,
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
}
