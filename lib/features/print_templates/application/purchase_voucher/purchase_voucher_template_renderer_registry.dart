import 'package:pdf/widgets.dart' as pw;

import '../../domain/print_template_registry.dart';
import 'purchase_voucher_pdf_layout_engine.dart';
import 'purchase_voucher_template_context.dart';

typedef PurchaseVoucherTemplateRenderer = List<pw.Widget> Function(
  PurchaseVoucherTemplateRenderContext context, {
  required bool isDuplicateCopy,
});

class PurchaseVoucherTemplateRendererRegistry {
  PurchaseVoucherTemplateRendererRegistry._();

  static final Map<String, PurchaseVoucherTemplateRenderer> _a4Renderers = {
    PrintTemplateRegistry.defaultTemplateId: (context,
        {required isDuplicateCopy}) {
      return const PurchaseLotusClassicVoucherPdfLayout().build(
        context,
        isDuplicateCopy: isDuplicateCopy,
      );
    },
    PrintTemplateRegistry.lotusEconomy.id: (context,
        {required isDuplicateCopy}) {
      return const PurchaseLotusEconomyVoucherPdfLayout().build(
        context,
        isDuplicateCopy: isDuplicateCopy,
      );
    },
    PrintTemplateRegistry.lotusSignature.id: (context,
        {required isDuplicateCopy}) {
      return const PurchaseLotusSignatureVoucherPdfLayout().build(
        context,
        isDuplicateCopy: isDuplicateCopy,
      );
    },
  };

  static List<pw.Widget> buildA4({
    required String templateId,
    required PurchaseVoucherTemplateRenderContext context,
    required bool isDuplicateCopy,
  }) {
    final resolvedTemplate = PrintTemplateRegistry.byId(templateId);
    final renderer = _a4Renderers[resolvedTemplate.id] ??
        _a4Renderers[PrintTemplateRegistry.defaultTemplateId]!;
    return renderer(context, isDuplicateCopy: isDuplicateCopy);
  }
}

class PurchaseLotusClassicVoucherPdfLayout {
  const PurchaseLotusClassicVoucherPdfLayout();

  List<pw.Widget> build(
    PurchaseVoucherTemplateRenderContext context, {
    required bool isDuplicateCopy,
  }) {
    return PurchaseVoucherPdfLayoutEngine.buildClassicOrEconomy(
      context,
      isDuplicateCopy: isDuplicateCopy,
    );
  }
}

class PurchaseLotusEconomyVoucherPdfLayout {
  const PurchaseLotusEconomyVoucherPdfLayout();

  List<pw.Widget> build(
    PurchaseVoucherTemplateRenderContext context, {
    required bool isDuplicateCopy,
  }) {
    return PurchaseVoucherPdfLayoutEngine.buildClassicOrEconomy(
      context,
      isDuplicateCopy: isDuplicateCopy,
    );
  }
}

class PurchaseLotusSignatureVoucherPdfLayout {
  const PurchaseLotusSignatureVoucherPdfLayout();

  List<pw.Widget> build(
    PurchaseVoucherTemplateRenderContext context, {
    required bool isDuplicateCopy,
  }) {
    return PurchaseVoucherPdfLayoutEngine.buildSignature(
      context,
      isDuplicateCopy: isDuplicateCopy,
    );
  }
}
