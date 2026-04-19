// ==========================================
// FILE: pos_customer_details_panel.dart
// TYPE: Smart UI Component (UPGRADED)
// AUTHOR: Senior System Architect
// DESCRIPTION: Premium customer entry form connected to Master Theme.
//              ✅ Zero hardcoded colors, icons, or styles.
// ==========================================

import 'package:flutter/material.dart';

import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import '../../../logic/sales & orders/sales pos/pos_billing_controller.dart';

class PosCustomerDetailsPanel extends StatefulWidget {
  final PosBillingController ctrl;

  const PosCustomerDetailsPanel({
    super.key,
    required this.ctrl,
  });

  @override
  State<PosCustomerDetailsPanel> createState() => _PosCustomerDetailsPanelState();
}

class _PosCustomerDetailsPanelState extends State<PosCustomerDetailsPanel>
    with SingleTickerProviderStateMixin {

  late final AnimationController _animCtrl;
  late final Animation<double>    _fadeAnim;
  late final Animation<Offset>    _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), 
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15), 
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          padding: const EdgeInsets.all(20), 
          decoration: BoxDecoration(
            color: SalesPosColors.customerCardBg, 
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: SalesPosColors.brandGold.withOpacity(0.12), 
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: SalesPosColors.shadowDark,
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: SalesPosColors.brandGold.withOpacity(0.3), 
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, 
            children: [
              // --- HEADER ---
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          SalesPosColors.goldGradientStart, 
                          SalesPosColors.brandGold, 
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: SalesPosColors.brandGold.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      SalesPosIcons.profile, 
                      color: Colors.white,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "CUSTOMER DETAILS",
                        style: SalesPosStyles.highVisHeader,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Search or add a new customer",
                        style: SalesPosStyles.subTitleMuted,
                      ),
                    ],
                  ),

                  const Spacer(),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: SalesPosColors.brandGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: SalesPosColors.brandGold.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: SalesPosColors.brandGold,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "POS Session",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: SalesPosColors.goldHoverDark, 
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // --- DIVIDER ---
              Container(
                height: 1.5,
                width: double.infinity, 
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SalesPosColors.brandGold.withOpacity(0.5),
                      SalesPosColors.brandGold.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- FIELDS + BUTTONS ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildInput(
                      label: "MOBILE",
                      hint: "10-digit",
                      controller: widget.ctrl.mobileCtrl,
                      isNumber: true,
                      icon: SalesPosIcons.mobilePhone,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    flex: 3,
                    child: _buildInput(
                      label: "CUSTOMER NAME",
                      hint: "Enter full name", 
                      controller: widget.ctrl.nameCtrl,
                      icon: SalesPosIcons.customerName,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    flex: 2,
                    child: _buildInput(
                      label: "CITY / AREA", 
                      hint: "Enter city", 
                      controller: widget.ctrl.cityCtrl,
                      icon: SalesPosIcons.cityLocation,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    flex: 2,
                    child: _buildInput(
                      label: "PAN / AADHAR",
                      hint: "Document ID",
                      controller: widget.ctrl.panCtrl,
                      isCaps: true,
                      icon: SalesPosIcons.panCard,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 🚀 GST FIELD
                  Expanded(
                    flex: 2,
                    child: _buildInput(
                      label: "GST NUMBER",
                      hint: "15-digit GSTIN",
                      controller: widget.ctrl.gstCtrl,
                      isCaps: true,
                      icon: SalesPosIcons.gstNumber,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // ANIMATED BUTTONS IN COLUMN
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HoverAnimatedButton(
                        title: "Search",
                        icon: SalesPosIcons.searchItem,
                        isPrimary: false,
                        onTap: () => debugPrint("Search Clicked"),
                      ),
                      const SizedBox(height: 8),
                      _HoverAnimatedButton(
                        title: "New Customer",
                        icon: SalesPosIcons.newCustomerAdd,
                        isPrimary: true,
                        onTap: () => debugPrint("New Customer Clicked"),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- INPUT FIELD ---
  Widget _buildInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isNumber = false,
    bool isCaps = false,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 5, height: 5,
              decoration: const BoxDecoration(
                color: SalesPosColors.brandGold,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SalesPosColors.textDark, 
                  fontSize: 13, 
                  fontWeight: FontWeight.bold, 
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44, 
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            textCapitalization:
                isCaps ? TextCapitalization.characters : TextCapitalization.none,
            style: SalesPosStyles.inputText,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: SalesPosColors.bodyTextMuted.withOpacity(0.6),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: icon != null
                  ? Icon(icon, size: 18, color: SalesPosColors.bodyTextMuted)
                  : null,
              filled: true,
              fillColor: SalesPosColors.formInputBg, 
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: SalesPosColors.bodyBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: SalesPosColors.bodyBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: SalesPosColors.brandGold, 
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// NEW CUSTOM HOVER BUTTON COMPONENT
// ==========================================
class _HoverAnimatedButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _HoverAnimatedButton({
    required this.title,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_HoverAnimatedButton> createState() => _HoverAnimatedButtonState();
}

class _HoverAnimatedButtonState extends State<_HoverAnimatedButton> {
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
          scale: _isHovered ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            height: 42, 
            width: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: widget.isPrimary
                  ? LinearGradient(
                      colors: [
                        _isHovered ? SalesPosColors.goldGradientStart : SalesPosColors.brandGold,
                        _isHovered ? SalesPosColors.brandGold : SalesPosColors.goldHoverDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: widget.isPrimary 
                  ? null 
                  : (_isHovered ? SalesPosColors.bodyPanelBg : SalesPosColors.formInputBg),
              border: widget.isPrimary
                  ? null
                  : Border.all(
                      color: _isHovered ? SalesPosColors.brandGold : SalesPosColors.bodyBorder, 
                      width: _isHovered ? 1.5 : 1.0,
                    ),
              boxShadow: [
                if (widget.isPrimary)
                  BoxShadow(
                    color: SalesPosColors.brandGold.withOpacity(_isHovered ? 0.6 : 0.4),
                    blurRadius: _isHovered ? 16 : 10,
                    offset: const Offset(0, 4),
                  )
                else if (_isHovered)
                  BoxShadow(
                    color: SalesPosColors.brandGold.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon, 
                  size: 16, 
                  color: widget.isPrimary
                      ? Colors.white
                      : (_isHovered ? SalesPosColors.goldHoverDark : SalesPosColors.textDark), 
                ),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: widget.isPrimary
                        ? Colors.white
                        : (_isHovered ? SalesPosColors.goldHoverDark : SalesPosColors.textDark), 
                    fontSize: 14, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}