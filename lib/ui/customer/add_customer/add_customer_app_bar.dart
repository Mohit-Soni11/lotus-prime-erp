// -----------------------------------------------------------------------------
// FILE: add_customer_app_bar.dart
// MODULE: Customer → Add New Customer
// DESCRIPTION: Dark app bar identical to POS + Customer List style.
//              Clean layout with module icon and radar status.
// -----------------------------------------------------------------------------
 
import 'package:flutter/material.dart';
import '../../../theme/customer/add_customer/add_customer_theme.dart';
 
class AddCustomerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
 
  const AddCustomerAppBar({super.key, required this.onBack});
 
  @override
  Size get preferredSize => const Size.fromHeight(AddCustomerStyles.appBarHeight);
 
  @override
  Widget build(BuildContext context) {
    return Container(
      height: AddCustomerStyles.appBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AddCustomerColors.shellPanelBg,
        border: Border(
          bottom: BorderSide(color: AddCustomerColors.shellBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // 1. BACK BUTTON
            _HoverBackButton(onTap: onBack),
            const SizedBox(width: 20),
 
            // 2. VERTICAL DIVIDER
            _buildDivider(),
            const SizedBox(width: 20),
 
            // 3. TITLE + RADAR (Matching Customer List exactly)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Title Row
                Row(
                  children: [
                    const Icon(
                      AddCustomerIcons.moduleIcon, // person_add_rounded icon
                      color: AddCustomerColors.brandGold,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AddCustomerStrings.appBarTitle, // "ADD NEW CUSTOMER"
                      style: AddCustomerStyles.appBarTitle,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // Radar status
                const _RadarStatusWidget(),
              ],
            ),
 
            const Spacer(), // Pushes everything to the left, module badge removed
          ],
        ),
      ),
    );
  }
 
  Widget _buildDivider() {
    return Container(
      width: 1, height: 32,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AddCustomerColors.shellBorder,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// HOVER BACK BUTTON (Gold hover — same as Customer List + POS)
// ─────────────────────────────────────────────────────────────────────────────
class _HoverBackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverBackButton({required this.onTap});
 
  @override
  State<_HoverBackButton> createState() => _HoverBackButtonState();
}
 
class _HoverBackButtonState extends State<_HoverBackButton> {
  bool _isHovered = false;
 
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 42, height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _isHovered
                  ? AddCustomerColors.bodyPanelBg
                  : AddCustomerColors.shellBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered
                    ? AddCustomerColors.brandGold
                    : AddCustomerColors.shellBorder,
                width: _isHovered ? 1.5 : 1.0,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: AddCustomerColors.brandGold.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              AddCustomerIcons.backArrow,
              color: _isHovered
                  ? AddCustomerColors.brandGold
                  : AddCustomerColors.shellTextTitle,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// RADAR STATUS (Same as POS + Customer List)
// ─────────────────────────────────────────────────────────────────────────────
class _RadarStatusWidget extends StatefulWidget {
  const _RadarStatusWidget();
 
  @override
  State<_RadarStatusWidget> createState() => _RadarStatusWidgetState();
}
 
class _RadarStatusWidgetState extends State<_RadarStatusWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
 
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }
 
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 14, height: 14,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _wave(0.0),
              _wave(0.5),
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Color(0xFF10B981), blurRadius: 6)],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
          ),
          child: const Text(
            AddCustomerStrings.systemOnline,
            style: AddCustomerStyles.systemOnlineText,
          ),
        ),
      ],
    );
  }
 
  Widget _wave(double delay) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final val = (_ctrl.value + delay) % 1.0;
        return Opacity(
          opacity: 1.0 - val,
          child: Transform.scale(
            scale: 1.0 + val * 1.5,
            child: Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.5),
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}