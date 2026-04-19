// =============================================================================
// FILE        : add_stock_screen.dart
// MODULE      : Stock & Inventory
// LAYER       : UI / Screen
// DESCRIPTION : Stepped Add Stock wizard. Dark AppBar + Cream body.
//               Step 1 → Metal  → Step 2 → Purity  → Step 3 → Items
//
//               Step 3: Invoice-style multi-row table with:
//               - Auto net weight = Gross − Stone
//               - Stone Value as separate ₹ charge (NOT deducted)
//               - 🔒 Owner-only section (purchaseRate, making, cost price)
//               - Session-level OR per-row supplier selection
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../logic/stock/add_stock_controller.dart';
import '../../../models/stock/stock_enums/stock_enums.dart';
import '../../../../../models/stock/supplier_model/supplier_model.dart';
import '../../../theme/stock/add_stock/add_stock_theme.dart';

// =============================================================================
// ROOT SCREEN
// =============================================================================

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});
  @override State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen>
    with SingleTickerProviderStateMixin {

  late final AddStockController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AddStockController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ctrl,
      builder: (context, _) => Scaffold(
        backgroundColor: AddStockColors.bodyBg,
        appBar: _buildAppBar(),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve:  Curves.easeOutQuart,
          switchOutCurve: Curves.easeInQuart,
          child: switch (_ctrl.step) {
            AddStockStep.metal  => _MetalStep(ctrl: _ctrl, key: const ValueKey('metal')),
            AddStockStep.purity => _PurityStep(ctrl: _ctrl, key: const ValueKey('purity')),
            AddStockStep.items  => _ItemsStep(ctrl: _ctrl, onSave: _onSave, key: const ValueKey('items')),
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(AddStockStyles.appBarHeight + 50),
      child: Container(
        decoration: const BoxDecoration(
          color: AddStockColors.shellPanelBg,
          border: Border(bottom: BorderSide(color: AddStockColors.shellBorder, width: 1)),
          boxShadow: [BoxShadow(color: Color(0x26000000), blurRadius: 16, offset: Offset(0, 4))],
        ),
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  if (_ctrl.step != AddStockStep.metal) ...[
                    GestureDetector(
                      onTap: _ctrl.prevStep,
                      child: Container(
                        width: 40, height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AddStockColors.shellBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AddStockColors.shellBorder),
                        ),
                        child: const Icon(AddStockIcons.backArrow, color: AddStockColors.shellTextTitle, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Row(
                    children: [
                      const Icon(AddStockIcons.addStock, color: AddStockColors.brandGold, size: 20),
                      const SizedBox(width: 8),
                      Text(AddStockStrings.screenTitle, style: AddStockStyles.shellTitle),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AddStockColors.moduleBadgeBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AddStockColors.moduleBadgeBorder),
                    ),
                    child: Text(AddStockStrings.moduleBadge,
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AddStockColors.moduleBadgeText)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Step indicator
            _StepIndicator(step: _ctrl.step),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    final success = await _ctrl.saveAll();
    if (!mounted) return;

    if (success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            const Icon(Icons.check_circle_rounded, color: AddStockColors.success, size: 28),
            const SizedBox(width: 10),
            Text(AddStockStrings.savedTitle, style: AddStockStyles.sectionTitle),
          ]),
          content: Text(_ctrl.successMessage ?? '', style: AddStockStyles.caption),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(context); _ctrl.resetAllRows(); },
              child: Text(AddStockStrings.btnAddMore, style: TextStyle(color: AddStockColors.brandGold, fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              onPressed: () { Navigator.pop(context); _ctrl.resetForNewBatch(); },
              style: ElevatedButton.styleFrom(backgroundColor: AddStockColors.shellBg, foregroundColor: AddStockColors.shellTextTitle),
              child: const Text(AddStockStrings.btnNewBatch),
            ),
            ElevatedButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              style: ElevatedButton.styleFrom(backgroundColor: AddStockColors.brandGold, foregroundColor: Colors.black),
              child: Text(AddStockStrings.btnDone, style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_ctrl.errorMessage ?? AddStockStrings.errSaveFailed),
        backgroundColor: AddStockColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

// =============================================================================
// STEP INDICATOR
// =============================================================================

class _StepIndicator extends StatelessWidget {
  final AddStockStep step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    final labels = [AddStockStrings.stepMetal, AddStockStrings.stepPurity, AddStockStrings.stepItems];
    final current = step.index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(3, (i) {
          final done   = i < current;
          final active = i == current;
          return Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: active ? AddStockColors.brandGold
                      : done ? AddStockColors.brandGold.withOpacity(0.5)
                      : AddStockColors.shellBorder,
                  child: done
                      ? const Icon(Icons.check, size: 13, color: Colors.black)
                      : Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: active ? Colors.black : AddStockColors.shellTextMuted)),
                ),
                const SizedBox(width: 6),
                Flexible(child: Text(labels[i], style: TextStyle(fontSize: 11, color: active ? AddStockColors.brandGold : AddStockColors.shellTextMuted, fontWeight: active ? FontWeight.w700 : FontWeight.normal))),
                if (i < 2) Expanded(child: Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 6), color: AddStockColors.shellBorder)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// =============================================================================
// STEP 1: METAL SELECTION
// =============================================================================

class _MetalStep extends StatelessWidget {
  final AddStockController ctrl;
  const _MetalStep({required this.ctrl, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(AddStockStrings.metalQuestion, style: AddStockStyles.pageTitle, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(AddStockStrings.metalSubtitle, style: AddStockStyles.caption, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.4,
            children: [
              _MetalTile(label: AddStockStrings.metalGold,     icon: Icons.circle,          accentColor: const Color(0xFFFFD700), metal: StockCategory.gold,     ctrl: ctrl),
              _MetalTile(label: AddStockStrings.metalSilver,   icon: Icons.circle,          accentColor: const Color(0xFF90A4AE), metal: StockCategory.silver,   ctrl: ctrl),
              _MetalTile(label: AddStockStrings.metalDiamond,  icon: Icons.diamond_outlined, accentColor: const Color(0xFF29B6F6), metal: StockCategory.diamond,  ctrl: ctrl),
              _MetalTile(label: AddStockStrings.metalPlatinum, icon: Icons.circle,          accentColor: const Color(0xFF78909C), metal: StockCategory.platinum, ctrl: ctrl),
            ],
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton.icon(
              onPressed: ctrl.nextStep,
              style: ElevatedButton.styleFrom(backgroundColor: AddStockColors.brandGold, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              label: Text(AddStockStrings.btnNextPurity, style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _MetalTile extends StatelessWidget {
  final String label; final IconData icon; final Color accentColor;
  final StockCategory metal; final AddStockController ctrl;
  const _MetalTile({required this.label, required this.icon, required this.accentColor, required this.metal, required this.ctrl});

  bool get isSelected => ctrl.selectedMetal == metal;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ctrl.setMetal(metal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.12) : AddStockColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? accentColor : AddStockColors.cardBorder, width: isSelected ? 2.5 : 1),
          boxShadow: [BoxShadow(color: isSelected ? accentColor.withOpacity(0.2) : AddStockColors.shadowLight, blurRadius: isSelected ? 12 : 6, offset: const Offset(0, 3))],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: accentColor, size: 36),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isSelected ? accentColor : AddStockColors.textBody)),
        ]),
      ),
    );
  }
}

// =============================================================================
// STEP 2: PURITY SELECTION
// =============================================================================

class _PurityStep extends StatefulWidget {
  final AddStockController ctrl;
  const _PurityStep({required this.ctrl, super.key});
  @override State<_PurityStep> createState() => _PurityStepState();
}

class _PurityStepState extends State<_PurityStep> {
  final _customCtrl = TextEditingController();
  @override void dispose() { _customCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: AddStockColors.brandGoldBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AddStockColors.brandGoldBorder)),
            child: Text(ctrl.selectedMetal.label, style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: AddStockColors.brandGold, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Text(AddStockStrings.purityQuestion, style: AddStockStyles.sectionTitle),
        ]),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12, runSpacing: 12,
          children: ctrl.purityOptions.map((opt) {
            final isSelected = ctrl.purityDisplay == opt || (!ctrl.isCustomPurity && ctrl.purityDisplay.isEmpty && opt == ctrl.purityOptions.first);
            return GestureDetector(
              onTap: () => ctrl.setPurity(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? AddStockColors.brandGold : AddStockColors.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? AddStockColors.brandGold : AddStockColors.cardBorder, width: isSelected ? 2 : 1),
                  boxShadow: [BoxShadow(color: isSelected ? AddStockColors.brandGoldGlow : AddStockColors.shadowLight, blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Text(opt, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isSelected ? Colors.black : AddStockColors.textBody)),
              ),
            );
          }).toList(),
        ),

        if (ctrl.isCustomPurity) ...[
          const SizedBox(height: 20),
          Text(AddStockStrings.purityCustomLabel, style: AddStockStyles.fieldLabel),
          const SizedBox(height: 8),
          TextFormField(
            controller: _customCtrl,
            onChanged: ctrl.setCustomPurity,
            style: AddStockStyles.fieldInput,
            decoration: InputDecoration(
              hintText: AddStockStrings.purityCustomHint,
              hintStyle: AddStockStyles.fieldHint,
              filled: true, fillColor: AddStockColors.inputBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AddStockColors.cardBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AddStockColors.brandGold, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],

        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity, height: 54,
          child: ElevatedButton.icon(
            onPressed: ctrl.canProceedFromPurity ? ctrl.nextStep : null,
            style: ElevatedButton.styleFrom(backgroundColor: AddStockColors.brandGold, disabledBackgroundColor: AddStockColors.inputBgLocked, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            label: Text(AddStockStrings.btnNextItems, style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ),
      ]),
    );
  }
}

