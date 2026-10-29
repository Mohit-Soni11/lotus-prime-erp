import 'dart:typed_data';

import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';

/// Keeps previews for the current invoice revision and shares in-flight builds.
class PosInvoicePreviewCache {
  final _ready = <MetalType, Uint8List>{};
  final _pending = <MetalType, Future<Uint8List>>{};
  int _revision = 0;

  int get revision => _revision;
  Map<MetalType, Uint8List> get ready => Map.unmodifiable(_ready);

  void invalidate() {
    _revision++;
    _ready.clear();
    _pending.clear();
  }

  Future<Uint8List> load(
    MetalType metal,
    Future<Uint8List> Function() build,
  ) async {
    final cached = _ready[metal];
    if (cached != null) return cached;

    final inFlight = _pending[metal];
    if (inFlight != null) return inFlight;

    final revision = _revision;
    final future = build();
    _pending[metal] = future;
    try {
      final bytes = await future;
      if (_revision == revision) _ready[metal] = bytes;
      return bytes;
    } finally {
      if (identical(_pending[metal], future)) _pending.remove(metal);
    }
  }
}
