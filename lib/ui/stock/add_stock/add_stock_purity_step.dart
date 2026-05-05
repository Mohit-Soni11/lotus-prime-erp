import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/logic/stock/add_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';
import 'stock_metal_ui.dart';

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

  Widget _buildMainPanel(AddStockController ctrl, StockMetalUiData ui) {
    return Container(
      decoration: AddStockStyles.cardWithAccent(ui.accent),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(ui.icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${ui.title} batch setup',
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ui.helperLine,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 1.45,
                          color: Colors.white.withOpacity(0.92),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Purity / Karat', style: AddStockStyles.pageTitle),
          const SizedBox(height: 6),
          Text(
            'Is batch ke liye base purity choose karo. Yeh selection saari rows par apply hogi aur later inventory save ke saath persist hogi.',
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.6,
              color: AddStockColors.textBody,
            ),
          ),
          const SizedBox(height: 22),
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
                        ? ui.accent.withOpacity(0.12)
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
          if (ctrl.isCustomPurity) ...[
            const SizedBox(height: 18),
            Text(
              AddStockStrings.purityCustomLabel,
              style: AddStockStyles.fieldLabel,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customCtrl,
              onChanged: ctrl.setCustomPurity,
              style: AddStockStyles.fieldInput,
              decoration: InputDecoration(
                hintText: AddStockStrings.purityCustomHint,
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
                  borderSide: const BorderSide(
                    color: AddStockColors.cardBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AddStockColors.cardBorder,
                  ),
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
                AddStockStrings.btnNextItems,
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

  Widget _buildSidePanel(AddStockController ctrl, StockMetalUiData ui) {
    return Container(
      decoration: AddStockStyles.cardDecoration,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Batch Snapshot',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AddStockColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          _sideStat('Metal', ui.title),
          const SizedBox(height: 10),
          _sideStat('Suggested HSN', ctrl.defaultHsnCode),
          const SizedBox(height: 10),
          _sideStat(
            'Purity selection',
            ctrl.purityDisplay.trim().isEmpty
                ? 'Not selected'
                : ctrl.purityDisplay,
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ui.softSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ui.accent.withOpacity(0.14)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips before you continue',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ui.accent,
                  ),
                ),
                const SizedBox(height: 10),
                _tip(
                  'Purity batch-level par lock hogi, isliye sahi option lo.',
                ),
                _tip(
                  'Aage har row mein HSN, HUID, pricing aur quantity save kar paoge.',
                ),
                _tip(
                  'Supplier same-for-all mode on rahe to row entry fast ho jayegi.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideStat(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AddStockColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: AddStockColors.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _tip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AddStockColors.brandGold,
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
