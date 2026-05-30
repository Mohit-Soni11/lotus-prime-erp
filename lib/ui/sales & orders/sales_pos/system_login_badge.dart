// ==========================================
// FILE: system_login_badge.dart
// TYPE: Smart UI Component
// AUTHOR: Senior System Architect
// DESCRIPTION: Premium animated login badge with dynamic role colors.
// ==========================================

import 'package:flutter/material.dart';
// BOSS: Update this path to where your theme file is located
import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';

class SystemLoginBadge extends StatefulWidget {
  final String userName;
  final String userRole;
  final String userInitials;

  const SystemLoginBadge({
    super.key,
    required this.userName,
    required this.userRole,
    required this.userInitials,
  });

  @override
  State<SystemLoginBadge> createState() => _SystemLoginBadgeState();
}

class _SystemLoginBadgeState extends State<SystemLoginBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  bool get _isOwner => widget.userRole.toLowerCase() == 'owner';
  bool get _isManager => widget.userRole.toLowerCase() == 'manager';

  Color get _primaryColor {
    if (_isOwner) return SalesPosColors.roleOwner;
    if (_isManager) return SalesPosColors.roleManager;
    return SalesPosColors.roleStaff;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final double glowOpacity = 0.1 + (0.2 * _glowController.value);
        final double spread = 2 * _glowController.value;

        return Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            // Layered dark glass background
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SalesPosColors.badgeBg,
                Color(0xFF111520), // Slightly deeper bottom
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _primaryColor.withValues(alpha: 0.22),
              width: 1,
            ),
            boxShadow: [
              // Role glow
              BoxShadow(
                color: _primaryColor.withValues(alpha: glowOpacity),
                blurRadius: 16,
                spreadRadius: spread,
              ),
              // Deep base shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAvatar(),
              const SizedBox(width: 12),
              _buildUserInfo(),
              const SizedBox(width: 12),
              _buildVerticalDivider(),
              const SizedBox(width: 12),
              _buildLogoutIcon(),
            ],
          ),
        );
      },
    );
  }

  //  AVATAR 
  Widget _buildAvatar() {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer sweep ring
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  _primaryColor,
                  _primaryColor.withValues(alpha: 0.1),
                  _primaryColor,
                ],
              ),
            ),
          ),
          // Gap ring
          CircleAvatar(
            radius: 16,
            backgroundColor: SalesPosColors.badgeBg,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: _primaryColor.withValues(alpha: 0.15),
              child: Text(
                widget.userInitials,
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          // Online dot
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: SalesPosColors.onlineIndicator,
                shape: BoxShape.circle,
                border: Border.all(
                  color: SalesPosColors.badgeBg,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        SalesPosColors.onlineIndicator.withValues(alpha: 0.6),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //  USER INFO 
  Widget _buildUserInfo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.userName,
          style: SalesPosStyles.badgeNameText.copyWith(
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        // Role pill  -  gradient with refined style
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _primaryColor.withValues(alpha: 0.85),
                _primaryColor.withValues(alpha: 0.55),
              ],
            ),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            widget.userRole.toUpperCase(),
            style: SalesPosStyles.badgeRoleText.copyWith(
              fontSize: 9,
              letterSpacing: 0.8,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  //  VERTICAL DIVIDER 
  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 26,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            SalesPosColors.shellBorder,
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  //  LOGOUT ICON 
  Widget _buildLogoutIcon() {
    return const Icon(
      SalesPosIcons.logout,
      size: 16,
      color: SalesPosColors.shellTextMuted,
    );
  }
}
