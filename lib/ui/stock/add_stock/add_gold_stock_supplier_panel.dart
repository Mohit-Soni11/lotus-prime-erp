import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lotus_erp/logic/stock/add_stock_controller.dart';
import 'package:lotus_erp/models/stock/supplier_model/supplier_model.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';
import 'package:lotus_erp/ui/stock/supplier/add_supplier/add_supplier_screen.dart';

class AddGoldStockSupplierPanel extends StatefulWidget {
  final AddStockController ctrl;

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
        .where((supplier) {
          return supplier.businessName.toLowerCase().contains(query) ||
              supplier.mobile.contains(query) ||
              (supplier.contactPersonName ?? '').toLowerCase().contains(query);
        })
        .take(8)
        .toList(growable: false);
  }

  bool get _notFound {
    final activeText = _isMobileActive
        ? widget.ctrl.supplierMobileCtrl.text.trim()
        : widget.ctrl.supplierNameCtrl.text.trim();
    return activeText.isNotEmpty && _activeSuggestions.isEmpty;
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
        final width = MediaQuery.sizeOf(context).width > 430
            ? 360.0
            : (MediaQuery.sizeOf(context).width - 28)
                .clamp(240.0, 360.0)
                .toDouble();

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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AddStockColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AddStockColors.brandGold.withValues(alpha: 0.10),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
              const BoxShadow(
                color: AddStockColors.shadowMedium,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: AddStockColors.brandGold.withValues(alpha: 0.22),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AddStockColors.brandGold.withValues(alpha: 0.48),
                      AddStockColors.brandGold.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final singleColumn = constraints.maxWidth < 760;

                  return Column(
                    children: [
                      if (singleColumn) ...[
                        CompositedTransformTarget(
                          link: _mobileSuggestionLink,
                          child: _buildInput(
                            label: 'MOBILE NUMBER',
                            hint: 'Search by phone',
                            controller: widget.ctrl.supplierMobileCtrl,
                            isNumber: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            icon: Icons.phone_android_rounded,
                          ),
                        ),
                        const SizedBox(height: 12),
                        CompositedTransformTarget(
                          link: _nameSuggestionLink,
                          child: _buildInput(
                            label: 'SUPPLIER NAME',
                            hint: 'Search by supplier name',
                            controller: widget.ctrl.supplierNameCtrl,
                            icon: Icons.business_center_rounded,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInput(
                          label: 'ADDRESS',
                          hint: 'Auto-filled after link',
                          controller: widget.ctrl.supplierRegionCtrl,
                          readOnly: true,
                          icon: Icons.location_on_outlined,
                        ),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 190,
                              child: CompositedTransformTarget(
                                link: _mobileSuggestionLink,
                                child: _buildInput(
                                  label: 'MOBILE NUMBER',
                                  hint: 'Search by phone',
                                  controller: widget.ctrl.supplierMobileCtrl,
                                  isNumber: true,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  icon: Icons.phone_android_rounded,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CompositedTransformTarget(
                                link: _nameSuggestionLink,
                                child: _buildInput(
                                  label: 'SUPPLIER NAME',
                                  hint: 'Search by supplier name',
                                  controller: widget.ctrl.supplierNameCtrl,
                                  icon: Icons.business_center_rounded,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInput(
                                label: 'ADDRESS',
                                hint: 'Auto-filled after link',
                                controller: widget.ctrl.supplierRegionCtrl,
                                readOnly: true,
                                icon: Icons.location_on_outlined,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
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

  Widget _buildHeader() {
    final showCreateCta = _notFound;
    final badge = showCreateCta
        ? _PrimaryActionChip(
            title: 'Create Supplier',
            icon: Icons.person_add_alt_1_rounded,
            onTap: _openCreateSupplier,
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AddStockColors.brandGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AddStockColors.brandGold.withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AddStockColors.brandGold,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.ctrl.hasLinkedSupplier
                      ? 'Ledger Linked'
                      : 'Lookup Ready',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AddStockColors.brandGold,
                  ),
                ),
              ],
            ),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackHeader = constraints.maxWidth < 760;

        final titleBlock = Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SUPPLIER PROFILE',
                style: AddStockStyles.pageTitle.copyWith(
                  fontSize: 18,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Search by name or mobile and bind this entire batch to one supplier ledger',
                style: AddStockStyles.caption.copyWith(
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
                    AddStockColors.goldGradientStart,
                    AddStockColors.brandGold,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AddStockColors.brandGold.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_tree_rounded,
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

  Widget _buildStatusCard() {
    if (_notFound) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AddStockColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AddStockColors.warning.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AddStockColors.warning,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No supplier profile matched this lookup. Create the supplier first so this gold batch can be linked to the correct ledger.',
                style: AddStockStyles.caption.copyWith(
                  color: AddStockColors.textDark,
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
    final detailParts = [
      widget.ctrl.supplierMobileCtrl.text.trim(),
      widget.ctrl.supplierRegionCtrl.text.trim(),
      if (widget.ctrl.supplierGstCtrl.text.trim().isNotEmpty)
        'GST ${widget.ctrl.supplierGstCtrl.text.trim()}',
    ].where((value) => value.isNotEmpty).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AddStockColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AddStockColors.success.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AddStockColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: AddStockColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.ctrl.supplierDisplayName.trim().isEmpty
                      ? 'Linked Supplier'
                      : widget.ctrl.supplierDisplayName,
                  style: AddStockStyles.sectionTitle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'This batch will be recorded against the supplier ledger automatically.',
                  style: AddStockStyles.caption.copyWith(
                    color: AddStockColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (detailParts.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    detailParts.join(' | '),
                    style: AddStockStyles.caption.copyWith(
                      color: AddStockColors.textBody,
                      fontSize: 12,
                    ),
                  ),
                ],
                if ((linked?.contactPersonName ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Contact: ${linked!.contactPersonName}',
                    style: AddStockStyles.caption.copyWith(
                      color: AddStockColors.textBody,
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

  Widget _buildInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isNumber = false,
    bool isCaps = false,
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
                color: AddStockColors.brandGold,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AddStockColors.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
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
            textCapitalization: isCaps
                ? TextCapitalization.characters
                : TextCapitalization.none,
            inputFormatters: inputFormatters,
            style: AddStockStyles.fieldInput.copyWith(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AddStockColors.textMuted.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: icon != null
                  ? Icon(icon, size: 18, color: AddStockColors.textMuted)
                  : null,
              filled: true,
              fillColor: readOnly
                  ? AddStockColors.inputBgLocked
                  : AddStockColors.inputBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: AddStockColors.cardBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AddStockColors.cardBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: AddStockColors.brandGold,
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
        color: AddStockColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AddStockColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AddStockColors.shadowMedium,
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
            const Divider(height: 1, color: AddStockColors.cardBorder),
        itemBuilder: (context, index) {
          final supplier = suppliers[index];
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              backgroundColor: AddStockColors.brandGold.withValues(alpha: 0.12),
              child: Text(
                supplier.avatarInitial,
                style: const TextStyle(
                  color: AddStockColors.brandGold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            title: Text(
              supplier.businessName,
              style: const TextStyle(
                color: AddStockColors.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              [
                supplier.mobile,
                supplier.supplierType.label,
              ].where((value) => value.isNotEmpty).join(' | '),
              style: AddStockStyles.caption.copyWith(fontSize: 12),
            ),
            onTap: () => onSelected(supplier),
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final background =
        widget.isPrimary ? AddStockColors.brandGold : AddStockColors.bodyBg;
    final foreground =
        widget.isPrimary ? Colors.white : AddStockColors.brandGold;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          decoration: BoxDecoration(
            color: _isHovered
                ? background.withValues(alpha: widget.isPrimary ? 0.92 : 1)
                : background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isPrimary
                  ? AddStockColors.brandGold
                  : AddStockColors.brandGold.withValues(alpha: 0.25),
            ),
            boxShadow: _isHovered && widget.isPrimary
                ? [
                    BoxShadow(
                      color: AddStockColors.brandGold.withValues(alpha: 0.24),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: foreground, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionChip extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryActionChip({
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
              AddStockColors.goldGradientStart,
              AddStockColors.brandGold,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AddStockColors.brandGold.withValues(alpha: 0.28),
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
              style: const TextStyle(
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
