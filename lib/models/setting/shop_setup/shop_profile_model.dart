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
  final String ownerWhatsapp;
  final String estYear;
  final String branchCode;
  final String openTime;
  final String closeTime;
  final String weeklyOff;
  final String brandDisplayName;
  final String businessEmail;
  final String shopPhone;
  final String shopWhatsapp;
  final String? logoPath; // 🚀 FIXED: Changed from logoBase64
  final String? signaturePath; // 🚀 FIXED: Changed from signatureBase64

  const ShopProfileModel({
    this.legalName = "",
    this.displayName = "",
    this.tagline = "",
    this.ownerName = "",
    this.ownerPhone = "",
    this.ownerWhatsapp = "",
    this.estYear = "",
    this.branchCode = "",
    this.openTime = "10:00 AM",
    this.closeTime = "08:00 PM",
    this.weeklyOff = "Sunday",
    this.brandDisplayName = "",
    this.businessEmail = "",
    this.shopPhone = "",
    this.shopWhatsapp = "",
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
      ownerWhatsapp: json['owner_whatsapp']?.toString() ?? "",
      estYear: json['est_year']?.toString() ?? "",
      branchCode: json['branch_code']?.toString() ?? "",
      openTime: json['open_time']?.toString() ?? "10:00 AM",
      closeTime: json['close_time']?.toString() ?? "08:00 PM",
      weeklyOff: json['weekly_off']?.toString() ?? "Sunday",
      brandDisplayName: json['brand_display_name']?.toString() ?? "",
      businessEmail: json['business_email']?.toString() ?? "",
      shopPhone: json['shop_phone']?.toString() ?? "",
      shopWhatsapp: json['shop_whatsapp']?.toString() ?? "",
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
      'owner_whatsapp': ownerWhatsapp,
      'est_year': estYear,
      'branch_code': branchCode,
      'open_time': openTime,
      'close_time': closeTime,
      'weekly_off': weeklyOff,
      'brand_display_name': brandDisplayName,
      'business_email': businessEmail,
      'shop_phone': shopPhone,
      'shop_whatsapp': shopWhatsapp,
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
    String? ownerWhatsapp,
    String? estYear,
    String? branchCode,
    String? openTime,
    String? closeTime,
    String? weeklyOff,
    String? brandDisplayName,
    String? businessEmail,
    String? shopPhone,
    String? shopWhatsapp,
    String? logoPath,
    String? signaturePath,
  }) {
    return ShopProfileModel(
      legalName: legalName ?? this.legalName,
      displayName: displayName ?? this.displayName,
      tagline: tagline ?? this.tagline,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      ownerWhatsapp: ownerWhatsapp ?? this.ownerWhatsapp,
      estYear: estYear ?? this.estYear,
      branchCode: branchCode ?? this.branchCode,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      weeklyOff: weeklyOff ?? this.weeklyOff,
      brandDisplayName: brandDisplayName ?? this.brandDisplayName,
      businessEmail: businessEmail ?? this.businessEmail,
      shopPhone: shopPhone ?? this.shopPhone,
      shopWhatsapp: shopWhatsapp ?? this.shopWhatsapp,
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
        other.ownerWhatsapp == ownerWhatsapp &&
        other.estYear == estYear &&
        other.branchCode == branchCode &&
        other.openTime == openTime &&
        other.closeTime == closeTime &&
        other.weeklyOff == weeklyOff &&
        other.brandDisplayName == brandDisplayName &&
        other.businessEmail == businessEmail &&
        other.shopPhone == shopPhone &&
        other.shopWhatsapp == shopWhatsapp &&
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
        ownerWhatsapp,
        estYear,
        branchCode,
        openTime,
        closeTime,
        weeklyOff,
        brandDisplayName,
        businessEmail,
        shopPhone,
        shopWhatsapp,
        logoPath,
        signaturePath);
  }
}
