import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/features/stock/shared/application/add_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';
import 'package:lotus_erp/features/stock/shared/presentation/add_stock/stock_metal_ui.dart';

class AddStockPurityStep extends StatefulWidget {
  final AddStockController ctrl;

  const AddStockPurityStep({super.key, required this.ctrl});

  @override
  State<AddStockPurityStep> createState() => _AddStockPurityStepState();
}

class _AddStockPurityStepState extends State<AddStockPurityStep> {
  late final TextEditingController _customCtrl;

  @override
  void initState() {
    super.initState();
    _customCtrl = TextEditingController(text: widget.ctrl.purityDisplay);
  }

  @override
  void didUpdateWidget(covariant AddStockPurityStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_customCtrl.text != widget.ctrl.purityDisplay &&
        widget.ctrl.isCustomPurity) {
      _customCtrl.text = widget.ctrl.purityDisplay;
    }
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final ui = stockMetalUiFor(ctrl.selectedMetal);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;
          final mainPanel = _buildMainPanel(ctrl, ui);
          final sidePanel = _buildSidePanel(ctrl, ui);

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: mainPanel),
                const SizedBox(width: 18),
                SizedBox(width: 320, child: sidePanel),
              ],
            );
          }

          return Column(
            children: [mainPanel, const SizedBox(height: 18), sidePanel],
          );
        },
      ),
    );
  }

  // â”€â”€ MAIN PANEL â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildMainPanel(AddStockController ctrl, StockMetalUiData ui) {
    return Container(
      decoration: AddStockStyles.cardWithAccent(ui.accent),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: ui.gradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: ui.textOnGradient.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ui.logoAsset != null
                      ? Image.asset(
                          ui.logoAsset!,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        )
                      : Icon(ui.icon, color: ui.textOnGradient, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${ui.title} â€” Stock Intake',
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: ui.textOnGradient,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ui.helperLine,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 1.45,
                          color: ui.textOnGradient.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          Text('Purity / Karat Grade', style: AddStockStyles.pageTitle),
          const SizedBox(height: 6),
          Text(
            'Select the base purity for this batch. All items in this session will inherit this purity grade. This setting is locked once you proceed to item entry.',
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.6,
              color: AddStockColors.textBody,
            ),
          ),
          const SizedBox(height: 22),

          // Purity option chips
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: ctrl.purityOptions.map((option) {
              final isCustom = option == 'Custom';
              final isSelected =
                  isCustom ? ctrl.isCustomPurity : ctrl.purityDisplay == option;

              return InkWell(
                onTap: () => ctrl.setPurity(option),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ui.accent.withValues(alpha: 0.12)
                        : AddStockColors.inputBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? ui.accent : AddStockColors.cardBorder,
                      width: isSelected ? 1.6 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCustom ? Icons.edit_rounded : Icons.verified_rounded,
                        size: 16,
                        color:
                            isSelected ? ui.accent : AddStockColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        option,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color:
                              isSelected ? ui.accent : AddStockColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Custom purity text field
          if (ctrl.isCustomPurity) ...[
            const SizedBox(height: 18),
            Text('Enter Custom Purity', style: AddStockStyles.fieldLabel),
            const SizedBox(height: 8),
            TextField(
              controller: _customCtrl,
              onChanged: ctrl.setCustomPurity,
              style: AddStockStyles.fieldInput,
              decoration: InputDecoration(
                hintText: 'e.g. 18K Rose Gold, 950 Platinum',
                hintStyle: AddStockStyles.fieldHint,
                prefixIcon: Icon(
                  Icons.tune_rounded,
                  color: ui.accent,
                  size: 18,
                ),
                filled: true,
                fillColor: AddStockColors.inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AddStockColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AddStockColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: ui.accent, width: 1.5),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: ctrl.canProceedFromPurity ? ctrl.nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: ui.accent,
                disabledBackgroundColor: AddStockColors.inputBgLocked,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                'Continue to Item Entry',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ SIDE PANEL â€” Smart Stock Summary â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildSidePanel(AddStockController ctrl, StockMetalUiData ui) {
    return Container(
      decoration: AddStockStyles.cardDecoration,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: ui.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(Icons.inventory_2_rounded, size: 15, color: ui.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Current Stock by Purity',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AddStockColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Available ${ui.title} inventory, grouped by purity grade.',
            style: GoogleFonts.inter(
              fontSize: 11,
              height: 1.5,
              color: AddStockColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),

          // Stock table
          if (ctrl.isLoadingStockSummary)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ui.accent,
                  ),
                ),
              ),
            )
          else if (ctrl.purityStockSummary.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ui.softSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ui.accent.withValues(alpha: 0.14)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_outlined,
                    size: 28,
                    color: ui.accent.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No ${ui.title} stock on record.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AddStockColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Items added in this batch will appear here on your next session.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      height: 1.5,
                      color: AddStockColors.textHint,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: ctrl.purityStockSummary.entries.map((entry) {
                return _purityRow(
                  purity: entry.key,
                  totalGrams: entry.value,
                  accent: ui.accent,
                  surface: ui.softSurface,
                );
              }).toList(),
            ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AddStockColors.cardBorder),
          const SizedBox(height: 16),

          // Batch guidelines
          Text(
            'Batch Guidelines',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ui.accent,
            ),
          ),
          const SizedBox(height: 10),
          _guideline(
            'Purity is locked at batch level â€” select carefully before proceeding.',
            ui.accent,
          ),
          _guideline(
            'Each item row supports individual HSN code, HUID and quantity.',
            ui.accent,
          ),
          _guideline(
            'Enable "Same supplier for all" to pre-fill supplier across every row.',
            ui.accent,
          ),
        ],
      ),
    );
  }

  Widget _purityRow({
    required String purity,
    required double totalGrams,
    required Color accent,
    required Color surface,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              purity,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AddStockColors.textDark,
              ),
            ),
          ),
          Text(
            '${totalGrams.toStringAsFixed(3)} g',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _guideline(String text, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 11,
                height: 1.5,
                color: AddStockColors.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
