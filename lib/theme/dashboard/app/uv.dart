import 'app_colors.dart';
import 'app_icons.dart';
import 'app_text_styles.dart';
import 'app_layout.dart';

/// UV — Unified Visual design system facade.
///
/// Single source of truth for all design tokens in Lotus ERP.
/// Access colors, icons, text styles, and layout constants via:
///   UV.colors.bgPrimary, UV.icons.appLogo, UV.styles.h1, UV.layout.pagePadding
class UV {
  UV._();

  // ── Global Design Tokens ──────────────────────────────────────────────────
  static const colors = AppColors();
  static const icons = AppIcons();
  static const styles = AppTextStyles();
  static const layout = AppLayout();
}
