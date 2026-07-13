import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lotus_erp/features/stock/gold/application/gold_stock_controller.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_model.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_gold/gold_stock_theme.dart';
import 'package:lotus_erp/features/stock/shared/presentation/supplier/add_supplier/add_supplier_screen.dart';

class AddGoldStockSupplierPanel extends StatefulWidget {
  final GoldStockController ctrl;

  const AddGoldStockSupplierPanel({super.key, required this.ctrl});

  @override
  State<AddGoldStockSupplierPanel> createState() =>
      _AddGoldStockSupplierPanelState();
}

class _AddGoldStockSupplierPanelState extends State<AddGoldStockSupplierPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  final LayerLink _mobileSuggestionLink = LayerLink();
  final LayerLink _nameSuggestionLink = LayerLink();

  OverlayEntry? _suggestionOverlay;
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
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 40), () {
      if (mounted) {
        _animCtrl.forward();
      }
    });

    widget.ctrl.supplierNameCtrl.addListener(_onNameChanged);
    widget.ctrl.supplierMobileCtrl.addListener(_onMobileChanged);
    widget.ctrl.addListener(_onControllerChanged);

    if (!widget.ctrl.sameForAll) {
      widget.ctrl.setSameForAll(true);
    }
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

  List<SupplierListItemModel> get _activeSuggestions {
    final query = _isMobileActive
        ? widget.ctrl.supplierMobileCtrl.text.trim().toLowerCase()
        : widget.ctrl.supplierNameCtrl.text.trim().toLowerCase();

    if (query.isEmpty) {
      return const [];
    }

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

  void _onNameChanged() {
    if (widget.ctrl.isApplyingSupplierProfile) {
      return;
    }
    _isMobileActive = false;
    final linked = widget.ctrl.linkedSupplier;
    final text = widget.ctrl.supplierNameCtrl.text;
    if (linked != null && linked.businessName == text) {
      return;
    }
    widget.ctrl.setSessionSupplierText(text);
  }

  void _onMobileChanged() {
    if (widget.ctrl.isApplyingSupplierProfile) {
      return;
    }
    _isMobileActive = true;
    final linked = widget.ctrl.linkedSupplier;
    final text = widget.ctrl.supplierMobileCtrl.text;
    if (linked != null && linked.mobile == text) {
      return;
    }
    widget.ctrl.updateSupplierMobileText(text);
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});

    // ✅ FIX: Supplier already linked hai toh overlay dobara mat dikhao.
    // setSessionSupplier() ke baad controller notify hota hai aur yahan
    // phir se suggestions show ho jaate the — isliye yeh check zaroori hai.
    if (widget.ctrl.hasLinkedSupplier) {
      _removeSuggestionOverlay();
      return;
    }

    if (_activeSuggestions.isEmpty) {
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
    if (!mounted) {
      return;
    }
    _removeSuggestionOverlay();

    final activeLink =
        _isMobileActive ? _mobileSuggestionLink : _nameSuggestionLink;

    _suggestionOverlay = OverlayEntry(
      builder: (context) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final width = screenWidth > 430
            ? 340.0
            : (screenWidth - 28).clamp(240.0, 340.0).toDouble();

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
              child: _GoldSupplierLookupDropdown(
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

    if (!mounted) {
      return;
    }
    await widget.ctrl.reloadSuppliers();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: GoldStockColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: GoldStockColors.brandGold.withValues(alpha: 0.10),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
              const BoxShadow(
                color: GoldStockColors.shadowMedium,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: GoldStockColors.brandGold.withValues(alpha: 0.22),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      GoldStockColors.brandGold.withValues(alpha: 0.48),
                      GoldStockColors.brandGold.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _buildInputsRow(),
              const SizedBox(height: 14),
              _buildStateCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final showCreateCta = _notFound;

    final badge = showCreateCta
        ? _GoldPrimaryActionChip(
            title: GoldStockStrings.createSupplier,
            icon: GoldStockIcons.createSupplierIcon,
            onTap: _openCreateSupplier,
          )
        : widget.ctrl.hasLinkedSupplier
            ? const _GoldStatusBadge(
                label: GoldStockStrings.ledgerLinked,
              )
            : const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackHeader = constraints.maxWidth < 760;

        final titleBlock = Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                GoldStockStrings.supplierProfileTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoldStockStyles.pageTitle.copyWith(
                  fontSize: 18,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                GoldStockStrings.supplierProfileDesc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoldStockStyles.caption.copyWith(
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    GoldStockColors.gradientStart,
                    GoldStockColors.brandGold,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: GoldStockColors.brandGold.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                GoldStockIcons.supplierProfile,
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
                  label: GoldStockStrings.fieldMobileNumber,
                  hint: GoldStockStrings.hintSearchByPhone,
                  controller: widget.ctrl.supplierMobileCtrl,
                  isNumber: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  icon: GoldStockIcons.phone,
                ),
              ),
              const SizedBox(height: 12),
              CompositedTransformTarget(
                link: _nameSuggestionLink,
                child: _buildInput(
                  label: GoldStockStrings.fieldSupplierName,
                  hint: GoldStockStrings.hintSearchByName,
                  controller: widget.ctrl.supplierNameCtrl,
                  icon: GoldStockIcons.businessName,
                ),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CompositedTransformTarget(
                link: _mobileSuggestionLink,
                child: _buildInput(
                  label: GoldStockStrings.fieldMobileNumber,
                  hint: GoldStockStrings.hintSearchByPhone,
                  controller: widget.ctrl.supplierMobileCtrl,
                  isNumber: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  icon: GoldStockIcons.phone,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CompositedTransformTarget(
                link: _nameSuggestionLink,
                child: _buildInput(
                  label: GoldStockStrings.fieldSupplierName,
                  hint: GoldStockStrings.hintSearchByName,
                  controller: widget.ctrl.supplierNameCtrl,
                  icon: GoldStockIcons.businessName,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStateCard() {
    if (_notFound) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: GoldStockColors.warningBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: GoldStockColors.warning.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              GoldStockIcons.warning,
              color: GoldStockColors.warning,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                GoldStockStrings.notFoundMessage,
                style: GoldStockStyles.caption.copyWith(
                  color: GoldStockColors.textDark,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final linked = widget.ctrl.linkedSupplier;
    if (linked == null) {
      return const SizedBox.shrink();
    }

    final supplierName = widget.ctrl.supplierDisplayName.trim().isEmpty
        ? GoldStockStrings.linkedSupplierFallback
        : widget.ctrl.supplierDisplayName;

    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: GoldStockColors.success,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            supplierName,
            style: GoldStockStyles.sectionTitle.copyWith(
              fontSize: 14,
              color: GoldStockColors.success,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

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
        Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: GoldStockColors.brandGold,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 170),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoldStockStyles.fieldLabel.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: GoldStockColors.textDark,
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
            style: GoldStockStyles.fieldInput.copyWith(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoldStockStyles.fieldHint.copyWith(
                color: GoldStockColors.textHint.withValues(alpha: 0.7),
                fontSize: 13,
              ),
              prefixIcon: icon != null
                  ? Icon(icon, size: 18, color: GoldStockColors.textMuted)
                  : null,
              filled: true,
              fillColor: readOnly
                  ? GoldStockColors.inputBgLocked
                  : GoldStockColors.inputBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: GoldStockColors.cardBorder,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: GoldStockColors.cardBorder,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: GoldStockColors.brandGold,
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

class _GoldSupplierLookupDropdown extends StatelessWidget {
  final List<SupplierListItemModel> suppliers;
  final ValueChanged<SupplierListItemModel> onSelected;

  const _GoldSupplierLookupDropdown({
    required this.suppliers,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: GoldStockColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GoldStockColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: GoldStockColors.shadowMedium,
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
            const Divider(height: 1, color: GoldStockColors.cardBorder),
        itemBuilder: (context, index) {
          final supplier = suppliers[index];
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              backgroundColor:
                  GoldStockColors.brandGold.withValues(alpha: 0.12),
              child: Text(
                supplier.avatarInitial,
                style: const TextStyle(
                  color: GoldStockColors.goldAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            title: Text(
              supplier.businessName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoldStockStyles.sectionTitle.copyWith(
                color: GoldStockColors.textDark,
              ),
            ),
            subtitle: Text(
              [
                supplier.mobile,
                supplier.supplierType.label,
              ].where((v) => v.isNotEmpty).join(' | '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoldStockStyles.caption.copyWith(fontSize: 12),
            ),
            onTap: () => onSelected(supplier),
          );
        },
      ),
    );
  }
}

class _GoldPrimaryActionChip extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _GoldPrimaryActionChip({
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
              GoldStockColors.gradientStart,
              GoldStockColors.brandGold,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: GoldStockColors.brandGold.withValues(alpha: 0.28),
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
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoldStockStyles.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldStatusBadge extends StatelessWidget {
  final String label;

  const _GoldStatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: GoldStockColors.brandGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: GoldStockColors.brandGold.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: GoldStockColors.brandGold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoldStockStyles.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: GoldStockColors.goldAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
