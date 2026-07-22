import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_model.dart';
import 'package:lotus_erp/features/stock/shared/presentation/supplier/add_supplier/add_supplier_screen.dart';
import 'package:lotus_erp/features/stock/shared/presentation/supplier/supplier_profile/supplier_profile_screen.dart';
import 'package:lotus_erp/features/stock/silver/application/silver_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_silver/silver_stock_theme.dart';
part 'silver_invoice_supplier_widgets.dart';
part 'silver_invoice_purchase_widgets.dart';

class SilverInvoiceCard extends StatefulWidget {
  final SilverStockController ctrl;

  const SilverInvoiceCard({
    super.key,
    required this.ctrl,
  });

  @override
  State<SilverInvoiceCard> createState() => _SilverInvoiceCardState();
}

class _SilverInvoiceCardState extends State<SilverInvoiceCard> {
  final LayerLink _mobileSuggestionLink = LayerLink();
  final LayerLink _nameSuggestionLink = LayerLink();

  OverlayEntry? _suggestionOverlay;
  bool _isMobileActive = false;

  SilverStockController get ctrl => widget.ctrl;

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
    SupplierListItemModel? refreshedSupplier;
    for (final supplier in ctrl.suppliers) {
      if (supplier.id == supplierId) {
        refreshedSupplier = supplier;
        break;
      }
    }
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
            ? SilverStockColors.success
            : SilverStockColors.brandSilver;

        return Container(
          decoration: BoxDecoration(
            color: SilverStockColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SilverStockColors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: SilverStockColors.shadowLight,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
              BoxShadow(
                color: SilverStockColors.shadowMedium,
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
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SilverStockColors.cardBorder),
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
                            accent: accent,
                          );
                          final billUpload = _BillPhotoPicker(
                            ctrl: ctrl,
                            accent: accent,
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
