class SearchResult {
  final String id;        // Database ID
  final String title;     // Main Text (e.g., Customer Name / Bill No)
  final String subtitle;  // Sub Text (e.g., Mobile / Amount)
  final String type;      // "Customer", "Invoice", "Loan"

  // CONST Constructor for Performance Optimization
  const SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
  });

  // ==========================================
  // ⚡ 1. JSON SERIALIZATION (API READY)
  // ==========================================
  // Python Backend se jo data aayega, usse safely handle karega
  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      // ID can be int or string from DB, force convert to String safely
      id: json['id']?.toString() ?? "0", 
      title: json['title'] ?? "Unknown",
      subtitle: json['subtitle'] ?? "",
      type: json['type'] ?? "General",
    );
  }

  // Data wapas server bhejne ke liye (if needed)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'type': type,
    };
  }

  // ==========================================
  // ⚡ 2. COPY WITH (Immutability Helper)
  // ==========================================
  SearchResult copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? type,
  }) {
    return SearchResult(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      type: type ?? this.type,
    );
  }

  // ==========================================
  // ⚡ 3. DEBUGGING HELPER
  // ==========================================
  @override
  String toString() {
    return 'SearchResult(title: $title, type: $type)';
  }
}