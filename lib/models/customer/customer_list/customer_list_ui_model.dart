// -----------------------------------------------------------------------------
// FILE: customer_list_ui_model.dart
// MODULE: Customer -> Customer List
// DESCRIPTION: Immutable view models for the production customer directory.
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

import '../customer_enums/customer_list_enums.dart';

@immutable
class CustomerListItemModel {
  static const double _moneyTolerance = 0.01;

  final int id;
  final String name;
  final String mobile;
  final String city;
  final CustomerType type;
  final int billCount;
  final int activeAdvanceCount;
  final int activeGirviCount;
  final double invoiceValue;
  final double dueAmount;
  final DateTime createdAt;
  final DateTime lastActivityAt;
  final CustomerActivityKind lastActivityKind;
  final String lastActivityLabel;
  final String lastActivityDetail;
  final String initials;

  const CustomerListItemModel({
    required this.id,
    required this.name,
    required this.mobile,
    required this.city,
    required this.type,
    required this.billCount,
    this.activeAdvanceCount = 0,
    this.activeGirviCount = 0,
    this.invoiceValue = 0,
    this.dueAmount = 0,
    required this.createdAt,
    DateTime? lastActivityAt,
    this.lastActivityKind = CustomerActivityKind.profile,
    this.lastActivityLabel = "Client profile created",
    this.lastActivityDetail = "No transaction posted yet",
    required this.initials,
  }) : lastActivityAt = lastActivityAt ?? createdAt;

  bool get isVip => type == CustomerType.elite;
  bool get hasDue => dueAmount > _moneyTolerance;
  bool get hasOpenWork => activeAdvanceCount > 0 || activeGirviCount > 0;

  bool get isNewToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }

  bool get isNewThisMonth {
    final now = DateTime.now();
    return createdAt.year == now.year && createdAt.month == now.month;
  }

  bool get hasActivityToday {
    final now = DateTime.now();
    return lastActivityAt.year == now.year &&
        lastActivityAt.month == now.month &&
        lastActivityAt.day == now.day;
  }

  bool get isActiveAccount {
    final daysSinceActivity = DateTime.now().difference(lastActivityAt).inDays;
    return daysSinceActivity <= 90 || hasOpenWork || hasDue;
  }

  String get formattedDate => _formatDate(createdAt);
  String get formattedLastActivityDate => _formatDate(lastActivityAt);

  String get activityAgeLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activityDay = DateTime(
      lastActivityAt.year,
      lastActivityAt.month,
      lastActivityAt.day,
    );
    final days = today.difference(activityDay).inDays;

    if (days <= 0) return "Today";
    if (days == 1) return "Yesterday";
    if (days < 7) return "$days days ago";
    if (days < 30) return "${(days / 7).floor()} weeks ago";
    if (days < 365) return "${(days / 30).floor()} months ago";
    return "${(days / 365).floor()} years ago";
  }

  static String buildInitials(String name) {
    final value = name.trim();
    if (value.isEmpty) return "NA";

    final parts = value.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
  }

  static String _formatDate(DateTime date) {
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
      'Dec',
    ];

    return "${date.day.toString().padLeft(2, '0')} "
        "${months[date.month]} ${date.year}";
  }
}

@immutable
class CustomerListStatsModel {
  final int totalCount;
  final int activeCount;
  final int todayCount;
  final int monthCount;
  final int vipCount;
  final int dueCustomerCount;
  final int totalBillCount;
  final int activeAdvanceCount;
  final int activeGirviCount;
  final double totalInvoiceValue;
  final double totalDueAmount;
  final bool isLoading;

  const CustomerListStatsModel({
    required this.totalCount,
    required this.activeCount,
    required this.todayCount,
    required this.monthCount,
    required this.vipCount,
    required this.dueCustomerCount,
    required this.totalBillCount,
    required this.activeAdvanceCount,
    required this.activeGirviCount,
    required this.totalInvoiceValue,
    required this.totalDueAmount,
    this.isLoading = false,
  });

  double get activeRatio => totalCount == 0 ? 0 : activeCount / totalCount;
  int get activePercentage => (activeRatio * 100).round();

  factory CustomerListStatsModel.fromCustomers(
    List<CustomerListItemModel> customers,
  ) {
    if (customers.isEmpty) return CustomerListStatsModel.empty();

    return CustomerListStatsModel(
      totalCount: customers.length,
      activeCount: customers.where((c) => c.isActiveAccount).length,
      todayCount: customers.where((c) => c.isNewToday).length,
      monthCount: customers.where((c) => c.isNewThisMonth).length,
      vipCount: customers.where((c) => c.isVip).length,
      dueCustomerCount: customers.where((c) => c.hasDue).length,
      totalBillCount: customers.fold(0, (sum, c) => sum + c.billCount),
      activeAdvanceCount:
          customers.fold(0, (sum, c) => sum + c.activeAdvanceCount),
      activeGirviCount: customers.fold(0, (sum, c) => sum + c.activeGirviCount),
      totalInvoiceValue: customers.fold(0.0, (sum, c) => sum + c.invoiceValue),
      totalDueAmount: customers.fold(0.0, (sum, c) => sum + c.dueAmount),
    );
  }

  factory CustomerListStatsModel.loading() => const CustomerListStatsModel(
        totalCount: 0,
        activeCount: 0,
        todayCount: 0,
        monthCount: 0,
        vipCount: 0,
        dueCustomerCount: 0,
        totalBillCount: 0,
        activeAdvanceCount: 0,
        activeGirviCount: 0,
        totalInvoiceValue: 0,
        totalDueAmount: 0,
        isLoading: true,
      );

  factory CustomerListStatsModel.empty() => const CustomerListStatsModel(
        totalCount: 0,
        activeCount: 0,
        todayCount: 0,
        monthCount: 0,
        vipCount: 0,
        dueCustomerCount: 0,
        totalBillCount: 0,
        activeAdvanceCount: 0,
        activeGirviCount: 0,
        totalInvoiceValue: 0,
        totalDueAmount: 0,
      );
}
