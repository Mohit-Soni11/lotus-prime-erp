enum PrintTemplateDocumentType {
  salesInvoice,
  salesReturn,
  purchaseVoucher,
  purchaseReturn,
  bookingAdvance,
  girviReceipt,
}

class PrintTemplateDefinition {
  final String id;
  final String name;
  final String shortName;
  final String description;
  final String designReference;
  final bool isSystemDefault;
  final List<PrintTemplateDocumentType> supportedDocuments;

  const PrintTemplateDefinition({
    required this.id,
    required this.name,
    required this.shortName,
    required this.description,
    required this.designReference,
    required this.isSystemDefault,
    required this.supportedDocuments,
  });

  bool supports(PrintTemplateDocumentType type) {
    return supportedDocuments.contains(type);
  }
}

class PrintTemplateRegistry {
  PrintTemplateRegistry._();

  static const String defaultTemplateId = 'default';

  static const PrintTemplateDefinition lotusClassic = PrintTemplateDefinition(
    id: defaultTemplateId,
    name: 'Lotus Classic Invoice',
    shortName: 'Lotus Classic',
    description:
        'Premium navy and gold invoice format based on the Girvi receipt layout.',
    designReference:
        'Girvi receipt header, brand panel, customer block, item table and settlement flow.',
    isSystemDefault: true,
    supportedDocuments: [
      PrintTemplateDocumentType.salesInvoice,
      PrintTemplateDocumentType.salesReturn,
      PrintTemplateDocumentType.purchaseVoucher,
      PrintTemplateDocumentType.purchaseReturn,
      PrintTemplateDocumentType.bookingAdvance,
      PrintTemplateDocumentType.girviReceipt,
    ],
  );

  static const PrintTemplateDefinition lotusEconomy = PrintTemplateDefinition(
    id: 'lotus_economy',
    name: 'Lotus Economy Tax Invoice',
    shortName: 'Lotus Economy',
    description:
        'Low-ink statutory A4 invoice with compact tables, thin borders and clean GST totals.',
    designReference:
        'Professional monochrome tax invoice optimized for daily printing and accounting records.',
    isSystemDefault: false,
    supportedDocuments: [
      PrintTemplateDocumentType.salesInvoice,
      PrintTemplateDocumentType.salesReturn,
      PrintTemplateDocumentType.purchaseVoucher,
    ],
  );

  static const PrintTemplateDefinition lotusSignature = PrintTemplateDefinition(
    id: 'lotus_signature',
    name: 'Lotus Signature Tax Invoice',
    shortName: 'Lotus Signature',
    description:
        'Elegant white and gold jewellery tax invoice with refined customer, item and settlement sections.',
    designReference:
        'Premium branded A4 invoice inspired by luxury jewellery bill formats.',
    isSystemDefault: false,
    supportedDocuments: [
      PrintTemplateDocumentType.salesInvoice,
      PrintTemplateDocumentType.salesReturn,
      PrintTemplateDocumentType.purchaseVoucher,
    ],
  );

  static const List<PrintTemplateDefinition> templates = [
    lotusClassic,
    lotusEconomy,
    lotusSignature,
  ];

  static List<String> get templateIds {
    return templates.map((template) => template.id).toList(growable: false);
  }

  static List<PrintTemplateDefinition> forDocument(
    PrintTemplateDocumentType type,
  ) {
    return templates
        .where((template) => template.supports(type))
        .toList(growable: false);
  }

  static PrintTemplateDefinition byId(String id) {
    final normalized = id.trim();
    for (final template in templates) {
      if (template.id == normalized) return template;
    }
    return lotusClassic;
  }

  static String labelFor(String id) {
    return byId(id).shortName;
  }
}

extension PrintTemplateDocumentTypeLabel on PrintTemplateDocumentType {
  String get label {
    switch (this) {
      case PrintTemplateDocumentType.salesInvoice:
        return 'Sales Invoice';
      case PrintTemplateDocumentType.salesReturn:
        return 'Sales Return';
      case PrintTemplateDocumentType.purchaseVoucher:
        return 'Customer Metal Purchase Voucher';
      case PrintTemplateDocumentType.purchaseReturn:
        return 'Purchase Return';
      case PrintTemplateDocumentType.bookingAdvance:
        return 'Booking Advance';
      case PrintTemplateDocumentType.girviReceipt:
        return 'Girvi Receipt';
    }
  }
}
