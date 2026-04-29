// =============================================================================
// FILE        : purchase_customer_panel.dart
// MODULE      : Purchase Entry
// LAYER       : UI
// DESCRIPTION : Seller/Customer details panel with slide-in animation.
//               Matches Sales POS customer panel design.
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/purchase/purchase_entry/purchase_entry_theme.dart';
import '../../../logic/purchase/purchase_entry_controller.dart';
import '../../../models/purchase/purchase_enums/purchase_enums.dart';

class PurchaseCustomerPanel extends StatefulWidget {
  final PurchaseEntryController ctrl;

  const PurchaseCustomerPanel({super.key, required this.ctrl});

  @override
  State<PurchaseCustomerPanel> createState() => _PurchaseCustomerPanelState();
}

class _PurchaseCustomerPanelState extends State<PurchaseCustomerPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

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
      end: Offset.zero,
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
    return ListenableBuilder(
      listenable: widget.ctrl,
      builder: (_, __) {
        final bool isCustomer =
            widget.ctrl.purchaseSource == PurchaseSource.fromCustomer;

        return FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: PurchaseEntryColors.bodyPanel,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: PurchaseEntryColors.purchaseAccent.withOpacity(0.10),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                  const BoxShadow(
                    color: PurchaseEntryColors.shadowDark,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: PurchaseEntryColors.purchaseAccent.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              PurchaseEntryColors.purchaseAccent,
                              PurchaseEntryColors.purchaseAccentMid,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: PurchaseEntryColors.purchaseAccent
                                  .withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          PurchaseEntryIcons.profile,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCustomer
                                ? 'CUSTOMER (SELLER) DETAILS'
                                : 'SUPPLIER DETAILS',
                            style: PurchaseEntryStyles.highVisHeader,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isCustomer
                                ? 'Customer jo sona bech raha hai'
                                : 'Supplier from whom purchasing',
                            style: PurchaseEntryStyles.subTitleMuted,
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Session badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: PurchaseEntryColors.purchaseAccent
                              .withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: PurchaseEntryColors.purchaseAccent
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: PurchaseEntryColors.purchaseAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Purchase Session',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: PurchaseEntryColors.purchaseAccentMid,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Gold divider
                  Container(
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          PurchaseEntryColors.purchaseAccent.withOpacity(0.5),
                          PurchaseEntryColors.purchaseAccent.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Fields row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildInput(
                          label: 'MOBILE',
                          hint: '10-digit',
                          controller: widget.ctrl.mobileCtrl,
                          isNumber: true,
                          icon: PurchaseEntryIcons.mobilePhone,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: _buildInput(
                          label: isCustomer ? 'CUSTOMER NAME' : 'SUPPLIER NAME',
                          hint: 'Enter full name',
                          controller: widget.ctrl.nameCtrl,
                          icon: PurchaseEntryIcons.customerName,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _buildInput(
                          label: 'CITY / AREA',
                          hint: 'Enter city',
                          controller: widget.ctrl.cityCtrl,
                          icon: PurchaseEntryIcons.cityLocation,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _buildInput(
                          label: 'PAN / AADHAR',
                          hint: 'Document ID',
                          controller: widget.ctrl.panCtrl,
                          isCaps: true,
                          icon: PurchaseEntryIcons.panCard,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _buildInput(
                          label: 'GST NUMBER',
                          hint: '15-digit GSTIN',
                          controller: widget.ctrl.gstCtrl,
                          isCaps: true,
                          icon: PurchaseEntryIcons.gstNumber,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Buttons column
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _HoverButton(
                            title: 'Search',
                            icon: PurchaseEntryIcons.searchItem,
                            isPrimary: false,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Seller search will be wired into this panel in the next update.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          _HoverButton(
                            title: isCustomer ? 'New Customer' : 'New Supplier',
                            icon: PurchaseEntryIcons.newSupplier,
                            isPrimary: true,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Inline seller creation is planned for a follow-up update.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
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
      },
    );
  }

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
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: PurchaseEntryColors.purchaseAccent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PurchaseEntryColors.textDark,
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
            textCapitalization: isCaps
                ? TextCapitalization.characters
                : TextCapitalization.none,
            style: PurchaseEntryStyles.inputText,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: PurchaseEntryColors.textMuted.withOpacity(0.6),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: icon != null
                  ? Icon(icon, size: 18, color: PurchaseEntryColors.textMuted)
                  : null,
              filled: true,
              fillColor: PurchaseEntryColors.formInputBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              border: OutlineInputBorder(
                borderSide:
                    const BorderSide(color: PurchaseEntryColors.bodyBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide:
                    const BorderSide(color: PurchaseEntryColors.bodyBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: PurchaseEntryColors.purchaseAccent,
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

// ── Hover Button ──────────────────────────────────────────────────────────────
class _HoverButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _HoverButton({
    required this.title,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
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
              color: widget.isPrimary
                  ? null
                  : (_isHovered
                      ? PurchaseEntryColors.bodyPanel
                      : PurchaseEntryColors.formInputBg),
              gradient: widget.isPrimary
                  ? LinearGradient(
                      colors: [
                        _isHovered
                            ? PurchaseEntryColors.purchaseAccentMid
                            : PurchaseEntryColors.purchaseAccent,
                        PurchaseEntryColors.purchaseAccentMid,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              border: widget.isPrimary
                  ? null
                  : Border.all(
                      color: _isHovered
                          ? PurchaseEntryColors.purchaseAccent
                          : PurchaseEntryColors.bodyBorder,
                      width: _isHovered ? 1.5 : 1.0,
                    ),
              boxShadow: [
                if (widget.isPrimary)
                  BoxShadow(
                    color: PurchaseEntryColors.purchaseAccent
                        .withOpacity(_isHovered ? 0.5 : 0.3),
                    blurRadius: _isHovered ? 16 : 10,
                    offset: const Offset(0, 4),
                  )
                else if (_isHovered)
                  BoxShadow(
                    color: PurchaseEntryColors.purchaseAccent.withOpacity(0.15),
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
                      : (_isHovered
                          ? PurchaseEntryColors.purchaseAccentMid
                          : PurchaseEntryColors.textDark),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: widget.isPrimary
                        ? Colors.white
                        : (_isHovered
                            ? PurchaseEntryColors.purchaseAccentMid
                            : PurchaseEntryColors.textDark),
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
