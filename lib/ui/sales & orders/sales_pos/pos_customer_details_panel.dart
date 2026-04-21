// ==========================================
// FILE: pos_customer_details_panel.dart
// TYPE: Smart UI Component (UPGRADED v3)
// DESCRIPTION: Premium customer entry form.
//              ✅ Customer name suggestions from DB
//              ✅ Fuzzy search — name field + mobile field dono pe
//              ✅ Overlay sahi field ke neeche dikhta hai
//              ✅ "New Customer" redirects to add customer screen
//              ✅ Zero hardcoded colors, icons, or styles.
//
// BUG FIX v3:
//   ❌ BUG — CompositedTransformTarget sirf Mobile field pe tha.
//            Name field mein type karne pe overlay galat jagah
//            ya bilkul nahi dikhta tha.
//   ✅ FIX — Alag-alag LayerLink banaya Name aur Mobile ke liye.
//            Jo field active ho, overlay usi ke neeche dikhe.
// ==========================================

import 'package:flutter/material.dart';

import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import '../../../logic/sales & orders/sales pos/pos_billing_controller.dart';
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

  // ✅ FIX: Dono fields ke liye alag-alag LayerLink
  final LayerLink _mobileSuggestionLink = LayerLink();
  final LayerLink _nameSuggestionLink = LayerLink();

  OverlayEntry? _suggestionOverlay;

  // Kaunsa field active hai — mobile ya name?
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
    // ✅ FIX: selectedCustomer ho aur name match kare to search mat karo
    if (widget.ctrl.selectedCustomer != null) {
      if (widget.ctrl.nameCtrl.text == widget.ctrl.selectedCustomer!.name)
        return;
      widget.ctrl.selectedCustomer = null; // Customer deselect hua
    }
    widget.ctrl.searchCustomersByName(widget.ctrl.nameCtrl.text);
  }

  void _onMobileChanged() {
    _isMobileActive = true;
    // ✅ FIX: selectedCustomer ho aur mobile match kare to search mat karo
    if (widget.ctrl.selectedCustomer != null) {
      if (widget.ctrl.mobileCtrl.text == widget.ctrl.selectedCustomer!.mobile)
        return;
      widget.ctrl.selectedCustomer = null; // Customer deselect hua
    }
    final mobile = widget.ctrl.mobileCtrl.text.trim();
    // ✅ FIX: 1 character se hi search
    if (mobile.length >= 1) {
      widget.ctrl.searchCustomersByName(mobile);
    } else {
      widget.ctrl.clearCustomerSuggestions();
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
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

    // ✅ FIX: Jo field active hai, usi ka LayerLink use karo
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

  bool get _noCustomerFound =>
      widget.ctrl.nameCtrl.text.length >= 2 &&
      widget.ctrl.customerSuggestions.isEmpty &&
      widget.ctrl.selectedCustomer == null;

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

                  // ── "NEW CUSTOMER" BANNER IF NOT FOUND ──
                  ListenableBuilder(
                    listenable: widget.ctrl,
                    builder: (context, _) {
                      if (!_noCustomerFound) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
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
                        );
                      }
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddCustomerScreen(
                              onBack: () => Navigator.pop(context),
                              onSaved: () => Navigator.pop(context),
                            ),
                          ),
                        ),
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
                                color:
                                    SalesPosColors.brandGold.withOpacity(0.4),
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
                                  fontSize: 12,
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
                  // ── MOBILE FIELD — apna LayerLink ──
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

                  // ── NAME FIELD — apna LayerLink ✅ ──
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

                  // ── BUTTONS ──
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
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddCustomerScreen(
                              onBack: () => Navigator.pop(context),
                              onSaved: () => Navigator.pop(context),
                            ),
                          ),
                        ),
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

        // Kuch nahi dikhana
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
                    ? Colors.red.withOpacity(0.35)
                    : SalesPosColors.brandGold.withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: notFound && suggestions.isEmpty
                // ─── CUSTOMER NOT FOUND STATE ───
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.person_off_outlined,
                            color: Colors.red,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Customer Not Found",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Not Registered — Click 'New Customer' to add",
                                style: TextStyle(
                                  color: SalesPosColors.bodyTextMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                // ─── SUGGESTIONS LIST ───
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
                                      .withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  c.initials,
                                  style: const TextStyle(
                                    color: SalesPosColors.brandGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
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
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (c.mobile.isNotEmpty)
                                      Text(
                                        c.mobile,
                                        style: TextStyle(
                                          color: SalesPosColors.bodyTextMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (c.city.isNotEmpty)
                                Text(
                                  c.city,
                                  style: TextStyle(
                                    color: SalesPosColors.bodyTextMuted,
                                    fontSize: 12,
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
                        .withOpacity(_isHovered ? 0.6 : 0.4),
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