// =============================================================================
// STEP 3: MULTI-ITEM ENTRY
// =============================================================================

class _ItemsStep extends StatelessWidget {
  final AddStockController ctrl;
  final Future<void> Function() onSave;
  const _ItemsStep({required this.ctrl, required this.onSave, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildSessionBar(context),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            ...ctrl.rows.map((row) => _ItemRowCard(row: row, ctrl: ctrl)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: ctrl.addRow,
              icon: const Icon(Icons.add_circle_outline_rounded, color: AddStockColors.brandGold),
              label: Text(AddStockStrings.btnAddRow, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AddStockColors.brandGold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AddStockColors.brandGold),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
      _buildSaveBar(context),
    ]);
  }

  Widget _buildSessionBar(BuildContext context) {
    return Container(
      color: AddStockColors.cardBg,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _badge(ctrl.selectedMetal.label, AddStockColors.brandGold),
          const SizedBox(width: 8),
          _badge(ctrl.purityDisplay, AddStockColors.accentPricing),
          const Spacer(),
          Text('${ctrl.rowCount} item${ctrl.rowCount != 1 ? 's' : ''}',
              style: AddStockStyles.caption.copyWith(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: _SupplierAutocomplete(
              label: AddStockStrings.supplierSession,
              suppliers: ctrl.suppliers,
              initialName: ctrl.sessionSupplierName,
              onSelected: ctrl.setSessionSupplier,
              onTextChanged: ctrl.setSessionSupplierText,
            ),
          ),
          const SizedBox(width: 10),
          Column(children: [
            Text(AddStockStrings.sameForAll, style: AddStockStyles.caption),
            Switch(value: ctrl.sameForAll, onChanged: ctrl.setSameForAll, activeColor: AddStockColors.brandGold, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
          ]),
        ]),
      ]),
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
  );

  Widget _buildSaveBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(color: AddStockColors.cardBg, boxShadow: [BoxShadow(color: AddStockColors.shadowMedium, blurRadius: 16, offset: const Offset(0, -4))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (ctrl.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(ctrl.errorMessage!, style: TextStyle(color: AddStockColors.danger, fontSize: 13)),
          ),
        SizedBox(
          width: double.infinity, height: 54,
          child: ElevatedButton.icon(
            onPressed: ctrl.isSaving ? null : onSave,
            style: ElevatedButton.styleFrom(backgroundColor: AddStockColors.accentPricing, disabledBackgroundColor: AddStockColors.inputBgLocked, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            icon: ctrl.isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(AddStockIcons.save, color: Colors.white, size: 20),
            label: Text(
              ctrl.isSaving ? AddStockStrings.btnSaving : 'Save ${ctrl.rowCount} Item${ctrl.rowCount > 1 ? 's' : ''} to Stock',
              style: AddStockStyles.saveButtonText.copyWith(color: Colors.white),
            ),
          ),
        ),
      ]),
    );
  }
}

