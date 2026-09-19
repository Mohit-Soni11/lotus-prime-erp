part of 'girvi_invoice_pdf_service.dart';

class _GirviInvoiceColumn {
  const _GirviInvoiceColumn({
    required this.header,
    required this.width,
    required this.alignment,
    required this.value,
    this.strong = false,
  });

  final String header;
  final double width;
  final pw.Alignment alignment;
  final String Function(GirviInvoiceItemDraft item) value;
  final bool strong;
}

class _GirviDetailEntry {
  const _GirviDetailEntry({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;
}

class _GirviPhoto {
  const _GirviPhoto({
    required this.serialNo,
    required this.title,
    required this.image,
  });

  final int serialNo;
  final String title;
  final pw.MemoryImage image;
}
