// -----------------------------------------------------------------------------
// FILE: shop_branding_model.dart
// TYPE: Data Model
// AUTHOR: Senior System Architect
// DESCRIPTION: Highly optimized, immutable data model strictly for Branding
//              and Social Media data. Includes safe JSON parsing and deep
//              value equality to prevent unnecessary UI rebuilds.
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

@immutable
class ShopBrandingModel {
  final String website;
  final String instagram;
  final String facebook;
  final String youtube;
  final String whatsappChannel;

  const ShopBrandingModel({
    this.website = "",
    this.instagram = "",
    this.facebook = "",
    this.youtube = "",
    this.whatsappChannel = "",
  });

  // --- SERIALIZATION (Bulletproof API Ready) ---
  factory ShopBrandingModel.fromJson(Map<String, dynamic> json) {
    return ShopBrandingModel(
      website: json['website']?.toString() ?? "",
      instagram: json['instagram']?.toString() ?? "",
      facebook: json['facebook']?.toString() ?? "",
      youtube: json['youtube']?.toString() ?? "",
      whatsappChannel: json['whatsapp_channel']?.toString() ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'website': website,
      'instagram': instagram,
      'facebook': facebook,
      'youtube': youtube,
      'whatsapp_channel': whatsappChannel,
    };
  }

  // --- IMMUTABLE STATE UPDATES ---
  ShopBrandingModel copyWith({
    String? website,
    String? instagram,
    String? facebook,
    String? youtube,
    String? whatsappChannel,
  }) {
    return ShopBrandingModel(
      website: website ?? this.website,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      youtube: youtube ?? this.youtube,
      whatsappChannel: whatsappChannel ?? this.whatsappChannel,
    );
  }

  // 🚀 UPGRADE: VALUE EQUALITY & HASHING (Prevents Memory Leaks & UI Lag)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ShopBrandingModel &&
        other.website == website &&
        other.instagram == instagram &&
        other.facebook == facebook &&
        other.youtube == youtube &&
        other.whatsappChannel == whatsappChannel;
  }

  @override
  int get hashCode {
    return Object.hash(
      website,
      instagram,
      facebook,
      youtube,
      whatsappChannel,
    );
  }
}
