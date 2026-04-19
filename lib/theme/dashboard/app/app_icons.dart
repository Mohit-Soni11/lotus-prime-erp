import 'package:flutter/material.dart';

class AppIcons {
  const AppIcons(); 

  // --- 1. CORE NAVIGATION ---
  IconData get dashboard => Icons.grid_view_rounded;
  IconData get customer => Icons.people_alt_rounded;
  IconData get sales => Icons.shopping_cart_rounded;
  IconData get inventory => Icons.inventory_2_rounded;
  IconData get settings => Icons.settings_rounded;
  IconData get logout => Icons.power_settings_new_rounded;
  
  // --- 2. ACTIONS ---
  IconData get search => Icons.search_rounded;
  IconData get notification => Icons.notifications_active_rounded;
  IconData get edit => Icons.edit_rounded;
  IconData get save => Icons.save_rounded;
  IconData get delete => Icons.delete_outline_rounded;
  
  // --- 3. STATUS & FEEDBACK ---
  IconData get success => Icons.check_circle_rounded;
  IconData get warning => Icons.warning_amber_rounded;
  IconData get defaultStore => Icons.store_rounded; 

  // --- 4. FORM & AUTH (Login Screen Specific - ADDED THESE) ---
  IconData get email => Icons.email_outlined;
  IconData get lock => Icons.lock_outline;
  IconData get visible => Icons.visibility_outlined;
  IconData get visibleOff => Icons.visibility_off_outlined;
  IconData get person => Icons.person_outline;
  IconData get phone => Icons.phone_android_rounded;
  IconData get business => Icons.store_mall_directory_outlined;
}