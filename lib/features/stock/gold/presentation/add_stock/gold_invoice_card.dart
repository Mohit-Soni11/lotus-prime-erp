import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/features/stock/gold/application/gold_stock_controller.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_model.dart';
import 'package:lotus_erp/features/stock/shared/presentation/supplier/add_supplier/add_supplier_screen.dart';
import 'package:lotus_erp/features/stock/shared/presentation/supplier/supplier_profile/supplier_profile_screen.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';

class GoldInvoiceCard extends StatefulWidget {
  final GoldStockController ctrl;

  const GoldInvoiceCard({
    super.key,
    required this.ctrl,
  });

  @override
  State<GoldInvoiceCard> createState() => _GoldInvoiceCardState();
}

class _GoldInvoiceCardState extends State<GoldInvoiceCard> {
  final LayerLink _mobileSuggestionLink = LayerLink();
  final LayerLink _nameSuggestionLink = LayerLink();

  OverlayEntry? _suggestionOverlay;
  bool _isMobileActive = false;

  GoldStockController get ctrl => widget.ctrl;

  @override
  void initState() {
    super.initState();
    ctrl.supplierNameCtrl.addListener(_onNameChanged);
    ctrl.supplierMobileCtrl.addListener(_onMobileChanged);
    ctrl.addListener(_onControllerChanged);

    if (!ctrl.sameForAll) {
      ctrl.setSameForAll(true);
    }
  }

  @override
  void dispose() {
    _removeSuggestionOverlay();
    ctrl.supplierNameCtrl.removeListener(_onNameChanged);
    ctrl.supplierMobileCtrl.removeListener(_onMobileChanged);
    ctrl.removeListener(_onControllerChanged);
    super.dispose();
  }

  List<SupplierListItemModel> get _activeSuggestions {
    final query = _isMobileActive
        ? ctrl.supplierMobileCtrl.text.trim().toLowerCase()
        : ctrl.supplierNameCtrl.text.trim().toLowerCase();

    if (query.isEmpty) {
      return const [];
    }

    return ctrl.suppliers
        .where(
          (supplier) =>
              supplier.businessName.toLowerCase().contains(query) ||
              supplier.mobile.contains(query) ||
              (supplier.contactPersonName ?? '').toLowerCase().contains(query),
        )
        .take(8)
        .toList(growable: false);
  }

  bool get _notFound {
    final text = _isMobileActive
        ? ctrl.supplierMobileCtrl.text.trim()
        : ctrl.supplierNameCtrl.text.trim();

    return text.isNotEmpty &&
        _activeSuggestions.isEmpty &&
        !ctrl.hasLinkedSupplier;
  }

  void _onNameChanged() {
    if (ctrl.isApplyingSupplierProfile) {
      return;
    }

    _isMobileActive = false;
    final linked = ctrl.linkedSupplier;
    final text = ctrl.supplierNameCtrl.text;

    if (linked != null && linked.businessName == text) {
      return;
    }

    ctrl.setSessionSupplierText(text);
  }

