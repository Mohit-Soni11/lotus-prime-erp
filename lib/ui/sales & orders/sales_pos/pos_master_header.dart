// ==========================================
// FILE: pos_master_header.dart
// TYPE: Smart UI Component (UPGRADED & MERGED)
// DESCRIPTION: Dynamic App Bar listening to AuthProfileController.
//              ✅ Back button merged (Original Color, No Gold Hover).
// ==========================================

import 'package:flutter/material.dart';
import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import '../../../logic/sales & orders/sales pos/auth_profile_controller.dart';

class PosMasterHeader extends StatelessWidget implements PreferredSizeWidget {
  final AuthProfileController authCtrl;
  final VoidCallback onBack;

  const PosMasterHeader({
    super.key,
    required this.authCtrl,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70.0);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authCtrl,
      builder: (context, _) {
        Color badgeColor = authCtrl.roleColor;
        bool isOwner = authCtrl.hasGoldenGlow;

        return Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: SalesPosColors.shellBg,
            border: const Border(
              bottom: BorderSide(color: SalesPosColors.shellBorder, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // --- 1. BACK BUTTON (Original Color, Fixed Hover) ---
              _SolidBackButton(onTap: onBack),
              const SizedBox(width: 20),

              // --- 2. VERTICAL SEPARATOR ---
              Container(
                width: 1,
                height: 32,
                color: SalesPosColors.shellBorder,
              ),
              const SizedBox(width: 20),

              // --- 3. PROFESSIONAL BOARD NAME & DYNAMIC SHOP INFO ---
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ENTERPRISE POS TERMINAL", 
                      style: SalesPosStyles.headerTitle.copyWith(
                        color: SalesPosColors.brandSilver,
                        fontSize: 12,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          authCtrl.displayShopName.toUpperCase(),
                          style: const TextStyle(
                            color: SalesPosColors.shellTextTitle,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: SalesPosColors.shellPanelBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: SalesPosColors.shellBorder),
                          ),
                          child: Text(
                            authCtrl.shopCity.toUpperCase(), 
                            style: const TextStyle(
                              color: SalesPosColors.shellTextMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // --- 4. DYNAMIC USER BADGE WITH GLOW LOGIC ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: SalesPosColors.badgeBg,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isOwner ? badgeColor.withOpacity(0.5) : SalesPosColors.shellBorder,
                  ),
                  boxShadow: isOwner
                      ? [
                          BoxShadow(
                            color: badgeColor.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          )
                        ]
                      : [], 
                ),
                child: Row(
                  children: [
                    Icon(
                      SalesPosIcons.profile,
                      color: badgeColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authCtrl.loggedInUserName,
                          style: SalesPosStyles.badgeNameText,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          authCtrl.displayRoleName, 
                          style: SalesPosStyles.badgeRoleText.copyWith(
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// SOLID BACK BUTTON (No Gold Hover)
// =============================================================================
class _SolidBackButton extends StatefulWidget {
  final VoidCallback onTap;

  const _SolidBackButton({required this.onTap});

  @override
  State<_SolidBackButton> createState() => _SolidBackButtonState();
}

class _SolidBackButtonState extends State<_SolidBackButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isHovered ? SalesPosColors.bodyBorder : SalesPosColors.bodyPanelBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: SalesPosColors.bodyBorder,
              width: 1.0,
            ),
          ),
          child: const Icon(
            Icons.arrow_back_rounded, 
            color: SalesPosColors.textDark, // Original solid dark color
            size: 20,
          ),
        ),
      ),
    );
  }
}