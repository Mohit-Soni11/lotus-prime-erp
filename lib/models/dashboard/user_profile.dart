// File: lib/core/models/user_profile.dart

class UserProfile {
  final String id;        
  final String name;      
  final String role;      
  final String? imageUrl; 
  final bool isOnline;    

  const UserProfile({
    this.id = "0",        
    required this.name,
    required this.role,
    this.imageUrl,
    this.isOnline = true,
  });

  // ✅ FIX: Guest User Factory (Ye missing tha)
  factory UserProfile.guest() {
    return const UserProfile(
      id: "guest",
      name: "Guest User",
      role: "VIEWER",
      isOnline: false, // Guest offline dikhega
    );
  }

  // 1. JSON SERIALIZATION
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? "0",
      name: json['name'] ?? "Unknown User",
      role: json['role'] ?? "STAFF",
      imageUrl: json['profile_image'],
      isOnline: json['is_online'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'profile_image': imageUrl,
      'is_online': isOnline,
    };
  }

  // 2. COPY WITH
  UserProfile copyWith({
    String? id,
    String? name,
    String? role,
    String? imageUrl,
    bool? isOnline,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      imageUrl: imageUrl ?? this.imageUrl,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  // 3. SMART INITIALS
  String get initials {
    if (name.isEmpty) return "NA";
    List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }
}