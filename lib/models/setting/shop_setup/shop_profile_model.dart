// -----------------------------------------------------------------------------
// FILE: shop_profile_model.dart
// TYPE: Data Model / Blueprint
// AUTHOR: Senior System Architect
// DESCRIPTION: Highly optimized, immutable data model.
//              🚀 UPGRADED: Removed Base64 death traps. Using File Paths now.
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

@immutable
class ShopProfileModel {
  final String legalName;
  final String displayName;
  final String tagline;
  final String ownerName;
  final String ownerPhone;
  final String brandDisplayName;
  final String businessEmail;
  final String shopPhone;
  final String shopWhatsapp;
  final String helpDeskNumber;
  final String logoShape;
  final String signatureShape;
  final String? logoPath; // 🚀 FIXED: Changed from logoBase64
  final String? signaturePath; // 🚀 FIXED: Changed from signatureBase64

  const ShopProfileModel({
    this.legalName = "",
    this.displayName = "",
    this.tagline = "",
    this.ownerName = "",
    this.ownerPhone = "",
    this.brandDisplayName = "",
    this.businessEmail = "",
    this.shopPhone = "",
    this.shopWhatsapp = "",
    this.helpDeskNumber = "",
    this.logoShape = "circle",
    this.signatureShape = "square",
    this.logoPath,
    this.signaturePath,
  });

  factory ShopProfileModel.fromJson(Map<String, dynamic> json) {
    return ShopProfileModel(
      legalName: json['legal_name']?.toString() ?? "",
      displayName: json['display_name']?.toString() ?? "",
      tagline: json['tagline']?.toString() ?? "",
      ownerName: json['owner_name']?.toString() ?? "",
      ownerPhone: json['owner_phone']?.toString() ?? "",
      brandDisplayName: json['brand_display_name']?.toString() ?? "",
      businessEmail: json['business_email']?.toString() ?? "",
      shopPhone: json['shop_phone']?.toString() ?? "",
      shopWhatsapp: json['shop_whatsapp']?.toString() ?? "",
      helpDeskNumber: json['help_desk_number']?.toString() ?? "",
      logoShape: _shape(json['logo_shape'], fallback: "circle"),
      signatureShape: _shape(json['signature_shape'], fallback: "square"),
      logoPath: json['logo_path']?.toString(),
      signaturePath: json['signature_path']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'legal_name': legalName,
      'display_name': displayName,
      'tagline': tagline,
      'owner_name': ownerName,
      'owner_phone': ownerPhone,
      'brand_display_name': brandDisplayName,
      'business_email': businessEmail,
      'shop_phone': shopPhone,
      'shop_whatsapp': shopWhatsapp,
      'help_desk_number': helpDeskNumber,
      'logo_shape': logoShape,
      'signature_shape': signatureShape,
      'logo_path': logoPath,
      'signature_path': signaturePath,
    };
  }

  ShopProfileModel copyWith({
    String? legalName,
    String? displayName,
    String? tagline,
    String? ownerName,
    String? ownerPhone,
    String? brandDisplayName,
    String? businessEmail,
    String? shopPhone,
    String? shopWhatsapp,
    String? helpDeskNumber,
    String? logoShape,
    String? signatureShape,
    String? logoPath,
    String? signaturePath,
  }) {
    return ShopProfileModel(
      legalName: legalName ?? this.legalName,
      displayName: displayName ?? this.displayName,
      tagline: tagline ?? this.tagline,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      brandDisplayName: brandDisplayName ?? this.brandDisplayName,
      businessEmail: businessEmail ?? this.businessEmail,
      shopPhone: shopPhone ?? this.shopPhone,
      shopWhatsapp: shopWhatsapp ?? this.shopWhatsapp,
      helpDeskNumber: helpDeskNumber ?? this.helpDeskNumber,
      logoShape: logoShape ?? this.logoShape,
      signatureShape: signatureShape ?? this.signatureShape,
      logoPath: logoPath ?? this.logoPath,
      signaturePath: signaturePath ?? this.signaturePath,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShopProfileModel &&
        other.legalName == legalName &&
        other.displayName == displayName &&
        other.tagline == tagline &&
        other.ownerName == ownerName &&
        other.ownerPhone == ownerPhone &&
        other.brandDisplayName == brandDisplayName &&
        other.businessEmail == businessEmail &&
        other.shopPhone == shopPhone &&
        other.shopWhatsapp == shopWhatsapp &&
        other.helpDeskNumber == helpDeskNumber &&
        other.logoShape == logoShape &&
        other.signatureShape == signatureShape &&
        other.logoPath == logoPath &&
        other.signaturePath == signaturePath;
  }

  @override
  int get hashCode {
    return Object.hash(
        legalName,
        displayName,
        tagline,
        ownerName,
        ownerPhone,
        brandDisplayName,
        businessEmail,
        shopPhone,
        shopWhatsapp,
        helpDeskNumber,
        logoShape,
        signatureShape,
        logoPath,
        signaturePath);
  }

  static String _shape(Object? value, {required String fallback}) {
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == "square" || normalized == "circle"
        ? normalized!
        : fallback;
  }
}