  void _onMobileChanged() {
    if (ctrl.isApplyingSupplierProfile) {
      return;
    }

    _isMobileActive = true;
    final linked = ctrl.linkedSupplier;
    final text = ctrl.supplierMobileCtrl.text;

    if (linked != null && linked.mobile == text) {
      return;
    }

    ctrl.updateSupplierMobileText(text);
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});

    if (ctrl.hasLinkedSupplier) {
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
        final width = screenWidth > 520
            ? 420.0
            : (screenWidth - 28).clamp(260.0, 420.0).toDouble();

        return Positioned(
          top: 0,
          left: 0,
          width: width,
          child: CompositedTransformFollower(
            link: activeLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 52),
            child: Material(
              color: Colors.transparent,
              elevation: 10,
              borderRadius: BorderRadius.circular(12),
              child: _SupplierLookupDropdown(
                suppliers: _activeSuggestions,
                onSelected: (supplier) {
                  FocusScope.of(context).unfocus();
                  ctrl.setSessionSupplier(supplier);
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

    await ctrl.reloadSuppliers();
  }

  Future<void> _openLinkedSupplierProfile() async {
    final supplierId = ctrl.linkedSupplier?.id ?? ctrl.sessionSupplierId;
    if (supplierId == null) {
      return;
    }

    _removeSuggestionOverlay();
    FocusScope.of(context).unfocus();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SupplierProfileScreen(
          supplierId: supplierId,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await ctrl.reloadSuppliers();
    final refreshedSupplier = ctrl.suppliers
        .where((supplier) => supplier.id == supplierId)
        .firstOrNull;
    if (refreshedSupplier != null) {
      ctrl.setSessionSupplier(refreshedSupplier);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ctrl,
        ctrl.supplierNameCtrl,
        ctrl.supplierMobileCtrl,
        ctrl.supplierInvoiceNumberCtrl,
      ]),
      builder: (context, _) {
        final accent = ctrl.gstEnabled
            ? AddStockColors.brandGold
            : AddStockColors.textDark;

        return Container(
          decoration: BoxDecoration(
            color: AddStockColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AddStockColors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: AddStockColors.shadowLight,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
              BoxShadow(
                color: AddStockColors.shadowMedium,
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                accent: accent,
                gstEnabled: ctrl.gstEnabled,
                hasSupplier: ctrl.hasLinkedSupplier,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SupplierLookupSection(
                      ctrl: ctrl,
                      mobileSuggestionLink: _mobileSuggestionLink,
                      nameSuggestionLink: _nameSuggestionLink,
                      notFound: _notFound,
                      onCreateSupplier: _openCreateSupplier,
                      onOpenSupplierProfile: _openLinkedSupplierProfile,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFCF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AddStockColors.cardBorder),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final stacked = constraints.maxWidth < 720;

                          final purchaseType = _PurchaseTypeSelector(
                            gstEnabled: ctrl.gstEnabled,
                            onChanged: ctrl.toggleGst,
                          );
                          final invoiceInput = _SupplierInvoiceInput(
                            ctrl: ctrl,
                            accent: AddStockColors.brandGold,
                          );
                          final billUpload = _BillPhotoPicker(
                            ctrl: ctrl,
                            accent: AddStockColors.brandGold,
                          );

                          if (stacked) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                purchaseType,
                                const SizedBox(height: 12),
                                invoiceInput,
                                const SizedBox(height: 12),
                                billUpload,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 34, child: purchaseType),
                              const SizedBox(width: 12),
                              Expanded(flex: 36, child: invoiceInput),
                              const SizedBox(width: 12),
                              Expanded(flex: 30, child: billUpload),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    _Note(gstEnabled: ctrl.gstEnabled),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final Color accent;
  final bool gstEnabled;
  final bool hasSupplier;

  const _Header({
    required this.accent,
    required this.gstEnabled,
    required this.hasSupplier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AddStockColors.cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AddStockColors.brandGoldLight,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AddStockColors.brandGoldBorder),
            ),
            child: const Icon(
              Icons.person_pin_circle_outlined,
              size: 17,
              color: AddStockColors.brandGold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '2. Supplier & Invoice',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.1,
                    color: AddStockColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasSupplier
                      ? 'Supplier linked with this stock batch'
                      : 'Select supplier and attach purchase reference',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AddStockColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StatusPill(
            label: gstEnabled ? 'GST Purchase' : 'Non-GST',
            color: gstEnabled
                ? AddStockColors.brandGold
                : AddStockColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _SupplierLookupSection extends StatelessWidget {
  final GoldStockController ctrl;
  final LayerLink mobileSuggestionLink;
  final LayerLink nameSuggestionLink;
  final bool notFound;
  final VoidCallback onCreateSupplier;
  final VoidCallback onOpenSupplierProfile;

  const _SupplierLookupSection({
    required this.ctrl,
    required this.mobileSuggestionLink,
    required this.nameSuggestionLink,
    required this.notFound,
    required this.onCreateSupplier,
    required this.onOpenSupplierProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AddStockColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AddStockColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 560;

              final mobileField = CompositedTransformTarget(
                link: mobileSuggestionLink,
                child: _SupplierTextField(
                  label: 'Mobile Number',
                  hint: 'Search by mobile number',
                  controller: ctrl.supplierMobileCtrl,
                  icon: Icons.phone_iphone_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
              );

              final nameField = CompositedTransformTarget(
                link: nameSuggestionLink,
                child: _SupplierTextField(
                  label: 'Supplier Name',
                  hint: 'Search by supplier name',
                  controller: ctrl.supplierNameCtrl,
                  icon: AddStockIcons.supplier,
                ),
              );

              if (stacked) {
                return Column(
                  children: [
                    mobileField,
                    const SizedBox(height: 12),
                    nameField,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: mobileField),
                  const SizedBox(width: 12),
                  Expanded(child: nameField),
                ],
              );
            },
          ),
          if (notFound) ...[
            const SizedBox(height: 12),
            _SupplierStateBanner(
              type: _SupplierStateType.notFound,
              title: 'Supplier not found',
              message:
                  'Create a supplier profile once, then this batch will link to supplier ledger automatically.',
              actionLabel: 'Create Supplier',
              onAction: onCreateSupplier,
            ),
          ] else if (ctrl.hasLinkedSupplier) ...[
            const SizedBox(height: 12),
            _SupplierStateBanner(
              type: _SupplierStateType.linked,
              title: 'Supplier linked',
              message: ctrl.supplierDisplayName.trim().isEmpty
                  ? 'Selected supplier profile is linked to this batch.'
                  : ctrl.supplierDisplayName,
              actionLabel: 'Open Profile',
              onAction: onOpenSupplierProfile,
              secondaryActionLabel: 'Change',
              onSecondaryAction: () => ctrl.clearSessionSupplier(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SupplierTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _SupplierTextField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AddStockColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AddStockColors.textDark,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AddStockColors.textHint,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(9),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AddStockColors.brandGoldLight,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      icon,
                      size: 14,
                      color: AddStockColors.brandGold,
                    ),
                  ),
                ),
                filled: true,
                fillColor: AddStockColors.cardBg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide:
                      const BorderSide(color: AddStockColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide:
                      const BorderSide(color: AddStockColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(
                    color: AddStockColors.brandGold,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _SupplierStateType { linked, notFound }

class _SupplierStateBanner extends StatelessWidget {
  final _SupplierStateType type;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const _SupplierStateBanner({
    required this.type,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final linked = type == _SupplierStateType.linked;
    final color = linked ? AddStockColors.success : AddStockColors.warning;
    final bg = linked ? AddStockColors.successBg : AddStockColors.warningBg;
    final icon =
        linked ? Icons.check_circle_rounded : Icons.warning_amber_rounded;

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AddStockColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AddStockColors.textBody,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            alignment: WrapAlignment.end,
            children: [
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  actionLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (secondaryActionLabel != null && onSecondaryAction != null)
                TextButton(
                  onPressed: onSecondaryAction,
                  style: TextButton.styleFrom(
                    foregroundColor: AddStockColors.textMuted,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    secondaryActionLabel!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SupplierLookupDropdown extends StatelessWidget {
  final List<SupplierListItemModel> suppliers;
  final ValueChanged<SupplierListItemModel> onSelected;

  const _SupplierLookupDropdown({
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
          final subtitle = [
            supplier.mobile,
            supplier.supplierType.label,
          ].where((value) => value.isNotEmpty).join(' • ');

          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: AddStockColors.brandGoldLight,
              child: Text(
                supplier.avatarInitial,
                style: GoogleFonts.inter(
                  color: AddStockColors.brandGold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            title: Text(
              supplier.businessName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: AddStockColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: AddStockColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: AddStockColors.textHint,
            ),
            onTap: () => onSelected(supplier),
          );
        },
      ),
    );
  }
}

class _PurchaseTypeSelector extends StatelessWidget {
  final bool gstEnabled;
  final ValueChanged<bool> onChanged;

  const _PurchaseTypeSelector({
    required this.gstEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Purchase Type',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AddStockColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 42,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AddStockColors.cardBg,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AddStockColors.cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: _PurchaseTypeButton(
                  selected: gstEnabled,
                  label: 'GST Purchase',
                  icon: Icons.verified_user_outlined,
                  onTap: () => onChanged(true),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _PurchaseTypeButton(
                  selected: !gstEnabled,
                  label: 'Non-GST / No ITC',
                  icon: Icons.receipt_outlined,
                  onTap: () => onChanged(false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PurchaseTypeButton extends StatelessWidget {
  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PurchaseTypeButton({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AddStockColors.textDark;
    final background = selected ? AddStockColors.brandGold : Colors.transparent;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: foreground),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupplierInvoiceInput extends StatelessWidget {
  final GoldStockController ctrl;
  final Color accent;

  const _SupplierInvoiceInput({
    required this.ctrl,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Supplier Invoice No.',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AddStockColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: TextFormField(
            controller: ctrl.supplierInvoiceNumberCtrl,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AddStockColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: 'Enter supplier invoice number',
              hintStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AddStockColors.textHint,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(9),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    AddStockIcons.hsn,
                    size: 14,
                    color: accent,
                  ),
                ),
              ),
              filled: true,
              fillColor: AddStockColors.cardBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: AddStockColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: AddStockColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: BorderSide(color: accent, width: 1.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BillPhotoPicker extends StatelessWidget {
  final GoldStockController ctrl;
  final Color accent;

  const _BillPhotoPicker({
    required this.ctrl,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final photoPath = ctrl.billPhotoPath;
    final hasPhoto = photoPath != null && photoPath.isNotEmpty;
    final canPreview = hasPhoto && File(photoPath).existsSync();
    final isPdf = hasPhoto && photoPath.toLowerCase().endsWith('.pdf');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Supplier Bill',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AddStockColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: OutlinedButton(
            onPressed: ctrl.isPickingBillPhoto ? null : ctrl.pickBillPhoto,
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              backgroundColor: AddStockColors.cardBg,
              side: BorderSide(color: accent.withValues(alpha: 0.38)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (ctrl.isPickingBillPhoto)
                  SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accent,
                    ),
                  )
                else if (canPreview && !isPdf)
                  Container(
                    width: 22,
                    height: 22,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Image.file(File(photoPath), fit: BoxFit.cover),
                  )
                else if (isPdf)
                  Icon(Icons.picture_as_pdf_rounded, size: 17, color: accent)
                else
                  Icon(Icons.upload_file_rounded, size: 17, color: accent),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    hasPhoto ? 'Change Bill File' : 'Upload Bill / PDF',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (hasPhoto) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: ctrl.clearBillPhoto,
                    child: const Padding(
                      padding: EdgeInsets.all(3),
                      child: Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: AddStockColors.danger,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  final bool gstEnabled;

  const _Note({required this.gstEnabled});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note:',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AddStockColors.brandGold,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            gstEnabled
                ? 'GST purchase requires invoice number and bill photo/PDF. Supplier GSTIN can be updated later from supplier profile.'
                : 'Non-GST purchases stay separate as No ITC records in supplier history.',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AddStockColors.textBody,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
