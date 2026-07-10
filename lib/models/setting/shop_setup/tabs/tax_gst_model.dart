// -----------------------------------------------------------------------------
// FILE: tax_gst_model.dart
// TYPE: Data Model / Core
// AUTHOR: Senior System Architect
// 🚀 UPGRADED: Replaced heavy Base64 strings with lightweight File Paths.
// -----------------------------------------------------------------------------

import '../enums/tax_gst_enums.dart';
import 'package:flutter/foundation.dart';

@immutable
class TaxGstModel {
  final String gstin;
  final String legalName;
  final String regDate;
  final TaxpayerType taxpayerType;
  final String bisLicenseNo;
  final String goldBisLicenseNo;
  final String silverBisLicenseNo;
  final String? gstCertPath; // 🚀 FIXED
  final String? bisLicensePath; // 🚀 FIXED

  const TaxGstModel({
    this.gstin = "",
    this.legalName = "",
    this.regDate = "",
    this.taxpayerType = TaxpayerType.regular,
    this.bisLicenseNo = "",
    this.goldBisLicenseNo = "",
    this.silverBisLicenseNo = "",
    this.gstCertPath,
    this.bisLicensePath,
  });

  factory TaxGstModel.fromJson(Map<String, dynamic> json) {
    final legacyBisLicense = json['bis_license_no']?.toString().trim() ?? "";
    final storedGoldBisLicense =
        json['gold_bis_license_no']?.toString().trim() ?? "";
    final goldBisLicense = storedGoldBisLicense.isNotEmpty
        ? storedGoldBisLicense
        : legacyBisLicense;
    final silverBisLicense =
        json['silver_bis_license_no']?.toString().trim() ?? "";

    return TaxGstModel(
      gstin: json['gstin']?.toString() ?? "",
      legalName: json['legal_name']?.toString() ?? "",
      regDate: json['reg_date']?.toString() ?? "",
      taxpayerType: TaxpayerType.fromString(json['taxpayer_type']?.toString()),
      bisLicenseNo: legacyBisLicense.isNotEmpty
          ? legacyBisLicense
          : _combinedBisLicense(goldBisLicense, silverBisLicense),
      goldBisLicenseNo: goldBisLicense,
      silverBisLicenseNo: silverBisLicense,
      gstCertPath: json['gst_cert_path']?.toString(),
      bisLicensePath: json['bis_license_path']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gstin': gstin,
      'legal_name': legalName,
      'reg_date': regDate,
      'taxpayer_type': taxpayerType.displayName,
      'bis_license_no': bisLicenseNo,
      'gold_bis_license_no': goldBisLicenseNo,
      'silver_bis_license_no': silverBisLicenseNo,
      'gst_cert_path': gstCertPath,
      'bis_license_path': bisLicensePath,
    };
  }

  TaxGstModel copyWith({
    String? gstin,
    String? legalName,
    String? regDate,
    TaxpayerType? taxpayerType,
    String? bisLicenseNo,
    String? goldBisLicenseNo,
    String? silverBisLicenseNo,
    String? gstCertPath,
    String? bisLicensePath,
  }) {
    return TaxGstModel(
      gstin: gstin ?? this.gstin,
      legalName: legalName ?? this.legalName,
      regDate: regDate ?? this.regDate,
      taxpayerType: taxpayerType ?? this.taxpayerType,
      bisLicenseNo: bisLicenseNo ?? this.bisLicenseNo,
      goldBisLicenseNo: goldBisLicenseNo ?? this.goldBisLicenseNo,
      silverBisLicenseNo: silverBisLicenseNo ?? this.silverBisLicenseNo,
      gstCertPath: gstCertPath ?? this.gstCertPath,
      bisLicensePath: bisLicensePath ?? this.bisLicensePath,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaxGstModel &&
        other.gstin == gstin &&
        other.legalName == legalName &&
        other.regDate == regDate &&
        other.taxpayerType == taxpayerType &&
        other.bisLicenseNo == bisLicenseNo &&
        other.goldBisLicenseNo == goldBisLicenseNo &&
        other.silverBisLicenseNo == silverBisLicenseNo &&
        other.gstCertPath == gstCertPath &&
        other.bisLicensePath == bisLicensePath;
  }

  @override
  int get hashCode {
    return Object.hash(
      gstin,
      legalName,
      regDate,
      taxpayerType,
      bisLicenseNo,
      goldBisLicenseNo,
      silverBisLicenseNo,
      gstCertPath,
      bisLicensePath,
    );
  }

  static String _combinedBisLicense(String gold, String silver) {
    final goldText = gold.trim();
    final silverText = silver.trim();
    if (goldText.isNotEmpty && silverText.isNotEmpty) {
      if (goldText.toUpperCase() == silverText.toUpperCase()) return goldText;
      return "Gold: $goldText | Silver: $silverText";
    }
    if (goldText.isNotEmpty) return goldText;
    return silverText;
  }
}
