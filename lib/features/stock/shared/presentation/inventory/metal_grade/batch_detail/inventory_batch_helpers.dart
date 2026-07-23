part of '../../inventory_screen.dart';

enum _InventoryBatchDocumentType {
  fullDossier(
    title: 'Full Batch Dossier',
    description: 'Complete supplier, valuation, settlement and stock record.',
    fileSuffix: 'full_dossier',
  ),
  stockStatus(
    title: 'Stock Status Report',
    description: 'Available and sold item status with trace details.',
    fileSuffix: 'stock_status',
  );

  final String title;
  final String description;
  final String fileSuffix;

  const _InventoryBatchDocumentType({
    required this.title,
    required this.description,
    required this.fileSuffix,
  });
}

Map<String, dynamic> _decodePaymentMeta(String raw) {
  if (raw.trim().isEmpty) return const {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry('$key', value));
    }
  } catch (_) {}
  return const {};
}

double _metaDouble(Map<String, dynamic> meta, String key) {
  final value = meta[key];
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

String _metaString(Map<String, dynamic> meta, String key) {
  final value = meta[key];
  if (value == null) return '';
  return '$value';
}

String _money(double value) {
  return NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 0,
  ).format(value);
}

String _weight(double value) {
  return NumberFormat('##,##0.000', 'en_IN').format(value);
}

String _percent(double value) {
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.001) {
    return rounded.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}

bool _hasWeightDifference(double first, double second) {
  return (first - second).abs() >= 0.001;
}

String _dash(String value) {
  final text = value.trim();
  return text.isEmpty ? 'Not recorded' : text;
}

String _batchPdfFileName(
  _InventoryBatchGroup batch, [
  _InventoryBatchDocumentType type = _InventoryBatchDocumentType.fullDossier,
]) {
  final cleanBatch = batch.batchCode
      .replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  final safeBatch = cleanBatch.isEmpty ? 'batch_dossier' : cleanBatch;
  return 'inventory_batch_${safeBatch}_${type.fileSuffix}.pdf';
}

Future<Uint8List> _buildBatchPdfBytes({
  required StockCategory metal,
  required _InventoryGradeSummary grade,
  required _InventoryBatchGroup batch,
  required _InventoryBatchDocumentType type,
}) {
  return switch (type) {
    _InventoryBatchDocumentType.fullDossier => _InventoryBatchPdfService.build(
        metal: metal,
        grade: grade,
        batch: batch,
      ),
    _InventoryBatchDocumentType.stockStatus =>
      _InventoryBatchStatusPdfService.build(
        metal: metal,
        grade: grade,
        batch: batch,
      ),
  };
}

Future<void> _openLocalPath(String path) async {
  if (path.trim().isEmpty) return;
  final file = File(path);
  if (!file.existsSync()) return;
  await Process.start('explorer.exe', [path]);
}

Future<void> _showLocalFile(String path) async {
  if (path.trim().isEmpty) return;
  final file = File(path);
  if (!file.existsSync()) return;
  await Process.start('explorer.exe', ['/select,', path]);
}
