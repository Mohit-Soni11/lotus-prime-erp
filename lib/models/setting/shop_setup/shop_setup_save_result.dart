import 'package:flutter/foundation.dart';

/// Outcome of committing the Shop Profile master record.
///
/// The local Shop Profile database is the source of truth. Operational copies
/// are maintained for legacy finance/reporting consumers and may be retried
/// independently without making a successfully saved profile look lost.
@immutable
class ShopSetupSaveResult {
  const ShopSetupSaveResult({
    required this.isPersisted,
    this.syncWarnings = const <String>[],
  });

  final bool isPersisted;
  final List<String> syncWarnings;

  bool get hasSyncWarnings => syncWarnings.isNotEmpty;
}