// =============================================================================
// ITEM ROW CARD
// =============================================================================

class _ItemRowCard extends StatefulWidget {
  final StockRowEntry row;
  final AddStockController ctrl;
  const _ItemRowCard({required this.row, required this.ctrl});
  @override State<_ItemRowCard> createState() => _ItemRowCardState();
}

class _ItemRowCardState extends State<_ItemRowCard> {
  bool _expanded = true;

  late final TextEditingController _itemNameCtrl;
  late final TextEditingController _huidCtrl;
  late final TextEditingController _grossCtrl;
  late final TextEditingController _stoneWtCtrl;
  late final TextEditingController _stoneValCtrl;
  late final TextEditingController _rateCtrl;
  late final TextEditingController _makingCtrl;
  late final TextEditingController _caratCtrl;
  late final TextEditingController _pcsCtrl;

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    _itemNameCtrl = TextEditingController(text: r.itemName);
    _huidCtrl     = TextEditingController(text: r.huid);
    _grossCtrl    = TextEditingController(text: r.grossWeight > 0 ? r.grossWeight.toString() : '');
    _stoneWtCtrl  = TextEditingController(text: r.stoneWeight > 0 ? r.stoneWeight.toString() : '');
    _stoneValCtrl = TextEditingController(text: r.stoneValue > 0 ? r.stoneValue.toString() : '');
    _rateCtrl     = TextEditingController(text: r.purchaseRate > 0 ? r.purchaseRate.toString() : '');
    _makingCtrl   = TextEditingController(text: r.makingCharges > 0 ? r.makingCharges.toString() : '');
    _caratCtrl    = TextEditingController(text: r.stoneCarats > 0 ? r.stoneCarats.toString() : '');
    _pcsCtrl      = TextEditingController(text: r.stonePieces > 0 ? r.stonePieces.toString() : '');
  }

  @override
  void dispose() {
    for (final c in [_itemNameCtrl, _huidCtrl, _grossCtrl, _stoneWtCtrl, _stoneValCtrl, _rateCtrl, _makingCtrl, _caratCtrl, _pcsCtrl]) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final row  = widget.row;
    final idx  = ctrl.rows.indexOf(row) + 1;
    final err  = ctrl.validateRow(row);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AddStockColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: err != null ? AddStockColors.danger.withOpacity(0.4) : AddStockColors.cardBorder),
        boxShadow: [BoxShadow(color: AddStockColors.shadowLight, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        // ── Header ──────────────────────────────────────────────────────
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AddStockColors.brandGoldBg,
              borderRadius: _expanded ? const BorderRadius.vertical(top: Radius.circular(12)) : BorderRadius.circular(12),
            ),
            child: Row(children: [
              CircleAvatar(radius: 13, backgroundColor: AddStockColors.brandGold,
                child: Text('$idx', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black))),
              const SizedBox(width: 10),
              Expanded(child: Text(
                row.itemName.isNotEmpty ? row.itemName : 'New Item',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: row.itemName.isNotEmpty ? AddStockColors.textDark : AddStockColors.textHint),
              )),
              if (err != null) const Padding(padding: EdgeInsets.only(right: 8), child: Icon(Icons.error_outline, color: AddStockColors.danger, size: 18)),
              if (ctrl.rowCount > 1) InkWell(
                onTap: () => ctrl.removeRow(row.id),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete_outline_rounded, color: AddStockColors.danger, size: 20)),
              ),
              const SizedBox(width: 4),
              Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AddStockColors.brandGold),
            ]),
          ),
        ),

        // ── Body ────────────────────────────────────────────────────────
        if (_expanded) Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Item Name + Sub Category
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: _f(label: AddStockStrings.lblItemName, ctrl: _itemNameCtrl, onCh: (v) => ctrl.updateItemName(row.id, v), textCap: TextCapitalization.words)),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: _dd<StockSubCategory>(
                label: AddStockStrings.lblSubCategory,
                value: row.subCategory,
                items: StockSubCategory.values,
                labelFor: (e) => e.label,
                onChanged: (v) { if (v != null) ctrl.updateSubCategory(row.id, v); },
              )),
            ]),
            const SizedBox(height: 10),

            // HUID
            _f(label: AddStockStrings.lblHuid, hint: AddStockStrings.hintHuid, ctrl: _huidCtrl, onCh: (v) => ctrl.updateHuid(row.id, v), textCap: TextCapitalization.characters, maxLength: 6),
            const SizedBox(height: 10),

            // Weights
            _sectionLabel('Weight Details'),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: _f(label: AddStockStrings.lblGrossWeight, ctrl: _grossCtrl, onCh: (v) => ctrl.updateGrossWeight(row.id, v), keyboard: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: _f(label: AddStockStrings.lblStoneWeight, ctrl: _stoneWtCtrl, onCh: (v) => ctrl.updateStoneWeight(row.id, v), keyboard: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: _readOnly(label: AddStockStrings.lblNetWeight, value: row.netWeight > 0 ? '${row.netWeight.toStringAsFixed(3)} g' : '—', tooltip: AddStockStrings.netWeightNote)),
            ]),
            const SizedBox(height: 10),

            // Stone Value box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCE93D8)),
              ),
              child: Row(children: [
                const Icon(AddStockIcons.stoneDetails, size: 16, color: Color(0xFF7B1FA2)),
                const SizedBox(width: 8),
                Expanded(child: _f(label: AddStockStrings.lblStoneValue, ctrl: _stoneValCtrl, onCh: (v) => ctrl.updateStoneValue(row.id, v), keyboard: TextInputType.number, prefix: '₹')),
                const SizedBox(width: 10),
                const Expanded(flex: 2, child: Text(AddStockStrings.stoneValueNote, style: TextStyle(fontSize: 11, color: Color(0xFF7B1FA2), height: 1.4))),
              ]),
            ),
            const SizedBox(height: 10),

            // Stone type + carats + pieces
            Row(children: [
              Expanded(child: _dd<StoneType>(label: AddStockStrings.lblStoneType, value: row.stoneType, items: StoneType.values, labelFor: (e) => e.label, onChanged: (v) { if (v != null) ctrl.updateStoneType(row.id, v); })),
              const SizedBox(width: 10),
              Expanded(child: _f(label: AddStockStrings.lblCarats, ctrl: _caratCtrl, onCh: (v) => ctrl.updateStoneCarats(row.id, v), keyboard: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: _f(label: AddStockStrings.lblPieces, ctrl: _pcsCtrl, onCh: (v) => ctrl.updateStonePieces(row.id, v), keyboard: TextInputType.number)),
            ]),
            const SizedBox(height: 12),

            // 🔒 Owner-only
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AddStockColors.warningBg, borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AddStockColors.warning.withOpacity(0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(AddStockIcons.compliance, size: 14, color: AddStockColors.warning),
                  const SizedBox(width: 6),
                  Text(AddStockStrings.ownerOnlyTitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AddStockColors.warning)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _f(label: AddStockStrings.lblPurchaseRate, ctrl: _rateCtrl, onCh: (v) => ctrl.updatePurchaseRate(row.id, v), keyboard: TextInputType.number, prefix: '₹', fillColor: const Color(0xFFFFFDE7))),
                  const SizedBox(width: 10),
                  Expanded(child: _f(label: AddStockStrings.lblMakingCharges, ctrl: _makingCtrl, onCh: (v) => ctrl.updateMakingCharges(row.id, v), keyboard: TextInputType.number, prefix: '₹', fillColor: const Color(0xFFFFFDE7))),
                  const SizedBox(width: 10),
                  Expanded(child: _dd<MakingChargesType>(
                    label: AddStockStrings.lblMakingType,
                    value: row.makingChargesType,
                    items: MakingChargesType.values,
                    labelFor: (e) => e.label.split(' ').first,
                    onChanged: (v) { if (v != null) ctrl.updateMakingType(row.id, v); },
                    fillColor: const Color(0xFFFFFDE7),
                  )),
                ]),
                if (row.costPrice > 0) Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(children: [
                    const Icon(AddStockIcons.pricing, size: 14, color: AddStockColors.warning),
                    const SizedBox(width: 6),
                    Text('${AddStockStrings.costPriceLabel}₹${row.costPrice.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AddStockColors.warning)),
                  ]),
                ),
              ]),
            ),

            // Per-row supplier (when "same for all" = OFF)
            if (!widget.ctrl.sameForAll) ...[
              const SizedBox(height: 12),
              _SupplierAutocomplete(
                label: AddStockStrings.lblSupplierRow,
                suppliers: widget.ctrl.suppliers,
                initialName: row.supplierName,
                onSelected: (s) => widget.ctrl.setRowSupplier(row.id, s),
                onTextChanged: (v) { row.supplierName = v; },
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _sectionLabel(String label) => Text(label, style: AddStockStyles.sectionTitle.copyWith(fontSize: 12, letterSpacing: 0.5, color: AddStockColors.brandGold));

  Widget _f({required String label, String? hint, required TextEditingController ctrl, required Function(String) onCh,
      TextInputType keyboard = TextInputType.text, TextCapitalization textCap = TextCapitalization.none,
      int? maxLength, String? prefix, Color? fillColor}) {
    return TextFormField(
      controller: ctrl, onChanged: onCh, keyboardType: keyboard, textCapitalization: textCap, maxLength: maxLength,
      inputFormatters: keyboard == TextInputType.number ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))] : null,
      style: AddStockStyles.fieldInput,
      decoration: InputDecoration(
        labelText: label, hintText: hint, prefixText: prefix,
        labelStyle: AddStockStyles.fieldLabel, hintStyle: AddStockStyles.fieldHint,
        filled: true, fillColor: fillColor ?? AddStockColors.inputBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AddStockColors.cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AddStockColors.cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AddStockColors.brandGold, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), isDense: true, counterText: '',
      ),
    );
  }

  Widget _readOnly({required String label, required String value, String? tooltip}) {
    return Tooltip(
      message: tooltip ?? '',
      child: TextFormField(
        readOnly: true, initialValue: value,
        style: AddStockStyles.readOnlyValue,
        decoration: InputDecoration(
          labelText: label, labelStyle: AddStockStyles.fieldLabel,
          filled: true, fillColor: AddStockColors.inputBgLocked,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AddStockColors.cardBorder)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), isDense: true,
          suffixIcon: const Icon(Icons.calculate_outlined, size: 14, color: AddStockColors.success),
        ),
      ),
    );
  }

  Widget _dd<T>({required String label, required T value, required List<T> items,
      required String Function(T) labelFor, required void Function(T?) onChanged, Color? fillColor}) {
    return DropdownButtonFormField<T>(
      value: value, onChanged: onChanged, isExpanded: true,
      style: AddStockStyles.fieldInput,
      decoration: InputDecoration(
        labelText: label, labelStyle: AddStockStyles.fieldLabel,
        filled: true, fillColor: fillColor ?? AddStockColors.inputBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AddStockColors.cardBorder)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), isDense: true,
      ),
      items: items.map((e) => DropdownMenuItem<T>(value: e, child: Text(labelFor(e), overflow: TextOverflow.ellipsis))).toList(),
    );
  }
}

