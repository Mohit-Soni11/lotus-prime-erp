import 'app_colors.dart';
import 'app_icons.dart';
import 'app_text_styles.dart';
import 'app_layout.dart';

class UV {
  // Private constructor
  UV._(); 

  // ==========================================
  // --- 1. GLOBAL APP THEME (Base Layers) ---
  // ==========================================
  // Ye wo chizein hain jo poori app mein use hongi (Login, Dashboard, Settings sab jagah)
  
  static const colors = AppColors();     // e.g. UV.colors.primaryBrand
  static const icons = AppIcons();       // e.g. UV.icons.appLogo
  static const styles = AppTextStyles(); // e.g. UV.styles.h1
  static const layout = AppLayout();     // e.g. UV.layout.pagePadding

  // ==========================================
  // --- 2. MODULES (Removed) ---
  // ==========================================
  // TopBar, Sidebar, etc. ab apne 'Manager' se directly call honge.
  // UV ko unki chinta karne ki zaroorat nahi.
}