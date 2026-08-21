import '../../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';

class PosInvoiceShopHeaderDetails {
  final String shopName;
  final List<PosInvoiceShopHeaderLine> lines;

  const PosInvoiceShopHeaderDetails({
    required this.shopName,
    required this.lines,
  });

  factory PosInvoiceShopHeaderDetails.fromInvoice(PosInvoiceModel invoice) {
    final address = _firstPresent([
      invoice.shopPrintValue('business_address'),
      invoice.printShopAddress,
      invoice.shopAddress,
    ]);
    final mobile = _firstPresent([
      invoice.shopPrintValue('mobile_number'),
      invoice.printShopPhone,
      invoice.shopPhone,
    ]);
    final email = _firstPresent([
      invoice.shopPrintValue('business_email'),
    ]);
    final gstin = _firstPresent([
      invoice.shopPrintValue('gstin'),
      invoice.printShopGstin,
      invoice.shopGstin,
    ]);

    return PosInvoiceShopHeaderDetails(
      shopName: _firstPresent([invoice.printShopName, invoice.shopName]),
      lines: [
        if (address.isNotEmpty)
          PosInvoiceShopHeaderLine(label: 'Address', value: address),
        if (mobile.isNotEmpty)
          PosInvoiceShopHeaderLine(
            label: 'Mobile',
            value: _formatPhone(mobile),
          ),
        if (email.isNotEmpty)
          PosInvoiceShopHeaderLine(label: 'Email', value: email),
        if (_isRegisteredGstin(gstin))
          PosInvoiceShopHeaderLine(label: 'GSTIN', value: gstin),
      ],
    );
  }

  List<String> get thermalLines {
    return lines
        .map((line) => '${line.label}: ${line.value}')
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
  }

  static bool _isRegisteredGstin(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.isNotEmpty && normalized != 'not registered';
  }

  static String _formatPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    return value.trim();
  }

  static String _firstPresent(Iterable<String> values) {
    for (final value in values) {
      final cleaned = value.trim();
      if (cleaned.isNotEmpty) return cleaned;
    }
    return '';
  }
}

class PosInvoiceShopHeaderLine {
  final String label;
  final String value;

  const PosInvoiceShopHeaderLine({
    required this.label,
    required this.value,
  });
}
