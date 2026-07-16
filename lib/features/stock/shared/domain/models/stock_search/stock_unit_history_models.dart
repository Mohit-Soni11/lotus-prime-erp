import 'package:drift/drift.dart' show QueryRow;

class StockUnitHistoryEvent {
  final String movementType;
  final String title;
  final String sourceNumber;
  final String partyName;
  final int quantityDelta;
  final double grossWeightDelta;
  final double netWeightDelta;
  final double fineWeightDelta;
  final DateTime? occurredAt;
  final String note;

  const StockUnitHistoryEvent({
    required this.movementType,
    required this.title,
    required this.sourceNumber,
    required this.partyName,
    required this.quantityDelta,
    required this.grossWeightDelta,
    required this.netWeightDelta,
    required this.fineWeightDelta,
    required this.occurredAt,
    required this.note,
  });

  factory StockUnitHistoryEvent.fromRow(QueryRow row) {
    return StockUnitHistoryEvent(
      movementType: _readString(row, 'movement_type'),
      title: _readString(row, 'title'),
      sourceNumber: _readString(row, 'source_number'),
      partyName: _readString(row, 'party_name'),
      quantityDelta: _readInt(row, 'quantity_delta'),
      grossWeightDelta: _readDouble(row, 'gross_weight_delta'),
      netWeightDelta: _readDouble(row, 'net_weight_delta'),
      fineWeightDelta: _readDouble(row, 'fine_weight_delta'),
      occurredAt: _readDate(row, 'occurred_at'),
      note: _readString(row, 'note'),
    );
  }

  bool get isInbound => movementType.toUpperCase() == 'IN';
  bool get isSale => movementType.toUpperCase() == 'SALE';
  bool get isRestore => movementType.toUpperCase() == 'SALE_RESTORE';

  String get businessStatus {
    if (isInbound) return 'Stock Added';
    if (isSale) return 'Sold';
    if (isRestore) return 'Restored';
    return title.trim().isEmpty ? 'Stock Movement' : title.trim();
  }

  String get sourceLabel {
    if (sourceNumber.trim().isNotEmpty) return sourceNumber.trim();
    return 'Not recorded';
  }

  String get partyLabel {
    if (partyName.trim().isNotEmpty) return partyName.trim();
    return 'Not recorded';
  }
}

int _readInt(QueryRow row, String key) {
  return (row.data[key] as num?)?.toInt() ?? 0;
}

double _readDouble(QueryRow row, String key) {
  return (row.data[key] as num?)?.toDouble() ?? 0;
}

String _readString(QueryRow row, String key) {
  return (row.data[key] as String?)?.trim() ?? '';
}

DateTime? _readDate(QueryRow row, String key) {
  final raw = row.data[key];
  if (raw is DateTime) return raw;
  final value = (raw as num?)?.toInt();
  if (value == null || value <= 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(value);
}
