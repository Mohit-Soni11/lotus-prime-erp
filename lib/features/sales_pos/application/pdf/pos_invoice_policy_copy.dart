import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import '../services/pos_invoice_scope_service.dart';
import 'pos_invoice_print_config.dart';

enum PosInvoicePolicySection {
  termsAndConditions('Terms & Conditions'),
  returnPolicy('Return Policy'),
  buybackPolicy('Buyback Policy');

  final String label;

  const PosInvoicePolicySection(this.label);
}

class PosInvoicePolicyEntry {
  final MetalType metal;
  final PosInvoicePolicySection section;
  final String body;

  const PosInvoicePolicyEntry({
    required this.metal,
    required this.section,
    required this.body,
  });

  String get title => '${metal.displayName} ${section.label}';
}

class PosInvoicePolicyCopy {
  PosInvoicePolicyCopy._();

  static List<PosInvoicePolicyEntry> entries({
    required PosInvoiceModel invoice,
    required PosInvoiceScopeService scopeService,
    required Map<MetalType, BillSettings> metalPrintSettings,
  }) {
    final entries = <PosInvoicePolicyEntry>[];

    for (final metal in scopeService.collectMetals(invoice)) {
      final config = metalPrintSettings[metal] ?? BillSettings();
      if (config.printTermsAndConditions &&
          hasPrintableCopy(config.termsAndConditions)) {
        entries.add(
          PosInvoicePolicyEntry(
            metal: metal,
            section: PosInvoicePolicySection.termsAndConditions,
            body: config.termsAndConditions,
          ),
        );
      }
      if (config.printReturnPolicy &&
          hasPrintableCopy(config.returnPolicyText)) {
        entries.add(
          PosInvoicePolicyEntry(
            metal: metal,
            section: PosInvoicePolicySection.returnPolicy,
            body: config.returnPolicyText,
          ),
        );
      }
      if (config.printBuybackPolicy &&
          hasPrintableCopy(config.buybackPolicyText)) {
        entries.add(
          PosInvoicePolicyEntry(
            metal: metal,
            section: PosInvoicePolicySection.buybackPolicy,
            body: config.buybackPolicyText,
          ),
        );
      }
    }

    return entries;
  }

  static bool hasPrintableCopy(String value) {
    return value.trim().isNotEmpty;
  }

  static List<String> lines(
    String value, {
    bool keepBlankLines = true,
  }) {
    final lines = value
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.trimRight())
        .toList(growable: false);

    if (keepBlankLines) return lines;
    return lines
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
  }

  static List<List<String>> bilingualGroups(String body) {
    final groups = <List<String>>[];
    var current = <String>[];

    void flush() {
      if (current.isEmpty) return;
      groups.add(current);
      current = <String>[];
    }

    for (final rawLine in lines(body)) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        flush();
        continue;
      }

      final isTranslationLine = containsDevanagari(line);
      final currentHasTranslation = current.any(containsDevanagari);
      final shouldStartNewGroup = current.isEmpty ||
          (!isTranslationLine && current.isNotEmpty) ||
          (isTranslationLine && currentHasTranslation);

      if (shouldStartNewGroup) {
        flush();
      }
      current.add(line);
    }

    flush();
    return groups;
  }

  static bool containsDevanagari(String value) {
    return RegExp(r'[\u0900-\u097F]').hasMatch(value);
  }
}
