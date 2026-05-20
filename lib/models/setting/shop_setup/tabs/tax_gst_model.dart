// -----------------------------------------------------------------------------
// FILE: tax_gst_model.dart
// TYPE: Data Model / Core
// AUTHOR: Senior System Architect
// 🚀 UPGRADED: Replaced heavy Base64 strings with lightweight File Paths.
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import '../enums/tax_gst_enums.dart';

@immutable
class TaxGstModel {
  final String gstin;
  final String legalName;
  final String regDate;
  final TaxpayerType taxpayerType;
  final String bisLicenseNo;
  final String bisValidFrom;
  final String bisValidUpto;
  final String? gstCertPath; // 🚀 FIXED
  final String? bisLicensePath; // 🚀 FIXED

  const TaxGstModel({
    this.gstin = "",
    this.legalName = "",
    this.regDate = "",
    this.taxpayerType = TaxpayerType.regular,
    this.bisLicenseNo = "",
    this.bisValidFrom = "",
    this.bisValidUpto = "",
    this.gstCertPath,
    this.bisLicensePath,
  });

  factory TaxGstModel.fromJson(Map<String, dynamic> json) {
    return TaxGstModel(
      gstin: json['gstin']?.toString() ?? "",
      legalName: json['legal_name']?.toString() ?? "",
      regDate: json['reg_date']?.toString() ?? "",
      taxpayerType: TaxpayerType.fromString(json['taxpayer_type']?.toString()),
      bisLicenseNo: json['bis_license_no']?.toString() ?? "",
      bisValidFrom: json['bis_valid_from']?.toString() ?? "",
      bisValidUpto: json['bis_valid_upto']?.toString() ?? "",
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
      'bis_valid_from': bisValidFrom,
      'bis_valid_upto': bisValidUpto,
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
    String? bisValidFrom,
    String? bisValidUpto,
    String? gstCertPath,
    String? bisLicensePath,
  }) {
    return TaxGstModel(
      gstin: gstin ?? this.gstin,
      legalName: legalName ?? this.legalName,
      regDate: regDate ?? this.regDate,
      taxpayerType: taxpayerType ?? this.taxpayerType,
      bisLicenseNo: bisLicenseNo ?? this.bisLicenseNo,
      bisValidFrom: bisValidFrom ?? this.bisValidFrom,
      bisValidUpto: bisValidUpto ?? this.bisValidUpto,
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
        other.bisValidFrom == bisValidFrom &&
        other.bisValidUpto == bisValidUpto &&
        other.gstCertPath == gstCertPath &&
        other.bisLicensePath == bisLicensePath;
  }

  @override
  int get hashCode {
    return Object.hash(gstin, legalName, regDate, taxpayerType, bisLicenseNo,
        bisValidFrom, bisValidUpto, gstCertPath, bisLicensePath);
  }
}
