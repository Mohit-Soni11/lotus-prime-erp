part of 'return_reversal_drift_repository.dart';

extension _ReturnReversalRepositoryUtilities on ReturnReversalDriftRepository {
  Future<Map<int, _PostedReturnLine>> _reversalLinesFor({
    required String sourceType,
    required int sourceId,
  }) async {
    final rows = await _database.customSelect(
      '''
      SELECT
        l.source_line_no,
        l.status,
        v.voucher_no,
        l.stock_disposition,
        l.received_net_weight,
        l.metal_return_amount,
        l.making_returned_amount,
        l.line_return_value,
        l.huid_matched,
        l.unit_matched,
        l.created_at
      FROM return_voucher_lines l
      INNER JOIN return_vouchers v ON v.id = l.return_voucher_id
      WHERE l.source_type = ?
        AND l.source_id = ?
        AND l.status <> 'VOIDED'
      ''',
      variables: [
        drift.Variable.withString(sourceType),
        drift.Variable.withInt(sourceId),
      ],
    ).get();
    return {
      for (final row in rows)
        row.read<int>('source_line_no'): _PostedReturnLine(
          status: row.readNullable<String>('status') ?? 'POSTED',
          voucherNo: row.readNullable<String>('voucher_no') ?? '',
          stockDisposition: row.readNullable<String>('stock_disposition') ?? '',
          receivedNetWeight: _readDouble(row, 'received_net_weight'),
          metalReturnAmount: _readDouble(row, 'metal_return_amount'),
          makingReturnedAmount: _readDouble(row, 'making_returned_amount'),
          lineReturnValue: _readDouble(row, 'line_return_value'),
          huidMatched: (row.readNullable<int>('huid_matched') ?? 1) == 1,
          unitMatched: (row.readNullable<int>('unit_matched') ?? 1) == 1,
          createdAt: _readDateTime(row, 'created_at'),
        ),
    };
  }

  String _documentReversalStatus({
    required int reversedLineCount,
    required int totalLineCount,
  }) {
    if (reversedLineCount <= 0) {
      return '';
    }
    return reversedLineCount >= totalLineCount ? 'RETURNED' : 'PARTIAL RETURN';
  }

  String _firstReversalVoucherNo(Map<int, _PostedReturnLine> lines) {
    for (final line in lines.values) {
      if (line.voucherNo.trim().isNotEmpty) {
        return line.voucherNo;
      }
    }
    return '';
  }

  String _sourceTypeStorage(ReturnReversalSourceDocumentType type) {
    return switch (type) {
      ReturnReversalSourceDocumentType.salesInvoice => 'SALES_INVOICE',
      ReturnReversalSourceDocumentType.advanceBooking => 'ADVANCE_BOOKING',
      ReturnReversalSourceDocumentType.customerPurchase => 'CUSTOMER_PURCHASE',
    };
  }

  String _operationTypeStorage(ReturnReversalOperationType type) {
    return switch (type) {
      ReturnReversalOperationType.salesReturn => 'SALES_RETURN',
      ReturnReversalOperationType.bookingCancellation => 'BOOKING_CANCELLATION',
    };
  }

  String _categoryForMetal(String metalType) {
    final metal = _metalDisplayName(metalType).toLowerCase();
    if (metal.contains('silver')) {
      return 'Silver Jewellery';
    }
    if (metal.contains('diamond')) {
      return 'Diamond Jewellery';
    }
    if (metal.contains('platinum')) {
      return 'Platinum Jewellery';
    }
    return 'Gold Jewellery';
  }

  String _metalDisplayName(String metalType) {
    final clean = metalType.trim();
    if (clean.isEmpty) {
      return 'Gold';
    }
    return clean
        .split(RegExp(r'\s+'))
        .map((word) => word.isEmpty
            ? word
            : '${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _normalizedUnitCode({
    required String storedUnit,
    required String metalType,
    required String itemName,
  }) {
    final stored = PosItemUnitProfile.fromStorageValue(storedUnit);
    final inferred = PosItemUnitProfile.infer(
      metal: _metalTypeFromLabel(metalType),
      itemName: itemName,
    );
    if (stored != null &&
        (stored.code != PosItemUnitCode.pieces ||
            inferred.code == PosItemUnitCode.pieces)) {
      return stored.shortName;
    }
    return inferred.shortName;
  }

  MetalType _metalTypeFromLabel(String metalType) {
    final normalized = metalType.trim().toUpperCase();
    if (normalized.contains('SILVER')) {
      return MetalType.silver;
    }
    if (normalized.contains('PLATINUM')) {
      return MetalType.platinum;
    }
    if (normalized.contains('DIAMOND')) {
      return MetalType.diamond;
    }
    return MetalType.gold;
  }

  double _purityPercent(String purity) {
    final normalized = purity.trim().toUpperCase();
    if (normalized.endsWith('KT') || normalized.endsWith('K')) {
      final karat = double.tryParse(
        normalized.replaceAll('KT', '').replaceAll('K', ''),
      );
      if (karat != null && karat > 0) {
        return karat / 24 * 100;
      }
    }
    return double.tryParse(normalized) ?? 0.0;
  }

  double _roundMoney(double value) => (value * 100).roundToDouble() / 100;

  String _normalizePhone(String value) {
    return value.replaceAll(RegExp(r'[\s\-]'), '').trim();
  }

  String _containsPattern(String value) {
    final escaped = value
        .trim()
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    return '%$escaped%';
  }

  String _joinAddress(String? line1, String? line2, String? city) {
    return [line1, line2, city]
        .map((part) => part?.trim() ?? '')
        .where((part) => part.isNotEmpty)
        .join(', ');
  }

  DateTime _readDateTime(drift.QueryRow row, String column) {
    try {
      final value = row.readNullable<DateTime>(column);
      if (value != null) {
        return value;
      }
    } catch (_) {
      // Drift custom queries can expose date columns as epoch milliseconds.
    }
    try {
      final millis = row.readNullable<int>(column);
      if (millis != null && millis > 0) {
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
    } catch (_) {}
    return DateTime.now();
  }

  double _readDouble(drift.QueryRow row, String column) {
    try {
      return row.readNullable<double>(column) ?? 0;
    } catch (_) {
      return (row.readNullable<int>(column) ?? 0).toDouble();
    }
  }

  double _allocatedDiscount({
    required double lineValue,
    required double billTotal,
    required double billDiscount,
  }) {
    if (lineValue <= 0 || billTotal <= 0 || billDiscount <= 0) {
      return 0;
    }
    return billDiscount * (lineValue / billTotal);
  }
}

class _PostedReturnLine {
  final String status;
  final String voucherNo;
  final String stockDisposition;
  final double receivedNetWeight;
  final double metalReturnAmount;
  final double makingReturnedAmount;
  final double lineReturnValue;
  final bool huidMatched;
  final bool unitMatched;
  final DateTime createdAt;

  const _PostedReturnLine({
    required this.status,
    required this.voucherNo,
    required this.stockDisposition,
    required this.receivedNetWeight,
    required this.metalReturnAmount,
    required this.makingReturnedAmount,
    required this.lineReturnValue,
    required this.huidMatched,
    required this.unitMatched,
    required this.createdAt,
  });

  bool get includeMakingCharge => makingReturnedAmount > 0.005;
}
