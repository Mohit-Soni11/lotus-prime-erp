// =============================================================================
// FILE        : alert_card_model.dart
// MODULE      : Dashboard / Alert Row
// LAYER       : Models
// DESCRIPTION : Char alert cards ka data model.
//               AlertStatus enum: safe / warning / critical
//               AlertCardModel: ek card ka poora data snapshot
// =============================================================================

/// Python ke status_level (0, 1, 2) ka Flutter equivalent
enum AlertStatus {
  safe,     // 0 → Green strip  → "Normal"
  warning,  // 1 → Orange strip → "Attention"
  critical, // 2 → Red strip    → "Action Needed"
}

/// Ek alert card ka complete data snapshot
class AlertCardModel {
  final String id;           // 'inventory' / 'orders' / 'collections' / 'deliveries'
  final String title;        // Card header label
  final String mainValue;    // Big bold text — "GOLD LOW", "3 PENDING", etc
  final String subText;      // Explanation text below main value
  final AlertStatus status;  // Determines strip + badge color
  final String routeId;      // Navigation target

  const AlertCardModel({
    required this.id,
    required this.title,
    required this.mainValue,
    required this.subText,
    required this.status,
    required this.routeId,
  });

  /// Loading placeholder — shimmer ke waqt use hoga
  factory AlertCardModel.loading(String id, String title, String routeId) {
    return AlertCardModel(
      id: id,
      title: title,
      mainValue: '--',
      subText: 'Updating...',
      status: AlertStatus.safe,
      routeId: routeId,
    );
  }

  bool get isLoading => mainValue == '--';
}

/// Charon cards ka ek saath snapshot — logic yahi return karega
class AlertRowModel {
  final AlertCardModel inventory;
  final AlertCardModel orders;
  final AlertCardModel collections;
  final AlertCardModel deliveries;

  const AlertRowModel({
    required this.inventory,
    required this.orders,
    required this.collections,
    required this.deliveries,
  });

  List<AlertCardModel> get cards =>
      [inventory, orders, collections, deliveries];
}