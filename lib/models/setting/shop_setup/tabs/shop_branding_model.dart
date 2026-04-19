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
  final String instagram;
  final String facebook;
  final String youtube;
  final String website;
  final String whatsappChannel;
  final String whatsappBusiness;
  final String supportEmail;
  final String supportPhone;

  const ShopBrandingModel({
    this.instagram = "",
    this.facebook = "",
    this.youtube = "",
    this.website = "",
    this.whatsappChannel = "",
    this.whatsappBusiness = "",
    this.supportEmail = "",
    this.supportPhone = "",
  });

  // --- SERIALIZATION (Bulletproof API Ready) ---
  factory ShopBrandingModel.fromJson(Map<String, dynamic> json) {
    return ShopBrandingModel(
      instagram: json['instagram']?.toString() ?? "",
      facebook: json['facebook']?.toString() ?? "",
      youtube: json['youtube']?.toString() ?? "",
      website: json['website']?.toString() ?? "",
      whatsappChannel: json['whatsapp_channel']?.toString() ?? "",
      whatsappBusiness: json['whatsapp_business']?.toString() ?? "",
      supportEmail: json['support_email']?.toString() ?? "",
      supportPhone: json['support_phone']?.toString() ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instagram': instagram,
      'facebook': facebook,
      'youtube': youtube,
      'website': website,
      'whatsapp_channel': whatsappChannel,
      'whatsapp_business': whatsappBusiness,
      'support_email': supportEmail,
      'support_phone': supportPhone,
    };
  }

  // --- IMMUTABLE STATE UPDATES ---
  ShopBrandingModel copyWith({
    String? instagram,
    String? facebook,
    String? youtube,
    String? website,
    String? whatsappChannel,
    String? whatsappBusiness,
    String? supportEmail,
    String? supportPhone,
  }) {
    return ShopBrandingModel(
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      youtube: youtube ?? this.youtube,
      website: website ?? this.website,
      whatsappChannel: whatsappChannel ?? this.whatsappChannel,
      whatsappBusiness: whatsappBusiness ?? this.whatsappBusiness,
      supportEmail: supportEmail ?? this.supportEmail,
      supportPhone: supportPhone ?? this.supportPhone,
    );
  }

  // 🚀 UPGRADE: VALUE EQUALITY & HASHING (Prevents Memory Leaks & UI Lag)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is ShopBrandingModel &&
      other.instagram == instagram &&
      other.facebook == facebook &&
      other.youtube == youtube &&
      other.website == website &&
      other.whatsappChannel == whatsappChannel &&
      other.whatsappBusiness == whatsappBusiness &&
      other.supportEmail == supportEmail &&
      other.supportPhone == supportPhone;
  }

  @override
  int get hashCode {
    return Object.hash(
      instagram, 
      facebook, 
      youtube, 
      website, 
      whatsappChannel, 
      whatsappBusiness, 
      supportEmail, 
      supportPhone,
    );
  }
}