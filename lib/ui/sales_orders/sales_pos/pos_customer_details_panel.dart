// ==========================================
// FILE: pos_customer_details_panel.dart
// TYPE: UI Component
// DESCRIPTION: Customer entry, customer lookup, suggestion overlay, and customer history panel for POS billing.
// ==========================================

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import '../../../logic/sales_orders/sales_pos/pos_billing_controller.dart';
import '../../customer/add_customer/add_customer_screen.dart';

class PosCustomerDetailsPanel extends StatefulWidget {
  final PosBillingController ctrl;

  const PosCustomerDetailsPanel({
    super.key,
    required this.ctrl,
  });

  @override
  State<PosCustomerDetailsPanel> createState() =>
      _PosCustomerDetailsPanelState();
}

class _PosCustomerDetailsPanelState extends State<PosCustomerDetailsPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // Dono fields ke liye alag-alag LayerLink
  final LayerLink _mobileSuggestionLink = LayerLink();
  final LayerLink _nameSuggestionLink = LayerLink();

  OverlayEntry? _suggestionOverlay;

  // Tracks whether the mobile or name field is active.
  bool _isMobileActive = false;

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

    widget.ctrl.nameCtrl.addListener(_onNameChanged);
    widget.ctrl.mobileCtrl.addListener(_onMobileChanged);
    widget.ctrl.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _removeSuggestionOverlay();
    widget.ctrl.nameCtrl.removeListener(_onNameChanged);
    widget.ctrl.mobileCtrl.removeListener(_onMobileChanged);
    widget.ctrl.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onNameChanged() {
    _isMobileActive = false;
    // Skip name lookup when the selected customer already matches.
    if (widget.ctrl.selectedCustomer != null) {
      if (widget.ctrl.nameCtrl.text == widget.ctrl.selectedCustomer!.name) {
        return;
      }
      widget.ctrl.selectedCustomer =
          null; // Customer selection has been cleared.
    }
    widget.ctrl.searchCustomersByName(widget.ctrl.nameCtrl.text);
  }

  void _onMobileChanged() {
    _isMobileActive = true;
    // Skip mobile lookup when the selected customer already matches.
    if (widget.ctrl.selectedCustomer != null) {
      if (widget.ctrl.mobileCtrl.text == widget.ctrl.selectedCustomer!.mobile) {
        return;
      }
      widget.ctrl.selectedCustomer =
          null; // Customer selection has been cleared.
    }
    final mobile = widget.ctrl.mobileCtrl.text.trim();
    // 1 character se hi search
    if (mobile.isNotEmpty) {
      widget.ctrl.searchCustomersByName(mobile);
    } else {
      widget.ctrl.clearCustomerSuggestions();
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;

    // setState is required when selectedCustomer changes.
    //         (select ya deselect), widget rebuild ho aur history card
    //         so the history card visibility updates during build.
    //         The selectedCustomer null check alone is insufficient.
    setState(() {});

    final suggestions = widget.ctrl.customerSuggestions;
    final notFound = widget.ctrl.customerNotFound;

    if (suggestions.isEmpty && !notFound) {
      _removeSuggestionOverlay();
    } else {
      _showSuggestionOverlay();
    }
  }

  void _removeSuggestionOverlay() {
    _suggestionOverlay?.remove();
    _suggestionOverlay = null;
  }

  void _showSuggestionOverlay() {
    if (!mounted) return;
    _removeSuggestionOverlay();

    // Use the layer link belonging to the active field.
    final activeLink =
        _isMobileActive ? _mobileSuggestionLink : _nameSuggestionLink;

    final overlay = Overlay.of(context);
    _suggestionOverlay = OverlayEntry(
      builder: (ctx) => Positioned(
        width: 320,
        child: CompositedTransformFollower(
          link: activeLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 52),
          child: Material(
            color: Colors.transparent,
            child: _CustomerSuggestionDropdown(
              ctrl: widget.ctrl,
              onSelected: () => _removeSuggestionOverlay(),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_suggestionOverlay!);
  }

  bool get _hasLookupText =>
      widget.ctrl.nameCtrl.text.trim().length >= 2 ||
      widget.ctrl.mobileCtrl.text.trim().length >= 3;

  bool get _noCustomerFound =>
      _hasLookupText &&
      widget.ctrl.customerNotFound &&
      widget.ctrl.customerSuggestions.isEmpty &&
      widget.ctrl.selectedCustomer == null;

  Future<void> _openQuickAddCustomer() async {
    _removeSuggestionOverlay();
    final initialMobile = widget.ctrl.mobileCtrl.text.trim();
    final initialName = widget.ctrl.nameCtrl.text.trim();
    final initialAddress = widget.ctrl.cityCtrl.text.trim();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddCustomerScreen(
          initialName: initialName,
          initialMobile: initialMobile,
          initialAddress: initialAddress,
          onSaved: () {
            if (!mounted) return;
            Navigator.pop(context);
            if (initialMobile.isNotEmpty) {
              unawaited(widget.ctrl.selectCustomerByMobile(initialMobile));
            } else if (initialName.isNotEmpty) {
              unawaited(widget.ctrl.searchCustomersByName(initialName));
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: SalesPosColors.customerCardBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: SalesPosColors.brandGold.withValues(alpha: 0.12),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                  const BoxShadow(
                    color: SalesPosColors.shadowDark,
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: SalesPosColors.brandGold.withValues(alpha: 0.3),
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
                              color: SalesPosColors.brandGold
                                  .withValues(alpha: 0.4),
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

                      //  "NEW CUSTOMER" BANNER IF NOT FOUND
                      ListenableBuilder(
                        listenable: widget.ctrl,
                        builder: (context, _) {
                          if (!_noCustomerFound) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: SalesPosColors.brandGold
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: SalesPosColors.brandGold
                                      .withValues(alpha: 0.4),
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
                                      fontSize: SalesPosStyles.fontCaption,
                                      fontWeight: FontWeight.bold,
                                      color: SalesPosColors.goldHoverDark,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return GestureDetector(
                            onTap: _openQuickAddCustomer,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    SalesPosColors.goldGradientStart,
                                    SalesPosColors.brandGold,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: SalesPosColors.brandGold
                                        .withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(SalesPosIcons.newCustomerAdd,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    "Create New Customer",
                                    style: TextStyle(
                                      fontSize: SalesPosStyles.fontCaption,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
                          SalesPosColors.brandGold.withValues(alpha: 0.5),
                          SalesPosColors.brandGold.withValues(alpha: 0.1),
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
                      //  MOBILE FIELD  -  apna LayerLink
                      Expanded(
                        flex: 2,
                        child: CompositedTransformTarget(
                          link: _mobileSuggestionLink,
                          child: _buildInput(
                            label: "MOBILE",
                            hint: "10-digit",
                            controller: widget.ctrl.mobileCtrl,
                            isNumber: true,
                            icon: SalesPosIcons.mobilePhone,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      //  NAME FIELD  -  apna LayerLink
                      Expanded(
                        flex: 3,
                        child: CompositedTransformTarget(
                          link: _nameSuggestionLink,
                          child: _buildInput(
                            label: "CUSTOMER NAME",
                            hint: "Enter full name",
                            controller: widget.ctrl.nameCtrl,
                            icon: SalesPosIcons.customerName,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        flex: 4,
                        child: _buildInput(
                          label: "ADDRESS",
                          hint: "Customer address",
                          controller: widget.ctrl.cityCtrl,
                          icon: SalesPosIcons.cityLocation,
                        ),
                      ),
                      const SizedBox(width: 16),

                      //  BUTTONS
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _HoverAnimatedButton(
                            title: "Search",
                            icon: SalesPosIcons.searchItem,
                            isPrimary: false,
                            onTap: () => widget.ctrl.searchCustomersByName(
                              widget.ctrl.mobileCtrl.text.isNotEmpty
                                  ? widget.ctrl.mobileCtrl.text
                                  : widget.ctrl.nameCtrl.text,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _HoverAnimatedButton(
                            title: "New Customer",
                            icon: SalesPosIcons.newCustomerAdd,
                            isPrimary: true,
                            onTap: _openQuickAddCustomer,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            //  Customer history card displayed after customer selection.
            if (widget.ctrl.selectedCustomer != null) ...[
              const SizedBox(height: 10),
              _PosCustomerHistoryCard(ctrl: widget.ctrl),
            ],
          ],
        ),
      ),
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
                  fontSize: SalesPosStyles.fontLabel,
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
            style: SalesPosStyles.inputText,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: SalesPosColors.bodyTextMuted.withValues(alpha: 0.6),
                fontSize: SalesPosStyles.fontLabel,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: icon != null
                  ? Icon(icon, size: 18, color: SalesPosColors.bodyTextMuted)
                  : null,
              filled: true,
              fillColor: SalesPosColors.formInputBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
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
// CUSTOMER SUGGESTION DROPDOWN
// ==========================================
class _CustomerSuggestionDropdown extends StatelessWidget {
  final PosBillingController ctrl;
  final VoidCallback onSelected;

  const _CustomerSuggestionDropdown({
    required this.ctrl,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        final suggestions = ctrl.customerSuggestions;
        final notFound = ctrl.customerNotFound;

        // No content is shown for this state.
        if (suggestions.isEmpty && !notFound) return const SizedBox.shrink();

        return Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(12),
          color: SalesPosColors.bodyPanelBg,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              border: Border.all(
                color: notFound && suggestions.isEmpty
                    ? SalesPosColors.danger.withValues(alpha: 0.25)
                    : SalesPosColors.brandGold.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: notFound && suggestions.isEmpty
                //  CUSTOMER NOT FOUND STATE
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color:
                                SalesPosColors.danger.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.person_off_outlined,
                            color: SalesPosColors.danger,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Customer Not Found",
                                style: TextStyle(
                                  color: SalesPosColors.danger,
                                  fontWeight: FontWeight.bold,
                                  fontSize: SalesPosStyles.fontLabel,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Not Registered  -  Click 'New Customer' to add",
                                style: TextStyle(
                                  color: SalesPosColors.bodyTextMuted,
                                  fontSize: SalesPosStyles.fontCaption,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                //  SUGGESTIONS LIST
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    itemCount: suggestions.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 12, endIndent: 12),
                    itemBuilder: (context, i) {
                      final c = suggestions[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          ctrl.selectCustomer(c);
                          onSelected();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: SalesPosColors.brandGold
                                      .withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  c.initials,
                                  style: const TextStyle(
                                    color: SalesPosColors.brandGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: SalesPosStyles.fontLabel,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: const TextStyle(
                                        color: SalesPosColors.textDark,
                                        fontWeight: FontWeight.bold,
                                        fontSize: SalesPosStyles.fontBody,
                                      ),
                                    ),
                                    if (c.mobile.isNotEmpty)
                                      Text(
                                        c.mobile,
                                        style: const TextStyle(
                                          color: SalesPosColors.bodyTextMuted,
                                          fontSize: SalesPosStyles.fontCaption,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (c.city.isNotEmpty)
                                Text(
                                  c.city,
                                  style: const TextStyle(
                                    color: SalesPosColors.bodyTextMuted,
                                    fontSize: SalesPosStyles.fontCaption,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}

// ==========================================
// HOVER ANIMATED BUTTON COMPONENT
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
                        _isHovered
                            ? SalesPosColors.goldGradientStart
                            : SalesPosColors.brandGold,
                        _isHovered
                            ? SalesPosColors.brandGold
                            : SalesPosColors.goldHoverDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: widget.isPrimary
                  ? null
                  : (_isHovered
                      ? SalesPosColors.bodyPanelBg
                      : SalesPosColors.formInputBg),
              border: widget.isPrimary
                  ? null
                  : Border.all(
                      color: _isHovered
                          ? SalesPosColors.brandGold
                          : SalesPosColors.bodyBorder,
                      width: _isHovered ? 1.5 : 1.0,
                    ),
              boxShadow: [
                if (widget.isPrimary)
                  BoxShadow(
                    color: SalesPosColors.brandGold
                        .withValues(alpha: _isHovered ? 0.6 : 0.4),
                    blurRadius: _isHovered ? 16 : 10,
                    offset: const Offset(0, 4),
                  )
                else if (_isHovered)
                  BoxShadow(
                    color: SalesPosColors.brandGold.withValues(alpha: 0.15),
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
                          ? SalesPosColors.goldHoverDark
                          : SalesPosColors.textDark),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: widget.isPrimary
                        ? Colors.white
                        : (_isHovered
                            ? SalesPosColors.goldHoverDark
                            : SalesPosColors.textDark),
                    fontSize: SalesPosStyles.fontBody,
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

// ==========================================
//  POS customer history card
// Displayed after customer selection:
//    -  Total bills count
//    -  Outstanding due amount + bill numbers
//    -  Last visit date and elapsed time.
//    -  Customer type badge
// ==========================================
// ==========================================
//  UPGRADED v4: POS Customer History Card
//
// CHANGES:
//    -  Prominent due section with amount and bill count.
//    -  Scrollable list of outstanding bills.
//    -  Actions for clearing dues and starting a new bill.
//    -  Dialog for collecting payments against outstanding bills.
// ==========================================
class _PosCustomerHistoryCard extends StatelessWidget {
  final PosBillingController ctrl;
  const _PosCustomerHistoryCard({required this.ctrl});

  //  FORMATTER
  String _fmt(double v) {
    if (v >= 100000) return 'Rs ${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000) return 'Rs ${(v / 1000).toStringAsFixed(1)}K';
    return 'Rs ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    //  LOADING STATE
    if (ctrl.isLoadingHistory) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: SalesPosColors.customerCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: SalesPosColors.brandGold.withValues(alpha: 0.2)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: SalesPosColors.brandGold),
            ),
            SizedBox(width: 10),
            Text(
              'Loading customer history...',
              style: TextStyle(
                  color: SalesPosColors.bodyTextMuted,
                  fontSize: SalesPosStyles.fontCaption),
            ),
          ],
        ),
      );
    }

    final history = ctrl.customerHistory;

    //  NEW CUSTOMER  -  NO HISTORY
    if (history == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: SalesPosColors.customerCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SalesPosColors.bodyBorder),
        ),
        child: const Row(
          children: [
            Icon(Icons.person_add_alt_1_rounded,
                size: 16, color: SalesPosColors.bodyTextMuted),
            SizedBox(width: 8),
            Text(
              'New customer - no previous records found',
              style: TextStyle(
                  color: SalesPosColors.bodyTextMuted,
                  fontSize: SalesPosStyles.fontCaption),
            ),
          ],
        ),
      );
    }

    //  DATA
    final totalBills = history.bills.length;
    final outstanding = history.outstanding;
    final hasDue = outstanding > 0;
    final dueBills = history.dues;
    final dueBillCount = dueBills.length;

    // Last visit text
    String lastVisitText = 'First visit';
    if (history.bills.isNotEmpty) {
      final days =
          DateTime.now().difference(history.bills.first.billDate).inDays;
      if (days == 0) {
        lastVisitText = 'Visited today';
      } else if (days == 1) {
        lastVisitText = 'Visited yesterday';
      } else if (days < 30) {
        lastVisitText = '$days days ago';
      } else if (days < 365) {
        lastVisitText = '${(days / 30).floor()} months ago';
      } else {
        final y = (days / 365).floor();
        final m = ((days % 365) / 30).floor();
        lastVisitText = m > 0 ? '$y years $m months ago' : '$y years ago';
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasDue
            ? SalesPosColors.danger.withValues(alpha: 0.04)
            : SalesPosColors.customerCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasDue
              ? SalesPosColors.danger.withValues(alpha: 0.45)
              : SalesPosColors.brandGold.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //  HEADER
          Row(
            children: [
              const Icon(Icons.history_rounded,
                  size: 15, color: SalesPosColors.brandGold),
              const SizedBox(width: 6),
              const Text(
                'CUSTOMER HISTORY',
                style: TextStyle(
                  color: SalesPosColors.brandGold,
                  fontSize: SalesPosStyles.fontCaption,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: SalesPosColors.brandGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: SalesPosColors.brandGold.withValues(alpha: 0.4)),
                ),
                child: Text(
                  history.type.toUpperCase(),
                  style: const TextStyle(
                    color: SalesPosColors.brandGold,
                    fontSize: SalesPosStyles.fontCaption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          //  STATS: Total Bills + Last Visit
          Row(
            children: [
              _HistoryStat(
                icon: Icons.receipt_long_rounded,
                label: 'Total Bills',
                value: '$totalBills',
                valueColor: SalesPosColors.textDark,
              ),
              const SizedBox(width: 16),
              _HistoryStat(
                icon: Icons.access_time_rounded,
                label: 'Last Visit',
                value: lastVisitText,
                valueColor: SalesPosColors.textDark,
              ),
            ],
          ),

          //  DUE SECTION
          if (hasDue) ...[
            const SizedBox(height: 12),

            //  BIG DUE BANNER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: SalesPosColors.danger.withValues(alpha: 0.08),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                border: Border.all(
                    color: SalesPosColors.danger.withValues(alpha: 0.35),
                    width: 1.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Warning icon circle
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: SalesPosColors.danger.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        size: 20, color: SalesPosColors.danger),
                  ),
                  const SizedBox(width: 12),

                  // Label + bill count
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL OUTSTANDING',
                        style: TextStyle(
                          color: SalesPosColors.danger.withValues(alpha: 0.85),
                          fontSize: SalesPosStyles.fontCaption,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dueBillCount == 1
                            ? 'Pending against 1 bill'
                            : 'Pending against $dueBillCount bills',
                        style: const TextStyle(
                          color: SalesPosColors.bodyTextMuted,
                          fontSize: SalesPosStyles.fontCaption,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // BIG AMOUNT
                  Text(
                    _fmt(outstanding),
                    style: const TextStyle(
                      color: SalesPosColors.danger,
                      fontSize: SalesPosStyles.fontAmount,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),

            //  DUE BILLS BREAKDOWN
            if (dueBills.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: SalesPosColors.danger.withValues(alpha: 0.03),
                  border: Border(
                    left: BorderSide(
                        color: SalesPosColors.danger.withValues(alpha: 0.35),
                        width: 1.5),
                    right: BorderSide(
                        color: SalesPosColors.danger.withValues(alpha: 0.35),
                        width: 1.5),
                  ),
                ),
                child: Column(
                  children: [
                    ...dueBills.map((due) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          child: Row(
                            children: [
                              Icon(Icons.receipt_outlined,
                                  size: 13,
                                  color: SalesPosColors.danger
                                      .withValues(alpha: 0.55)),
                              const SizedBox(width: 6),
                              Text(
                                due.billNo,
                                style: const TextStyle(
                                  color: SalesPosColors.bodyTextMuted,
                                  fontSize: SalesPosStyles.fontCaption,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                due.formattedDate,
                                style: TextStyle(
                                  color: SalesPosColors.bodyTextMuted
                                      .withValues(alpha: 0.6),
                                  fontSize: SalesPosStyles.fontCaption,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _fmt(due.dueAmount),
                                style: const TextStyle(
                                  color: SalesPosColors.danger,
                                  fontSize: SalesPosStyles.fontLabel,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),

            //  ACTION BUTTONS
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SalesPosColors.danger.withValues(alpha: 0.05),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(10)),
                border: Border.all(
                    color: SalesPosColors.danger.withValues(alpha: 0.35),
                    width: 1.5),
              ),
              child: Row(
                children: [
                  //  CLEAR DUE
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => _ClearDueDialog(
                            customerName: history.name,
                            dueBills: dueBills,
                            totalOutstanding: outstanding,
                          ),
                        ),
                        icon: const Icon(Icons.payments_outlined, size: 16),
                        label: const Text(
                          'Clear Due',
                          style: TextStyle(
                              fontSize: SalesPosStyles.fontLabel,
                              fontWeight: FontWeight.w800),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SalesPosColors.danger,
                          side: BorderSide(
                              color:
                                  SalesPosColors.danger.withValues(alpha: 0.7),
                              width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  //  NEW BILL
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Continue billing from the active customer history state.
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.receipt_long,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                      'New invoice ready. Add items and collect outstanding dues when required.'),
                                ],
                              ),
                              backgroundColor: SalesPosColors.success,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline,
                            size: 16, color: Colors.white),
                        label: const Text(
                          'New Bill',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: SalesPosStyles.fontLabel,
                              fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SalesPosColors.success,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          //  ALL CLEAR
          if (!hasDue && totalBills > 0) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 14, color: SalesPosColors.success),
                SizedBox(width: 6),
                Text(
                  'No outstanding balance. Account is fully settled.',
                  style: TextStyle(
                      color: SalesPosColors.success,
                      fontSize: SalesPosStyles.fontCaption),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// Clear Due Dialog
// Customer ke unpaid bills ki list + total
// collect karne ka option
// ==========================================
class _ClearDueDialog extends StatefulWidget {
  final String customerName;
  final List<dynamic> dueBills; // CustomerDueModel list
  final double totalOutstanding;

  const _ClearDueDialog({
    required this.customerName,
    required this.dueBills,
    required this.totalOutstanding,
  });

  @override
  State<_ClearDueDialog> createState() => _ClearDueDialogState();
}

class _ClearDueDialogState extends State<_ClearDueDialog> {
  final TextEditingController _amountCtrl = TextEditingController();
  String _selectedMode = 'CASH';
  bool _payFull = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) {
    if (v >= 100000) return 'Rs ${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000) return 'Rs ${(v / 1000).toStringAsFixed(1)}K';
    return 'Rs ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: SalesPosColors.bodyPanelBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //  HEADER
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: SalesPosColors.danger.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.payments_outlined,
                      color: SalesPosColors.danger, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DUE COLLECTION',
                      style: TextStyle(
                        color: SalesPosColors.textDark,
                        fontSize: SalesPosStyles.fontInput,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    Text(
                      widget.customerName,
                      style: const TextStyle(
                          color: SalesPosColors.bodyTextMuted,
                          fontSize: SalesPosStyles.fontCaption),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close,
                      size: 20, color: SalesPosColors.bodyTextMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: SalesPosColors.bodyBorder),
            const SizedBox(height: 12),

            //  TOTAL DUE BOX
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: SalesPosColors.danger.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: SalesPosColors.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Outstanding (${widget.dueBills.length} bills)',
                    style: const TextStyle(
                        color: SalesPosColors.danger,
                        fontSize: SalesPosStyles.fontCaption,
                        fontWeight: FontWeight.w700),
                  ),
                  Text(
                    _fmt(widget.totalOutstanding),
                    style: const TextStyle(
                      color: SalesPosColors.danger,
                      fontSize: SalesPosStyles.fontSection,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            //  BILL BREAKDOWN
            const Text(
              'BILL-WISE BREAKDOWN',
              style: TextStyle(
                color: SalesPosColors.bodyTextMuted,
                fontSize: SalesPosStyles.fontCaption,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              decoration: BoxDecoration(
                color: SalesPosColors.bodyBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SalesPosColors.bodyBorder),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                itemCount: widget.dueBills.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: SalesPosColors.bodyBorder),
                itemBuilder: (_, i) {
                  final due = widget.dueBills[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_outlined,
                            size: 13, color: SalesPosColors.bodyTextMuted),
                        const SizedBox(width: 6),
                        Text(due.billNo,
                            style: const TextStyle(
                                fontSize: SalesPosStyles.fontCaption,
                                fontWeight: FontWeight.w700,
                                color: SalesPosColors.textDark)),
                        const SizedBox(width: 8),
                        Text(due.formattedDate,
                            style: const TextStyle(
                                fontSize: SalesPosStyles.fontCaption,
                                color: SalesPosColors.bodyTextMuted)),
                        const Spacer(),
                        Text(
                          _fmt(due.dueAmount),
                          style: const TextStyle(
                            color: SalesPosColors.danger,
                            fontSize: SalesPosStyles.fontLabel,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            //  PAYMENT MODE
            const Text(
              'PAYMENT MODE',
              style: TextStyle(
                color: SalesPosColors.bodyTextMuted,
                fontSize: SalesPosStyles.fontCaption,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: ['CASH', 'UPI', 'CARD'].map((mode) {
                final selected = _selectedMode == mode;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMode = mode),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? SalesPosColors.brandGold.withValues(alpha: 0.15)
                            : SalesPosColors.bodyBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? SalesPosColors.brandGold
                              : SalesPosColors.bodyBorder,
                          width: selected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Text(
                        mode,
                        style: TextStyle(
                          color: selected
                              ? SalesPosColors.goldHoverDark
                              : SalesPosColors.bodyTextMuted,
                          fontSize: SalesPosStyles.fontCaption,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            //  AMOUNT INPUT
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AMOUNT RECEIVED',
                        style: TextStyle(
                          color: SalesPosColors.bodyTextMuted,
                          fontSize: SalesPosStyles.fontCaption,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 44,
                        child: TextField(
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: const TextStyle(
                            color: SalesPosColors.textDark,
                            fontSize: SalesPosStyles.fontValue,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            prefixText: 'Rs  ',
                            hintStyle: const TextStyle(
                                color: SalesPosColors.bodyTextMuted,
                                fontSize: SalesPosStyles.fontBody),
                            filled: true,
                            fillColor: SalesPosColors.formInputBg,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 0),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: SalesPosColors.bodyBorder),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: SalesPosColors.brandGold, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Pay Full toggle
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _payFull = !_payFull;
                      if (_payFull) {
                        _amountCtrl.text =
                            widget.totalOutstanding.toStringAsFixed(2);
                      } else {
                        _amountCtrl.clear();
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _payFull
                          ? SalesPosColors.success.withValues(alpha: 0.12)
                          : SalesPosColors.bodyBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _payFull
                            ? SalesPosColors.success
                            : SalesPosColors.bodyBorder,
                        width: _payFull ? 1.5 : 1.0,
                      ),
                    ),
                    child: Text(
                      'Pay Full',
                      style: TextStyle(
                        color: _payFull
                            ? SalesPosColors.success
                            : SalesPosColors.bodyTextMuted,
                        fontSize: SalesPosStyles.fontCaption,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            //  CONFIRM BUTTON
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  final amount =
                      double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
                  if (amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter an amount.'),
                        backgroundColor: SalesPosColors.danger,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Rs ${amount.toStringAsFixed(0)} collected via $_selectedMode. Bill update is pending.'),
                      backgroundColor: SalesPosColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline,
                    color: Colors.white, size: 20),
                label: const Text(
                  'CONFIRM COLLECTION',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: SalesPosStyles.fontBody,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SalesPosColors.success,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// HELPER: Single stat tile
// ==========================================
class _HistoryStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _HistoryStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: SalesPosColors.bodyTextMuted),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: SalesPosColors.bodyTextMuted,
                    fontSize: SalesPosStyles.fontCaption,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: SalesPosStyles.fontCaption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
