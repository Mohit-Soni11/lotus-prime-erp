// -----------------------------------------------------------------------------
// FILE: bank_account_model.dart
// TYPE: Core Data Model
// AUTHOR: Senior System Architect
// DESCRIPTION: Highly optimized, immutable data model with deep value equality
//              and safe JSON parsing for 60-FPS rendering.
// -----------------------------------------------------------------------------

import '../enums/banking_enums.dart';
import 'package:flutter/foundation.dart';

@immutable
class BankAccountModel {
  final String id;
  final String title;
  final String holder;
  final String bank;
  final BankAccountType type;
  final String acc;
  final String ifsc;
  final String branch;
  final String upi;
  final String? qrImagePath;

  const BankAccountModel({
    required this.id,
    this.title = "New Bank Account",
    this.holder = "",
    this.bank = "",
    this.type = BankAccountType.current,
    this.acc = "",
    this.ifsc = "",
    this.branch = "",
    this.upi = "",
    this.qrImagePath,
  });

  // --- API / JSON SERIALIZATION ---
  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    return BankAccountModel(
      id: json['id']?.toString() ?? "",
      title: json['title']?.toString() ?? "New Bank Account",
      holder: json['holder']?.toString() ?? "",
      bank: json['bank']?.toString() ?? "",
      type: BankAccountType.fromString(json['type']?.toString()),
      acc: json['acc']?.toString() ?? "",
      ifsc: json['ifsc']?.toString() ?? "",
      branch: json['branch']?.toString() ?? "",
      upi: json['upi']?.toString() ?? "",
      qrImagePath: json['qr_image_path']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'holder': holder,
      'bank': bank,
      'type': type.displayName,
      'acc': acc,
      'ifsc': ifsc,
      'branch': branch,
      'upi': upi,
      'qr_image_path': qrImagePath,
    };
  }

  // --- STATE MANAGEMENT ---
  BankAccountModel copyWith({
    String? id,
    String? title,
    String? holder,
    String? bank,
    BankAccountType? type,
    String? acc,
    String? ifsc,
    String? branch,
    String? upi,
    String? qrImagePath,
    bool clearQrImage = false, // 🚀 UPGRADE: Safe null assignment flag
  }) {
    return BankAccountModel(
      id: id ?? this.id,
      title: title ?? this.title,
      holder: holder ?? this.holder,
      bank: bank ?? this.bank,
      type: type ?? this.type,
      acc: acc ?? this.acc,
      ifsc: ifsc ?? this.ifsc,
      branch: branch ?? this.branch,
      upi: upi ?? this.upi,
      qrImagePath: clearQrImage ? null : (qrImagePath ?? this.qrImagePath),
    );
  }

  // --- LOGIC MOVED FROM UI ---
  String getDisplayAccount(bool isPrimary) {
    if (acc.isEmpty) return "No Account Details";
    if (isPrimary) {
      if (acc.length <= 4) return "••••";
      return "•••• ${acc.substring(acc.length - 4)}";
    }
    return acc;
  }

  // 🚀 UPGRADE: DEEP VALUE EQUALITY & HASHING (Lag Killer)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BankAccountModel &&
        other.id == id &&
        other.title == title &&
        other.holder == holder &&
        other.bank == bank &&
        other.type == type &&
        other.acc == acc &&
        other.ifsc == ifsc &&
        other.branch == branch &&
        other.upi == upi &&
        other.qrImagePath == qrImagePath;
  }

  @override
  int get hashCode {
    return Object.hash(
        id, title, holder, bank, type, acc, ifsc, branch, upi, qrImagePath);
  }
}