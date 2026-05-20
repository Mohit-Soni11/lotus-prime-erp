// -----------------------------------------------------------------------------
// FILE: shop_step_model.dart
// TYPE: Data Model / Core
// AUTHOR: Senior System Architect
// DESCRIPTION: Immutable model representing a configuration step in the setup process.
//              Includes deep value equality for optimal list/stepper rendering.
// -----------------------------------------------------------------------------
import 'package:flutter/material.dart';

// 🚀 UPGRADE: Imported centralized enums instead of duplicating them locally.
// NOTE: Adjust this import path according to your actual folder structure.
import '../../../models/setting/shop_setup/enums/basic_info_enums.dart';

@immutable
class ShopStepModel {
  final int id;
  final String title;
  final String subTitle;
  final IconData icon;
  final StepStatus status;

  const ShopStepModel({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.icon,
    this.status =
        StepStatus.locked, // Defaults to locked from basic_info_enums.dart
  });

  /// Creates a new instance with updated fields, essential for State Management.
  ShopStepModel copyWith({
    int? id,
    String? title,
    String? subTitle,
    IconData? icon,
    StepStatus? status,
  }) {
    return ShopStepModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subTitle: subTitle ?? this.subTitle,
      icon: icon ?? this.icon,
      status: status ?? this.status,
    );
  }

  // 🚀 UPGRADE: VALUE EQUALITY & HASHING (Crucial for Stepper UI performance)
  // Ensures Flutter only redraws the specific step that changed its status.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ShopStepModel &&
        other.id == id &&
        other.title == title &&
        other.subTitle == subTitle &&
        other.icon == icon &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, subTitle, icon, status);
  }
}