// =============================================================================
// SUPPLIER AUTOCOMPLETE FIELD
// =============================================================================

class _SupplierAutocomplete extends StatefulWidget {
  final String label;
  final List<SupplierListItemModel> suppliers;
  final String initialName;
  final void Function(SupplierListItemModel?) onSelected;
  final void Function(String) onTextChanged;
  const _SupplierAutocomplete({required this.label, required this.suppliers, required this.initialName, required this.onSelected, required this.onTextChanged});
  @override State<_SupplierAutocomplete> createState() => _SupplierAutocompleteState();
}

class _SupplierAutocompleteState extends State<_SupplierAutocomplete> {
  @override
  Widget build(BuildContext context) {
    return Autocomplete<SupplierListItemModel>(
      initialValue: TextEditingValue(text: widget.initialName),
      displayStringForOption: (s) => s.displayName,
      optionsBuilder: (tv) {
        if (tv.text.isEmpty) return const [];
        final q = tv.text.toLowerCase();
        return widget.suppliers.where((s) => s.businessName.toLowerCase().contains(q) || s.mobile.contains(q));
      },
      onSelected: widget.onSelected,
      fieldViewBuilder: (ctx, ctrl, focusNode, onSubmit) => TextField(
        controller: ctrl, focusNode: focusNode,
        onChanged: widget.onTextChanged,
        onSubmitted: (_) => onSubmit(),
        style: AddStockStyles.fieldInput,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: AddStockStrings.supplierHint,
          hintStyle: AddStockStyles.fieldHint,
          labelStyle: AddStockStyles.fieldLabel,
          prefixIcon: const Icon(AddStockIcons.supplier, color: AddStockColors.brandGold, size: 18),
          filled: true, fillColor: AddStockColors.inputBg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AddStockColors.cardBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AddStockColors.brandGold, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true,
          suffixIcon: ctrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () { ctrl.clear(); widget.onSelected(null); }) : null,
        ),
      ),
    );
  }
}