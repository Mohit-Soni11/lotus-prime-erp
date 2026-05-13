// =============================================================================
// FILE        : silver_supplier_panel.dart
// MODULE      : Stock & Inventory (Silver)
// LAYER       : UI
// DESCRIPTION : Supplier profile lookup + session binding panel for Silver batch.
//               Full silver-theme parity with AddGoldStockSupplierPanel.
//               All colors, icons, styles and strings sourced from
//               SilverStockColors / SilverStockIcons / SilverStockStyles /
//               SilverStockStrings — zero hardcoded values.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lotus_erp/logic/stock/add_stock_silver/silver_stock_controller.dart';
import 'package:lotus_erp/models/stock/supplier_model/supplier_model.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_silver/silver_stock_theme.dart';
import 'package:lotus_erp/ui/stock/supplier/add_supplier/add_supplier_screen.dart';

class AddSilverStockSupplierPanel extends StatefulWidget {
  final SilverStockController ctrl;

  const AddSilverStockSupplierPanel({super.key, required this.ctrl});

  @override
  State<AddSilverStockSupplierPanel> createState() =>
      _AddSilverStockSupplierPanelState();
}

class _AddSilverStockSupplierPanelState
    extends State<AddSilverStockSupplierPanel>
    with SingleTickerProviderStateMixin {
  // ── Animation ────────────────────────────────────────────────
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // ── Overlay links for dropdown positioning ───────────────────
  final LayerLink _mobileSuggestionLink = LayerLink();
  final LayerLink _nameSuggestionLink = LayerLink();

  OverlayEntry? _suggestionOverlay;
  bool _isMobileActive = false;

  // ── Lifecycle ────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 40), () {
      if (mounted) _animCtrl.forward();
    });

    widget.ctrl.supplierNameCtrl.addListener(_onNameChanged);
    widget.ctrl.supplierMobileCtrl.addListener(_onMobileChanged);
    widget.ctrl.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _removeSuggestionOverlay();
    widget.ctrl.supplierNameCtrl.removeListener(_onNameChanged);
    widget.ctrl.supplierMobileCtrl.removeListener(_onMobileChanged);
    widget.ctrl.removeListener(_onControllerChanged);
    super.dispose();
  }

  // ── Suggestion computation ───────────────────────────────────
  List<SupplierListItemModel> get _activeSuggestions {
    final query = _isMobileActive
        ? widget.ctrl.supplierMobileCtrl.text.trim().toLowerCase()
        : widget.ctrl.supplierNameCtrl.text.trim().toLowerCase();

    if (query.isEmpty) return const [];

    return widget.ctrl.suppliers
        .where(
          (s) =>
              s.businessName.toLowerCase().contains(query) ||
              s.mobile.contains(query) ||
              (s.contactPersonName ?? '').toLowerCase().contains(query),
        )
        .take(8)
        .toList(growable: false);
  }

  bool get _notFound {
    final text = _isMobileActive
        ? widget.ctrl.supplierMobileCtrl.text.trim()
        : widget.ctrl.supplierNameCtrl.text.trim();
    return text.isNotEmpty && _activeSuggestions.isEmpty;
  }

  // ── Listeners ────────────────────────────────────────────────
  void _onNameChanged() {
    if (widget.ctrl.isApplyingSupplierProfile) return;
    _isMobileActive = false;
    final linked = widget.ctrl.linkedSupplier;
    final text = widget.ctrl.supplierNameCtrl.text;
    if (linked != null && linked.businessName == text) return;
    widget.ctrl.setSessionSupplierText(text);
  }

  void _onMobileChanged() {
    if (widget.ctrl.isApplyingSupplierProfile) return;
    _isMobileActive = true;
    final linked = widget.ctrl.linkedSupplier;
    final text = widget.ctrl.supplierMobileCtrl.text;
    if (linked != null && linked.mobile == text) return;
    widget.ctrl.updateSupplierMobileText(text);
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
    if (_activeSuggestions.isEmpty) {
      _removeSuggestionOverlay();
    } else {
      _showSuggestionOverlay();
    }
  }

  // ── Overlay management ───────────────────────────────────────
  void _removeSuggestionOverlay() {
    _suggestionOverlay?.remove();
    _suggestionOverlay = null;
  }

  void _showSuggestionOverlay() {
    if (!mounted) return;
    _removeSuggestionOverlay();

    final activeLink =
        _isMobileActive ? _mobileSuggestionLink : _nameSuggestionLink;

    _suggestionOverlay = OverlayEntry(
      builder: (context) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final width = screenWidth > 430
            ? 360.0
            : (screenWidth - 28).clamp(240.0, 360.0).toDouble();

        return Positioned(
          top: 0,
          left: 0,
          width: width,
          child: CompositedTransformFollower(
            link: activeLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 54),
            child: Material(
              color: Colors.transparent,
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: _SilverSupplierLookupDropdown(
                suppliers: _activeSuggestions,
                onSelected: (supplier) {
                  FocusScope.of(context).unfocus();
                  widget.ctrl.setSessionSupplier(supplier);
                  _removeSuggestionOverlay();
                },
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_suggestionOverlay!);
  }

  // ── Navigation ───────────────────────────────────────────────
  Future<void> _openCreateSupplier() async {
    _removeSuggestionOverlay();
    FocusScope.of(context).unfocus();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddSupplierScreen(
          onBack: () => Navigator.pop(context),
          onSaved: () => Navigator.pop(context),
        ),
      ),
    );

    if (!mounted) return;
    await widget.ctrl.reloadSuppliers();
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SilverStockColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: SilverStockColors.brandSilver.withOpacity(0.10),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
              const BoxShadow(
                color: SilverStockColors.shadowMedium,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: SilverStockColors.brandSilver.withOpacity(0.22),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),

              // Silver gradient divider
              Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SilverStockColors.brandSilver.withOpacity(0.48),
                      SilverStockColors.brandSilver.withOpacity(0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Inputs (responsive)
              _buildInputsRow(),

              // SAME FOR ALL toggle
              const SizedBox(height: 16),
              _buildSameForAllToggle(),

              // Status card
              if (widget.ctrl.hasLinkedSupplier || _notFound) ...[
                const SizedBox(height: 16),
                _buildStatusCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader() {
    final showCreateCta = _notFound;

    final badge = showCreateCta
        ? _SilverPrimaryActionChip(
            title: SilverStockStrings.createSupplier,
            icon: SilverStockIcons.createSupplierIcon,
            onTap: _openCreateSupplier,
          )
        : _SilverStatusBadge(
            label: widget.ctrl.hasLinkedSupplier
                ? SilverStockStrings.ledgerLinked
                : SilverStockStrings.lookupReady,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackHeader = constraints.maxWidth < 760;

        final titleBlock = Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                SilverStockStrings.supplierProfileTitle,
                style: SilverStockStyles.pageTitle.copyWith(
                  fontSize: 18,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                SilverStockStrings.supplierProfileDesc,
                style: SilverStockStyles.caption.copyWith(
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        );

        final leadingRow = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Silver gradient icon box
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    SilverStockColors.gradientStart,
                    SilverStockColors.brandSilver,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: SilverStockColors.brandSilver.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                SilverStockIcons.supplierProfile,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            titleBlock,
          ],
        );

        if (stackHeader) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [leadingRow, const SizedBox(height: 12), badge],
          );
        }

        return Row(
          children: [
            Expanded(child: leadingRow),
            const SizedBox(width: 12),
            badge,
          ],
        );
      },
    );
  }

  // ── Inputs row (responsive) ──────────────────────────────────
  Widget _buildInputsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final singleColumn = constraints.maxWidth < 760;

        if (singleColumn) {
          return Column(
            children: [
              CompositedTransformTarget(
                link: _mobileSuggestionLink,
                child: _buildInput(
                  label: SilverStockStrings.fieldMobileNumber,
                  hint: SilverStockStrings.hintSearchByPhone,
                  controller: widget.ctrl.supplierMobileCtrl,
                  isNumber: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  icon: SilverStockIcons.phone,
                ),
              ),
              const SizedBox(height: 12),
              CompositedTransformTarget(
                link: _nameSuggestionLink,
                child: _buildInput(
                  label: SilverStockStrings.fieldSupplierName,
                  hint: SilverStockStrings.hintSearchByName,
                  controller: widget.ctrl.supplierNameCtrl,
                  icon: SilverStockIcons.businessName,
                ),
              ),
              const SizedBox(height: 12),
              _buildInput(
                label: SilverStockStrings.fieldAddress,
                hint: SilverStockStrings.hintAutoFilled,
                controller: widget.ctrl.supplierRegionCtrl,
                readOnly: true,
                icon: SilverStockIcons.locationPin,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 190,
              child: CompositedTransformTarget(
                link: _mobileSuggestionLink,
                child: _buildInput(
                  label: SilverStockStrings.fieldMobileNumber,
                  hint: SilverStockStrings.hintSearchByPhone,
                  controller: widget.ctrl.supplierMobileCtrl,
                  isNumber: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  icon: SilverStockIcons.phone,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CompositedTransformTarget(
                link: _nameSuggestionLink,
                child: _buildInput(
                  label: SilverStockStrings.fieldSupplierName,
                  hint: SilverStockStrings.hintSearchByName,
                  controller: widget.ctrl.supplierNameCtrl,
                  icon: SilverStockIcons.businessName,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInput(
                label: SilverStockStrings.fieldAddress,
                hint: SilverStockStrings.hintAutoFilled,
                controller: widget.ctrl.supplierRegionCtrl,
                readOnly: true,
                icon: SilverStockIcons.locationPin,
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Same For All toggle ──────────────────────────────────────
  Widget _buildSameForAllToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SilverStockColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SilverStockColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(
            SilverStockIcons.storefront,
            size: 18,
            color: SilverStockColors.brandSilver,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              SilverStockStrings.supplierSession,
              style: SilverStockStyles.fieldLabel.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: SilverStockColors.textBody,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            SilverStockStrings.sameForAllLabel,
            style: SilverStockStyles.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: SilverStockColors.textMuted,
            ),
          ),
          const SizedBox(width: 4),
          Switch.adaptive(
            value: widget.ctrl.sameForAll,
            onChanged: widget.ctrl.setSameForAll,
            activeColor: SilverStockColors.brandSilver,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  // ── Status card ──────────────────────────────────────────────
  Widget _buildStatusCard() {
    // Not found state
    if (_notFound) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SilverStockColors.warningBg,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: SilverStockColors.warning.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const Icon(
              SilverStockIcons.warning,
              color: SilverStockColors.warning,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                SilverStockStrings.notFoundMessage,
                style: SilverStockStyles.caption.copyWith(
                  color: SilverStockColors.textDark,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Linked state
    final linked = widget.ctrl.linkedSupplier;
    final detailParts = [
      widget.ctrl.supplierMobileCtrl.text.trim(),
      widget.ctrl.supplierRegionCtrl.text.trim(),
      if (widget.ctrl.supplierGstCtrl.text.trim().isNotEmpty)
        '${SilverStockStrings.gstPrefix}${widget.ctrl.supplierGstCtrl.text.trim()}',
    ].where((v) => v.isNotEmpty).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SilverStockColors.successBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SilverStockColors.success.withOpacity(0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: SilverStockColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              SilverStockIcons.huidVerified,
              color: SilverStockColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.ctrl.supplierDisplayName.trim().isEmpty
                      ? SilverStockStrings.linkedSupplierFallback
                      : widget.ctrl.supplierDisplayName,
                  style: SilverStockStyles.sectionTitle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  SilverStockStrings.linkedBatchMessage,
                  style: SilverStockStyles.caption.copyWith(
                    color: SilverStockColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (detailParts.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    detailParts.join(' | '),
                    style: SilverStockStyles.caption.copyWith(
                      color: SilverStockColors.textBody,
                      fontSize: 12,
                    ),
                  ),
                ],
                if ((linked?.contactPersonName ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${SilverStockStrings.contactPrefix}${linked!.contactPersonName}',
                    style: SilverStockStyles.caption.copyWith(
                      color: SilverStockColors.textBody,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Text input builder ───────────────────────────────────────
  Widget _buildInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isNumber = false,
    bool readOnly = false,
    List<TextInputFormatter>? inputFormatters,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row with silver dot
        Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: SilverStockColors.brandSilver,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: SilverStockStyles.fieldLabel.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: SilverStockColors.textDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 46,
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            inputFormatters: inputFormatters,
            style: SilverStockStyles.fieldInput.copyWith(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: SilverStockStyles.fieldHint.copyWith(
                color: SilverStockColors.textHint.withOpacity(0.7),
                fontSize: 13,
              ),
              prefixIcon: icon != null
                  ? Icon(
                      icon,
                      size: 18,
                      color: SilverStockColors.textMuted,
                    )
                  : null,
              filled: true,
              fillColor: readOnly
                  ? SilverStockColors.inputBgLocked
                  : SilverStockColors.inputBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderSide:
                    const BorderSide(color: SilverStockColors.cardBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide:
                    const BorderSide(color: SilverStockColors.cardBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: SilverStockColors.brandSilver,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// PRIVATE WIDGET — Lookup dropdown (silver-themed)
// =============================================================================
class _SilverSupplierLookupDropdown extends StatelessWidget {
  final List<SupplierListItemModel> suppliers;
  final ValueChanged<SupplierListItemModel> onSelected;

  const _SilverSupplierLookupDropdown({
    required this.suppliers,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: SilverStockColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SilverStockColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: SilverStockColors.shadowMedium,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        shrinkWrap: true,
        itemCount: suppliers.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: SilverStockColors.cardBorder),
        itemBuilder: (context, index) {
          final supplier = suppliers[index];
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              backgroundColor: SilverStockColors.brandSilver.withOpacity(0.12),
              child: Text(
                supplier.avatarInitial,
                style: const TextStyle(
                  color: SilverStockColors.silverAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            title: Text(
              supplier.businessName,
              style: SilverStockStyles.sectionTitle.copyWith(
                color: SilverStockColors.textDark,
              ),
            ),
            subtitle: Text(
              [supplier.mobile, supplier.supplierType.label]
                  .where((v) => v.isNotEmpty)
                  .join(' | '),
              style: SilverStockStyles.caption.copyWith(fontSize: 12),
            ),
            onTap: () => onSelected(supplier),
          );
        },
      ),
    );
  }
}

// =============================================================================
// PRIVATE WIDGET — Primary action chip (Create Supplier CTA)
// =============================================================================
class _SilverPrimaryActionChip extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _SilverPrimaryActionChip({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              SilverStockColors.gradientStart,
              SilverStockColors.brandSilver,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: SilverStockColors.brandSilver.withOpacity(0.28),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              title,
              style: SilverStockStyles.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PRIVATE WIDGET — Status badge (Ledger Linked / Lookup Ready)
// =============================================================================
class _SilverStatusBadge extends StatelessWidget {
  final String label;

  const _SilverStatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: SilverStockColors.brandSilver.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SilverStockColors.brandSilver.withOpacity(0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: SilverStockColors.brandSilver,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: SilverStockStyles.caption.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: SilverStockColors.silverAccent,
            ),
          ),
        ],
      ),
    );
  }
}
