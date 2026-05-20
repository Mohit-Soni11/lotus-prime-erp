// -----------------------------------------------------------------------------
// FILE: customer_profile_app_bar.dart
// MODULE: Customer → Customer Profile
// CHANGE LOG:
//   - appBarSubtitle: now shows "LOTUS PRIME ERP" (from strings)
//   - Badge: removed yellow online dot — now clean icon + text only
//   - Badge icon: account_circle_rounded (from icons constant)
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../../theme/customer/customer_profile/customer_profile_theme.dart';

class CustomerProfileAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final VoidCallback onBack;
  final String customerName;

  const CustomerProfileAppBar({
    super.key,
    required this.onBack,
    required this.customerName,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(CustomerProfileStyles.appBarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: CustomerProfileStyles.appBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: CustomerProfileColors.shellPanelBg,
        border: Border(
          bottom:
              BorderSide(color: CustomerProfileColors.shellBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
              color: Color(0x26000000), blurRadius: 16, offset: Offset(0, 4))
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _HoverBackButton(onTap: onBack),
            const SizedBox(width: 20),
            _buildDivider(),
            const SizedBox(width: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ FIXED: Shows "LOTUS PRIME ERP" now
                Text(
                  CustomerProfileStrings.appBarSubtitle,
                  style: CustomerProfileStyles.appBarSubtitle,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: CustomerProfileColors.brandGold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: CustomerProfileColors.brandGold
                                .withValues(alpha: 0.6),
                            blurRadius: 6,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CustomerProfileStrings.appBarTitle,
                      style: CustomerProfileStyles.appBarTitle,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const _RadarWidget(),
              ],
            ),
            const Spacer(),
            // ✅ FIXED: Clean badge — no yellow dot, proper icon
            _buildBadge(customerName),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => Container(
        width: 1,
        height: 32,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              CustomerProfileColors.shellBorder,
              Colors.transparent,
            ],
          ),
        ),
      );

  // ✅ FIXED: Yellow dot removed, icon changed to account_circle_rounded
  Widget _buildBadge(String name) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: CustomerProfileColors.shellBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: CustomerProfileColors.brandGold.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: CustomerProfileColors.brandGold.withValues(alpha: 0.1),
              blurRadius: 10,
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ account_circle_rounded — clean profile icon, no yellow dot
            const Icon(
              CustomerProfileIcons.moduleIcon,
              color: CustomerProfileColors.brandGold,
              size: 18,
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.length > 15 ? "${name.substring(0, 13)}..." : name,
                  style: const TextStyle(
                    color: CustomerProfileColors.brandGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const Text(
                  "Customer Profile",
                  style: TextStyle(
                    color: CustomerProfileColors.shellTextMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// HOVER BACK BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _HoverBackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverBackButton({required this.onTap});

  @override
  State<_HoverBackButton> createState() => _HoverBackButtonState();
}

class _HoverBackButtonState extends State<_HoverBackButton> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _h ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _h
                  ? CustomerProfileColors.bodyPanelBg
                  : CustomerProfileColors.shellBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _h
                    ? CustomerProfileColors.brandGold
                    : CustomerProfileColors.shellBorder,
                width: _h ? 1.5 : 1,
              ),
              boxShadow: _h
                  ? [
                      BoxShadow(
                        color: CustomerProfileColors.brandGold
                            .withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [],
            ),
            child: Icon(
              CustomerProfileIcons.backArrow,
              color: _h
                  ? CustomerProfileColors.brandGold
                  : CustomerProfileColors.shellTextTitle,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RADAR / SYSTEM ONLINE WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _RadarWidget extends StatefulWidget {
  const _RadarWidget();

  @override
  State<_RadarWidget> createState() => _RadarWidgetState();
}

class _RadarWidgetState extends State<_RadarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _wave(0.0),
              _wave(0.5),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0xFF10B981), blurRadius: 6)
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
            ),
          ),
          child: const Text(
            "SYSTEM ONLINE",
            style: CustomerProfileStyles.systemOnlineText,
          ),
        ),
      ],
    );
  }

  Widget _wave(double d) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final v = (_c.value + d) % 1.0;
          return Opacity(
            opacity: 1.0 - v,
            child: Transform.scale(
              scale: 1.0 + v * 1.5,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          );
        },
      );
}
