// Location: lib/models/notification_item.dart

class NotificationItem {
  final int id;
  final String type; // "Stock", "CRM", "Admin" etc.
  final String title;
  final String desc;
  final String targetRole; // "ALL", "OWNER", "STAFF"
  bool isRead; // Mutable: Kyunki hum isse update karte hain (Mark Read)

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.desc,
    required this.targetRole,
    this.isRead = false,
  });

  // ==========================================
  // ⚡ 1. JSON SERIALIZATION (API READY)
  // ==========================================
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? 0,
      type: json['type'] ?? "General",
      title: json['title'] ?? "No Title",
      desc: json['desc'] ?? "",
      // Agar backend se target_role na aaye, toh default "ALL" maan lo
      targetRole: json['target_role'] ?? "ALL",
      isRead: json['is_read'] ?? false,
    );
  }

  // Data wapas bhejne ke liye
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'desc': desc,
      'target_role': targetRole,
      'is_read': isRead,
    };
  }

  // ==========================================
  // ⚡ 2. COPY WITH (Helper for Updates)
  // ==========================================
  // Agar hum immutable state use karein future mein, toh ye kaam aayega
  NotificationItem copyWith({
    int? id,
    String? type,
    String? title,
    String? desc,
    String? targetRole,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      desc: desc ?? this.desc,
      targetRole: targetRole ?? this.targetRole,
      isRead: isRead ?? this.isRead,
    );
  }
}
