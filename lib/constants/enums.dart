// Location: lib/core/constants/enums.dart

// ⚡ SMART ENUMS: Updated to CamelCase (Dart Standard)

// ==========================================
// 1. USER ROLES
// ==========================================
enum UserRole {
  owner,
  manager,
  staff,
  admin;

  // 🔥 SAFETY LOGIC: Case Insensitive Matching
  static UserRole fromString(String value) {
    try {
      return UserRole.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase().trim(),
        orElse: () => UserRole.staff,
      );
    } catch (_) {
      return UserRole.staff;
    }
  }

  // Display Helper: "owner" -> "Owner"
  String get label {
    return name[0].toUpperCase() + name.substring(1);
  }
}

// ==========================================
// 2. NOTIFICATION TYPES
// ==========================================
enum NotificationType {
  stock,
  money,
  crm,
  admin,
  system,
  sales;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase().trim(),
      orElse: () => NotificationType.system,
    );
  }
}

// ==========================================
// 3. SEARCH SCOPES
// ==========================================
enum SearchScope {
  all,
  customer,
  invoice,
  mobile,
  loan;

  String get label {
    // Special casing for generic display
    return name[0].toUpperCase() + name.substring(1);
  }
}