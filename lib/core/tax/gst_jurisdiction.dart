class GstJurisdiction {
  const GstJurisdiction({
    required this.shopStateCode,
    required this.placeOfSupplyStateCode,
    required this.placeOfSupplyName,
    required this.isInterState,
    required this.isResolved,
  });

  final String shopStateCode;
  final String placeOfSupplyStateCode;
  final String placeOfSupplyName;
  final bool isInterState;
  final bool isResolved;

  String get supplyType => isInterState ? 'INTER_STATE' : 'INTRA_STATE';
}

class GstTaxSplit {
  const GstTaxSplit({
    required this.cgst,
    required this.sgst,
    required this.igst,
  });

  final double cgst;
  final double sgst;
  final double igst;

  double get total => GstJurisdictionResolver.roundMoney(cgst + sgst + igst);
}

class GstinValidationResult {
  const GstinValidationResult({
    required this.isEmpty,
    required this.isValidFormat,
    required this.stateCode,
  });

  final bool isEmpty;
  final bool isValidFormat;
  final String stateCode;
}

class GstJurisdictionResolver {
  const GstJurisdictionResolver._();

  static GstJurisdiction resolve({
    required String shopGstin,
    required String shopStateCode,
    required String shopStateName,
    required String customerGstin,
    required String customerStateCode,
    required String customerStateName,
    required String placeOfSupply,
  }) {
    final supplierCode = firstStateCode([
      shopStateCode,
      stateCodeFromGstin(shopGstin),
      stateCodeFromText(shopStateName),
    ]);
    final supplyCode = firstStateCode([
      customerStateCode,
      stateCodeFromGstin(customerGstin),
      stateCodeFromText(placeOfSupply),
      stateCodeFromText(customerStateName),
    ]);
    final supplyName = firstText([
      canonicalStateName(supplyCode),
      stateNameFromText(placeOfSupply),
      stateNameFromText(customerStateName),
      placeOfSupply,
      customerStateName,
    ]);

    return GstJurisdiction(
      shopStateCode: supplierCode,
      placeOfSupplyStateCode: supplyCode,
      placeOfSupplyName: supplyName,
      isInterState: supplierCode.isNotEmpty &&
          supplyCode.isNotEmpty &&
          supplierCode != supplyCode,
      isResolved: supplierCode.isNotEmpty && supplyCode.isNotEmpty,
    );
  }

  static GstTaxSplit splitOutputTax({
    required double totalGst,
    required GstJurisdiction jurisdiction,
    double storedCgst = 0,
    double storedSgst = 0,
    double storedIgst = 0,
  }) {
    final roundedTotal = roundMoney(totalGst);
    if (roundedTotal.abs() <= 0.005) {
      return const GstTaxSplit(cgst: 0, sgst: 0, igst: 0);
    }
    if (jurisdiction.isResolved) {
      if (jurisdiction.isInterState) {
        return GstTaxSplit(cgst: 0, sgst: 0, igst: roundedTotal);
      }
      final half = roundMoney(roundedTotal / 2);
      return GstTaxSplit(cgst: half, sgst: half, igst: 0);
    }
    final roundedIgst = roundMoney(storedIgst);
    if (roundedIgst.abs() > 0.005) {
      return GstTaxSplit(cgst: 0, sgst: 0, igst: roundedTotal);
    }
    final storedSplit = roundMoney(storedCgst + storedSgst);
    if ((storedSplit - roundedTotal).abs() <= 0.02 &&
        storedCgst.abs() > 0.005 &&
        storedSgst.abs() > 0.005) {
      return GstTaxSplit(
        cgst: roundMoney(storedCgst),
        sgst: roundMoney(roundedTotal - roundMoney(storedCgst)),
        igst: 0,
      );
    }
    final half = roundMoney(roundedTotal / 2);
    return GstTaxSplit(cgst: half, sgst: half, igst: 0);
  }

