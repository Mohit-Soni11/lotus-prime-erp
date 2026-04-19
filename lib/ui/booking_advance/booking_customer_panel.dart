// =============================================================================
// FILE        : booking_customer_panel.dart
// MODULE      : Sales → Booking & Advance
// DESCRIPTION : EXACT same as PosCustomerDetailsPanel.
//               Mobile, Name, City, PAN, GST fields + Search/Clear buttons.
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/booking_advance/booking_advance_theme.dart';
import '../../../logic/booking_advance/booking_advance_controller.dart';

class BookingCustomerPanel extends StatefulWidget {
  final BookingAdvanceController ctrl;
  const BookingCustomerPanel({super.key, required this.ctrl});

  @override
  State<BookingCustomerPanel> createState() => _BookingCustomerPanelState();
}

class _BookingCustomerPanelState extends State<BookingCustomerPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 50), () { if (mounted) _animCtrl.forward(); });

    widget.ctrl.addListener(() {
      if (mounted) setState(() { _showDropdown = widget.ctrl.customerResults.isNotEmpty; });
    });
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Column(children: [
          _buildPanel(),
          if (_showDropdown) _buildDropdown(),
        ]),
      ),
    );
  }

  Widget _buildPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BookingAdvanceStyles.goldBorderCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── HEADER ──
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [BookingAdvanceColors.goldGradientStart, BookingAdvanceColors.brandGold],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: BookingAdvanceColors.brandGold.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: const Icon(BookingAdvanceIcons.profile, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(BookingAdvanceStrings.sectionCustomer, style: BookingAdvanceStyles.highVisHeader),
                const SizedBox(height: 2),
                Text(BookingAdvanceStrings.customerSubtitle, style: BookingAdvanceStyles.subTitleMuted),
              ]),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: BookingAdvanceColors.brandGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: BookingAdvanceColors.brandGold.withOpacity(0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: BookingAdvanceColors.brandGold, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(BookingAdvanceStrings.bookingSession,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BookingAdvanceColors.goldHoverDark)),
                ]),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── GOLD DIVIDER ──
          Container(height: 1.5,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [
              BookingAdvanceColors.brandGold.withOpacity(0.5),
              BookingAdvanceColors.brandGold.withOpacity(0.1),
              Colors.transparent,
            ]))),

          const SizedBox(height: 16),

          // ── FIELDS ROW ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(flex: 2, child: _field(BookingAdvanceStrings.lblMobile, BookingAdvanceStrings.hintMobile,
                widget.ctrl.mobileCtrl, isNumber: true, icon: BookingAdvanceIcons.mobilePhone,
                onChanged: widget.ctrl.searchCustomer)),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: _field(BookingAdvanceStrings.lblName, BookingAdvanceStrings.hintName,
                widget.ctrl.nameCtrl, icon: BookingAdvanceIcons.customerName)),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _field(BookingAdvanceStrings.lblCity, BookingAdvanceStrings.hintCity,
                widget.ctrl.cityCtrl, icon: BookingAdvanceIcons.cityLocation)),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _field(BookingAdvanceStrings.lblPan, BookingAdvanceStrings.hintPan,
                widget.ctrl.panCtrl, isCaps: true, icon: BookingAdvanceIcons.panCard)),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _field(BookingAdvanceStrings.lblGst, BookingAdvanceStrings.hintGst,
                widget.ctrl.gstCtrl, isCaps: true, icon: BookingAdvanceIcons.gstNumber)),
              const SizedBox(width: 16),
              // Buttons
              Column(mainAxisSize: MainAxisSize.min, children: [
                _HoverBtn(title: BookingAdvanceStrings.btnSearch, icon: BookingAdvanceIcons.searchItem, isPrimary: false,
                  onTap: () => widget.ctrl.searchCustomer(widget.ctrl.mobileCtrl.text)),
                const SizedBox(height: 8),
                _HoverBtn(title: BookingAdvanceStrings.btnClear, icon: BookingAdvanceIcons.clearAll, isPrimary: false,
                  onTap: () {
                    widget.ctrl.mobileCtrl.clear(); widget.ctrl.nameCtrl.clear();
                    widget.ctrl.cityCtrl.clear(); widget.ctrl.panCtrl.clear();
                    widget.ctrl.gstCtrl.clear(); widget.ctrl.selectedCustomerId = null;
                  }),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return ListenableBuilder(
      listenable: widget.ctrl,
      builder: (_, __) {
        if (widget.ctrl.customerResults.isEmpty) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: BookingAdvanceColors.bodyPanelBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BookingAdvanceColors.brandGold.withOpacity(0.4), width: 1.5),
            boxShadow: [const BoxShadow(color: BookingAdvanceColors.shadowDark, blurRadius: 16, offset: Offset(0, 6))],
          ),
          child: Column(
            children: widget.ctrl.customerResults.map((c) => _SearchTile(
              customer: c,
              onTap: () {
                widget.ctrl.selectCustomerFromSearch(c);
                setState(() => _showDropdown = false);
              },
            )).toList(),
          ),
        );
      },
    );
  }

  Widget _field(String label, String hint, TextEditingController ctrl,
      {bool isNumber = false, bool isCaps = false, IconData? icon, ValueChanged<String>? onChanged}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 5, height: 5, decoration: const BoxDecoration(color: BookingAdvanceColors.brandGold, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: BookingAdvanceColors.textDark, fontSize: 13, fontWeight: FontWeight.bold))),
      ]),
      const SizedBox(height: 8),
      SizedBox(
        height: 44,
        child: TextField(
          controller: ctrl, onChanged: onChanged,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          textCapitalization: isCaps ? TextCapitalization.characters : TextCapitalization.none,
          style: BookingAdvanceStyles.inputText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: BookingAdvanceColors.bodyTextMuted.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500),
            prefixIcon: icon != null ? Icon(icon, size: 18, color: BookingAdvanceColors.bodyTextMuted) : null,
            filled: true, fillColor: BookingAdvanceColors.formInputBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            border: OutlineInputBorder(borderSide: const BorderSide(color: BookingAdvanceColors.bodyBorder), borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: BookingAdvanceColors.bodyBorder), borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: BookingAdvanceColors.brandGold, width: 2), borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _SearchTile extends StatefulWidget {
  final Map<String, dynamic> customer;
  final VoidCallback onTap;
  const _SearchTile({required this.customer, required this.onTap});
  @override State<_SearchTile> createState() => _SearchTileState();
}
class _SearchTileState extends State<_SearchTile> {
  bool _h = false;
  @override Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit:  (_) => setState(() => _h = false),
      child: GestureDetector(onTap: widget.onTap,
        child: AnimatedContainer(duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: _h ? const Color(0xFFFAF6EC) : Colors.transparent,
          child: Row(children: [
            const Icon(BookingAdvanceIcons.profile, color: BookingAdvanceColors.brandGold, size: 18),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.customer['name'] ?? '', style: const TextStyle(color: BookingAdvanceColors.textDark, fontSize: 14, fontWeight: FontWeight.w800)),
              Text('${widget.customer['mobile'] ?? ''}${(widget.customer['city'] ?? '').isNotEmpty ? "  •  ${widget.customer['city']}" : ""}',
                style: const TextStyle(color: BookingAdvanceColors.bodyTextMuted, fontSize: 12)),
            ])),
          ])),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _HoverBtn extends StatefulWidget {
  final String title; final IconData icon; final bool isPrimary; final VoidCallback onTap;
  const _HoverBtn({required this.title, required this.icon, required this.isPrimary, required this.onTap});
  @override State<_HoverBtn> createState() => _HoverBtnState();
}
class _HoverBtnState extends State<_HoverBtn> {
  bool _h = false;
  @override Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit:  (_) => setState(() => _h = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: widget.onTap,
        child: AnimatedScale(scale: _h ? 1.04 : 1.0, duration: const Duration(milliseconds: 200), curve: Curves.easeOutBack,
          child: AnimatedContainer(duration: const Duration(milliseconds: 250), height: 42, width: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: widget.isPrimary ? LinearGradient(colors: [
                _h ? BookingAdvanceColors.goldGradientStart : BookingAdvanceColors.brandGold,
                _h ? BookingAdvanceColors.brandGold : BookingAdvanceColors.goldHoverDark,
              ], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
              color: widget.isPrimary ? null : (_h ? BookingAdvanceColors.bodyPanelBg : BookingAdvanceColors.formInputBg),
              border: widget.isPrimary ? null : Border.all(color: _h ? BookingAdvanceColors.brandGold : BookingAdvanceColors.bodyBorder, width: _h ? 1.5 : 1.0),
              boxShadow: [
                if (widget.isPrimary) BoxShadow(color: BookingAdvanceColors.brandGold.withOpacity(_h ? 0.6 : 0.4), blurRadius: _h ? 16 : 10, offset: const Offset(0, 4))
                else if (_h) BoxShadow(color: BookingAdvanceColors.brandGold.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(widget.icon, size: 16,
                color: widget.isPrimary ? Colors.white : (_h ? BookingAdvanceColors.goldHoverDark : BookingAdvanceColors.textDark)),
              const SizedBox(width: 8),
              Text(widget.title, style: TextStyle(
                color: widget.isPrimary ? Colors.white : (_h ? BookingAdvanceColors.goldHoverDark : BookingAdvanceColors.textDark),
                fontSize: 14, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ),
    );
  }
}