// ==========================================
// FILE: pos_customer_details_panel.dart
// TYPE: UI Component
// DESCRIPTION: Customer entry, customer lookup, suggestion overlay, and customer history panel for POS billing.
// ==========================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import '../../../logic/sales_orders/sales_pos/pos_billing_controller.dart';
import 'customer_history/pos_customer_history_card.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

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

  Future<void> _quickAddCustomer() async {
    final ok = await widget.ctrl.quickCreateCustomer();
    if (!mounted) return;
    if (ok) {
      _removeSuggestionOverlay();
      AppFeedback.show(
        context,
        type: AppFeedbackType.success,
        message: 'Customer added for this sale.',
      );
      return;
    }

    AppFeedback.show(
      context,
      type: AppFeedbackType.error,
      message: 'Enter customer name or a valid 10-digit mobile number.',
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
                      ListenableBuilder(
                        listenable: widget.ctrl,
                        builder: (context, _) {
                          if (_noCustomerFound) {
                            return _HeaderQuickAddButton(
                              onTap: _quickAddCustomer,
                            );
                          }
                          return const _PosSessionBadge();
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
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r"[a-zA-Z ]"),
                              ),
                            ],
                            textCapitalization: TextCapitalization.words,
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
                            title: "Quick Add",
                            icon: SalesPosIcons.newCustomerAdd,
                            isPrimary: true,
                            onTap: _quickAddCustomer,
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
              PosCustomerHistoryCard(ctrl: widget.ctrl),
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
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization? textCapitalization,
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
            inputFormatters: inputFormatters ??
                (isNumber
                    ? [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ]
                    : null),
            textCapitalization: textCapitalization ??
                (isCaps
                    ? TextCapitalization.characters
                    : TextCapitalization.none),
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

class _PosSessionBadge extends StatelessWidget {
  const _PosSessionBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: SalesPosColors.brandGold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SalesPosColors.brandGold.withValues(alpha: 0.4),
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
}

class _HeaderQuickAddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _HeaderQuickAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: SalesPosColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: SalesPosColors.success.withValues(alpha: 0.45),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_add_alt_1_rounded,
              size: 15,
              color: SalesPosColors.success,
            ),
            SizedBox(width: 6),
            Text(
              "Quick Add Customer",
              style: TextStyle(
                fontSize: SalesPosStyles.fontCaption,
                fontWeight: FontWeight.w900,
                color: SalesPosColors.success,
              ),
            ),
          ],
        ),
      ),
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
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              border: Border.all(
                color: notFound && suggestions.isEmpty
                    ? SalesPosColors.brandGold.withValues(alpha: 0.35)
                    : SalesPosColors.brandGold.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: notFound && suggestions.isEmpty
                //  CUSTOMER NOT FOUND STATE
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: SalesPosColors.brandGold
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.person_search_rounded,
                                color: SalesPosColors.goldHoverDark,
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
                                    "No Customer Match",
                                    style: TextStyle(
                                      color: SalesPosColors.textDark,
                                      fontWeight: FontWeight.w800,
                                      fontSize: SalesPosStyles.fontBody,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "Use Quick Add to save this buyer instantly.",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: SalesPosColors.bodyTextMuted,
                                      fontSize: SalesPosStyles.fontCaption,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: SalesPosColors.formInputBg
                                .withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: SalesPosColors.bodyBorder
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                          child: Text(
                            ctrl.mobileCtrl.text.trim().isNotEmpty
                                ? "Mobile: ${ctrl.mobileCtrl.text.trim()}"
                                : "Name: ${ctrl.nameCtrl.text.trim()}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: SalesPosColors.textDark,
                              fontSize: SalesPosStyles.fontCaption,
                              fontWeight: FontWeight.w700,
                            ),
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
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, i) {
                      final c = suggestions[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            ctrl.selectCustomer(c);
                            onSelected();
                          },
                          child: Ink(
                            decoration: BoxDecoration(
                              color: SalesPosColors.formInputBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: SalesPosColors.bodyBorder
                                    .withValues(alpha: 0.85),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 9),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: SalesPosColors.brandGold
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(
                                        color: SalesPosColors.brandGold
                                            .withValues(alpha: 0.18),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      c.initials,
                                      style: const TextStyle(
                                        color: SalesPosColors.goldHoverDark,
                                        fontWeight: FontWeight.w800,
                                        fontSize: SalesPosStyles.fontCaption,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: SalesPosColors.textDark,
                                            fontWeight: FontWeight.w800,
                                            fontSize: SalesPosStyles.fontBody,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            if (c.mobile.isNotEmpty) ...[
                                              const Icon(
                                                Icons.phone_android_rounded,
                                                size: 12,
                                                color: SalesPosColors
                                                    .bodyTextMuted,
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  c.mobile,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: SalesPosColors
                                                        .bodyTextMuted,
                                                    fontSize: SalesPosStyles
                                                        .fontCaption,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            if (c.mobile.isNotEmpty &&
                                                c.city.isNotEmpty)
                                              Container(
                                                width: 4,
                                                height: 4,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 7),
                                                decoration: BoxDecoration(
                                                  color: SalesPosColors
                                                      .bodyTextMuted
                                                      .withValues(alpha: 0.45),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            if (c.city.isNotEmpty)
                                              Flexible(
                                                child: Text(
                                                  c.city,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: SalesPosColors
                                                        .bodyTextMuted,
                                                    fontSize: SalesPosStyles
                                                        .fontCaption,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: SalesPosColors.brandGold
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: SalesPosColors.goldHoverDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
