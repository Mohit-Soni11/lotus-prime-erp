// =============================================================================
// FILE        : karigar_master_model.dart
// MODULE      : Karigar
// LAYER       : Models
// DESCRIPTION : UI-friendly model wrapping the Drift-generated KarigarMaster
//               data class. Adds computed display helpers for the UI layer.
// =============================================================================

import 'karigar_enums/karigar_enums.dart';

/// Wraps a Drift KarigarMaster with computed display helpers.
/// Pure Dart — zero Flutter dependency.
class KarigarMasterModel {
  final int id;
  final String name;
  final String phone;
  final String? alternatePhone;
  final String specialization;
  final String rateType;
  final double rateAmount;
  final String? address;
  final String? city;
  final double openingBalance;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;

  const KarigarMasterModel({
    required this.id,
    required this.name,
    required this.phone,
    this.alternatePhone,
    required this.specialization,
    required this.rateType,
    required this.rateAmount,
    this.address,
    this.city,
    required this.openingBalance,
    required this.isActive,
    this.notes,
    required this.createdAt,
  });

  /// Display label — initials for avatar widget.
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Full location string for display.
  String get locationDisplay {
    if (address != null && city != null) return '$address, $city';
    if (city != null) return city!;
    if (address != null) return address!;
    return '—';
  }

  /// Rate display string, e.g. "₹45 / gram"
  String get rateDisplay {
    final formatted = rateAmount.toStringAsFixed(2);
    switch (KarigarRateType.fromLabel(rateType)) {
      case KarigarRateType.perGram:
        return '₹$formatted / gram';
      case KarigarRateType.perPiece:
        return '₹$formatted / piece';
      case KarigarRateType.percent:
        return '$formatted%';
    }
  }
}
