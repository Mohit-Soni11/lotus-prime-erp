import 'dart:convert';
import 'package:crypto/crypto.dart';

class NotificationItem {
  final int id;
  final String type; // "Stock", "CRM", "Admin" etc.
  final String title;
  final String desc;
  final String targetRole; // "ALL", "OWNER", "STAFF"
  final bool isRead;
  final String? eventKey;
  final String? routeId;
  final int? billId;
  final int? customerId;
  final int? loanId;
  final bool isOperational;
  final String? location;
  final int priority;
  final String? sourceRevision;

  String get storageKey => eventKey ?? 'message:$id';
  bool get isDailyEssential =>
      isOperational &&
      ((eventKey?.startsWith('business:') ?? false) ||
          type == 'Day Book' ||
          type == 'Metal Rates');
  bool get isStockAlert =>
      isOperational &&
      ((eventKey?.startsWith('stock:') ?? false) || type == 'Inventory');
  bool get isProtected => isDailyEssential || isStockAlert;
  bool get canOpen =>
      location != null || routeId != null || billId != null || loanId != null;
  String get fingerprint => sha256
      .convert(utf8.encode(jsonEncode([
        type,
        title,
        desc,
        location,
        routeId,
        billId,
        customerId,
        loanId,
        if (sourceRevision != null) sourceRevision,
      ])))
      .toString();
  int get sortRank {
    final key = eventKey ?? '';
    if (key.startsWith('business:opening:')) return 0;
    if (key.startsWith('business:rates:')) return 1;
    if (key.startsWith('business:closing:') ||
        key.startsWith('business:unfinished:')) {
      return 2;
    }
    return isOperational ? 10 : 20;
  }

  static int compare(NotificationItem a, NotificationItem b) {
    final rank = a.sortRank.compareTo(b.sortRank);
    if (rank != 0) return rank;
    final urgency = a.priority.compareTo(b.priority);
    if (urgency != 0) return urgency;
    if (!a.isOperational && !b.isOperational) return b.id.compareTo(a.id);
    return a.storageKey.compareTo(b.storageKey);
  }

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.desc,
    required this.targetRole,
    this.isRead = false,
    this.eventKey,
    this.routeId,
    this.billId,
    this.customerId,
    this.loanId,
    this.isOperational = false,
    this.location,
    this.priority = 1,
    this.sourceRevision,
  });

  // ==========================================
  // 1. JSON SERIALIZATION
  // ==========================================
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? 0,
      type: json['type'] ?? "General",
      title: json['title'] ?? "No Title",
      desc: json['desc'] ?? "",
      // Default to all roles when target_role is omitted.
      targetRole: json['target_role'] ?? "ALL",
      isRead: json['is_read'] ?? false,
      eventKey: json['event_key'],
      routeId: json['route_id'],
      billId: json['bill_id'],
      customerId: json['customer_id'],
      loanId: json['loan_id'],
      isOperational: json['is_operational'] ?? false,
      location: json['location'],
      priority: json['priority'] ?? 1,
      sourceRevision: json['source_revision'],
    );
  }

  // Serializes data for backend updates.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'desc': desc,
      'target_role': targetRole,
      'is_read': isRead,
      'event_key': eventKey,
      'route_id': routeId,
      'bill_id': billId,
      'customer_id': customerId,
      'loan_id': loanId,
      'is_operational': isOperational,
      'location': location,
      'priority': priority,
      'source_revision': sourceRevision,
    };
  }

  // ==========================================
  // 2. COPY WITH
  // ==========================================
  // Supports immutable state updates.
  NotificationItem copyWith({
    int? id,
    String? type,
    String? title,
    String? desc,
    String? targetRole,
    bool? isRead,
    String? eventKey,
    String? routeId,
    int? billId,
    int? customerId,
    int? loanId,
    bool? isOperational,
    String? location,
    int? priority,
    String? sourceRevision,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      desc: desc ?? this.desc,
      targetRole: targetRole ?? this.targetRole,
      isRead: isRead ?? this.isRead,
      eventKey: eventKey ?? this.eventKey,
      routeId: routeId ?? this.routeId,
      billId: billId ?? this.billId,
      customerId: customerId ?? this.customerId,
      loanId: loanId ?? this.loanId,
      isOperational: isOperational ?? this.isOperational,
      location: location ?? this.location,
      priority: priority ?? this.priority,
      sourceRevision: sourceRevision ?? this.sourceRevision,
    );
  }
}
