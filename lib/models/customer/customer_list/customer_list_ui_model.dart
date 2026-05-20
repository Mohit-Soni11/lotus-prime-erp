// -----------------------------------------------------------------------------
// FILE: customer_list_ui_model.dart
// MODULE: Customer → Customer List
// DESCRIPTION: Immutable UI model for displaying customer in list.
//              Separate from DB model for clean separation.
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import '../customer_enums/customer_list_enums.dart';

@immutable
class CustomerListItemModel {
  final int id;
  final String name;
  final String mobile;
  final String city;
  final CustomerType type;
  final int billCount;
  final DateTime createdAt;
  final String initials;

  const CustomerListItemModel({
    required this.id,
    required this.name,
    required this.mobile,
    required this.city,
    required this.type,
    required this.billCount,
    required this.createdAt,
    required this.initials,
  });

  /// Format: "12 Jan 2025"
  String get formattedDate {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return "${createdAt.day.toString().padLeft(2, '0')} "
        "${months[createdAt.month]} "
        "${createdAt.year}";
  }

  /// Check if added today
  bool get isNewToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }

  bool get isVip => type == CustomerType.vip;

  static String buildInitials(String name) {
    if (name.trim().isEmpty) return "NA";
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}

/// Model for the stats strip at top
@immutable
class CustomerListStatsModel {
  final int totalCount;
  final int todayCount;
  final int vipCount;
  final bool isLoading;

  const CustomerListStatsModel({
    required this.totalCount,
    required this.todayCount,
    required this.vipCount,
    this.isLoading = false,
  });

  factory CustomerListStatsModel.loading() => const CustomerListStatsModel(
        totalCount: 0,
        todayCount: 0,
        vipCount: 0,
        isLoading: true,
      );

  factory CustomerListStatsModel.empty() => const CustomerListStatsModel(
        totalCount: 0,
        todayCount: 0,
        vipCount: 0,
      );
}