  static GstinValidationResult validateGstin(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized.isEmpty) {
      return const GstinValidationResult(
        isEmpty: true,
        isValidFormat: false,
        stateCode: '',
      );
    }
    final format = RegExp(
      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$',
    );
    final stateCode = stateCodeFromGstin(normalized);
    return GstinValidationResult(
      isEmpty: false,
      isValidFormat:
          format.hasMatch(normalized) && _stateNames.containsKey(stateCode),
      stateCode: stateCode,
    );
  }

  static String firstStateCode(Iterable<String?> values) {
    for (final value in values) {
      final code = stateCodeFromText(value ?? '');
      if (code.isNotEmpty) return code;
    }
    return '';
  }

  static String stateCodeFromGstin(String? gstin) {
    final normalized = gstin?.trim().toUpperCase() ?? '';
    if (normalized.length < 2) return '';
    final prefix = normalized.substring(0, 2);
    return _stateNames.containsKey(prefix) ? prefix : '';
  }

  static String stateCodeFromText(String? value) {
    final normalized = _normalize(value ?? '');
    if (normalized.isEmpty) return '';
    final directCode =
        RegExp(r'^\d{2}$').hasMatch(normalized) ? normalized : '';
    if (_stateNames.containsKey(directCode)) return directCode;
    final gstCode = stateCodeFromGstin(normalized);
    if (gstCode.isNotEmpty) return gstCode;
    for (final entry in _stateAliases.entries) {
      if (normalized == entry.key) {
        return entry.value;
      }
    }
    for (final entry in _stateAliases.entries) {
      if (entry.key.length > 3 && normalized.contains(entry.key)) {
        return entry.value;
      }
    }
    return '';
  }

  static String canonicalStateName(String stateCode) {
    return _stateNames[stateCode.trim()] ?? '';
  }

  static String stateNameFromText(String? value) {
    final code = stateCodeFromText(value);
    return canonicalStateName(code);
  }

  static String firstText(Iterable<String?> values) {
    for (final value in values) {
      final clean = value?.trim() ?? '';
      if (clean.isNotEmpty) return clean;
    }
    return '';
  }

  static double roundMoney(double value) => (value * 100).round() / 100;

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}

const Map<String, String> _stateNames = {
  '01': 'Jammu and Kashmir',
  '02': 'Himachal Pradesh',
  '03': 'Punjab',
  '04': 'Chandigarh',
  '05': 'Uttarakhand',
  '06': 'Haryana',
  '07': 'Delhi',
  '08': 'Rajasthan',
  '09': 'Uttar Pradesh',
  '10': 'Bihar',
  '11': 'Sikkim',
  '12': 'Arunachal Pradesh',
  '13': 'Nagaland',
  '14': 'Manipur',
  '15': 'Mizoram',
  '16': 'Tripura',
  '17': 'Meghalaya',
  '18': 'Assam',
  '19': 'West Bengal',
  '20': 'Jharkhand',
  '21': 'Odisha',
  '22': 'Chhattisgarh',
  '23': 'Madhya Pradesh',
  '24': 'Gujarat',
  '26': 'Dadra and Nagar Haveli and Daman and Diu',
  '27': 'Maharashtra',
  '29': 'Karnataka',
  '30': 'Goa',
  '31': 'Lakshadweep',
  '32': 'Kerala',
  '33': 'Tamil Nadu',
  '34': 'Puducherry',
  '35': 'Andaman and Nicobar Islands',
  '36': 'Telangana',
  '37': 'Andhra Pradesh',
  '38': 'Ladakh',
  '97': 'Other Territory',
};

final Map<String, String> _stateAliases = {
  for (final entry in _stateNames.entries)
    _normalizeForAlias(entry.value): entry.key,
  'jammu kashmir': '01',
  'himachal': '02',
  'uttaranchal': '05',
  'uttrakhand': '05',
  'new delhi': '07',
  'delhi': '07',
  'up': '09',
  'u p': '09',
  'wb': '19',
  'west bengal': '19',
  'orissa': '21',
  'mp': '23',
  'm p': '23',
  'dadra nagar haveli daman diu': '26',
  'daman diu': '26',
  'dnrhdd': '26',
  'pondicherry': '34',
  'andaman nicobar': '35',
  'telengana': '36',
  'ap': '37',
  'a p': '37',
};

String _normalizeForAlias(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
}
