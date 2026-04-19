import 'package:flutter/material.dart';

class SidebarIcons {
  const SidebarIcons._();

  // --- Navigation Categories ---
  static IconData get dashboard => Icons.grid_view_rounded;
  static IconData get customer  => Icons.people_outline_rounded;
  static IconData get sales     => Icons.shopping_cart_outlined;
  static IconData get purchase  => Icons.shopping_bag_outlined;
  static IconData get stock     => Icons.inventory_2_outlined;
  static IconData get karigar   => Icons.engineering_outlined;
  static IconData get girvi     => Icons.lock_outline_rounded;
  static IconData get accounts  => Icons.account_balance_wallet_outlined;
  static IconData get reports   => Icons.assessment_outlined;
  static IconData get schemes   => Icons.calendar_month_outlined;

  // --- System Actions ---
  static IconData get settings  => Icons.settings_rounded;
  static IconData get logout    => Icons.power_settings_new_rounded;
  
  // --- UI Controls ---
  static IconData get collapse  => Icons.chevron_left_rounded;
  static IconData get expand    => Icons.menu_rounded;
}