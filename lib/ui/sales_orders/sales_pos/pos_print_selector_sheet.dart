// ==========================================
// FILE: pos_print_selector_sheet.dart
// TYPE: Smart UI Component (Bottom Sheet)
// DESCRIPTION: Premium print format selector with live size thumbnails,
//              copy count selector, and duplicate stamp toggle.
// Live PDF Preview update
// Invisible Copy Count Text & Premium UI Polish
// ==========================================

import 'package:flutter/material.dart';
import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import '../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import '../../../logic/sales_orders/sales_pos/pos_invoice_controller.dart';

class PosPrintSelectorSheet extends StatefulWidget {
  final PosInvoiceController invoiceCtrl;
  final VoidCallback onPrint;

  const PosPrintSelectorSheet({
    super.key,
    required this.invoiceCtrl,
    required this.onPrint,
  });

  static Future<void> show(
    BuildContext context, {
    required PosInvoiceController invoiceCtrl,
    required VoidCallback onPrint,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PosPrintSelectorSheet(
        invoiceCtrl: invoiceCtrl,
        onPrint: onPrint,
      ),
    );
  }

  @override
  State<PosPrintSelectorSheet> createState() => _PosPrintSelectorSheetState();
}

class _PosPrintSelectorSheetState extends State<PosPrintSelectorSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _slideAnim;

  late PrintFormat _selected;
  int _copies = 1;
  bool _duplicateStamp = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.invoiceCtrl.selectedFormat;
    _copies = widget.invoiceCtrl.printCopies;
    _duplicateStamp = widget.invoiceCtrl.includeDuplicateStamp;

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(_slideAnim),
      child: Container(
        decoration: const BoxDecoration(
          color: SalesPosColors.shellBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            _buildHeader(),
            const _GoldDivider(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormatGrid(),
                    const SizedBox(height: 20),
                    _buildPreviewThumbnail(),
                    const SizedBox(height: 20),
                    _buildAdvancedOptions(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            const _GoldDivider(),
            _buildActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: SalesPosColors.bodyBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 16, 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: SalesPosColors.brandGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: SalesPosColors.brandGold.withValues(alpha: 0.30)),
              ),
              child: const Icon(Icons.print_rounded,
                  color: SalesPosColors.brandGold, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("SELECT PRINT FORMAT",
                        style: TextStyle(
                            color: SalesPosColors.shellTextTitle,
                            fontSize: SalesPosStyles.fontBody,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0)),
                    SizedBox(height: 2),
                    Text("Choose paper size for your printer",
                        style: TextStyle(
                            color: SalesPosColors.shellTextMuted,
                            fontSize: SalesPosStyles.fontCaption)),
                  ]),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: SalesPosColors.shellTextMuted),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );

  Widget _buildFormatGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("PAPER SIZE",
            style: TextStyle(
                color: SalesPosColors.shellTextMuted,
                fontSize: SalesPosStyles.fontCaption,
                fontWeight: FontWeight.w700,
                letterSpacing: 0)),
        const SizedBox(height: 10),
        Row(
          children: PrintFormat.values
              .map((fmt) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: fmt == PrintFormat.thermal2inch ? 0 : 10),
                      child: _FormatOptionCard(
                        format: fmt,
                        isSelected: _selected == fmt,
                        onTap: () {
                          setState(() => _selected = fmt);
                          widget.invoiceCtrl.switchFormat(fmt);
                        },
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPreviewThumbnail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("SIZE PREVIEW",
            style: TextStyle(
                color: SalesPosColors.shellTextMuted,
                fontSize: SalesPosStyles.fontCaption,
                fontWeight: FontWeight.w700,
                letterSpacing: 0)),
        const SizedBox(height: 10),
        Container(
          height: 130,
          decoration: BoxDecoration(
              color: SalesPosColors.bodyBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SalesPosColors.bodyBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: _PaperSizeThumbnail(
                  key: ValueKey(_selected), format: _selected),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("PRINT OPTIONS",
            style: TextStyle(
                color: SalesPosColors.shellTextMuted,
                fontSize: SalesPosStyles.fontCaption,
                fontWeight: FontWeight.w700,
                letterSpacing: 0)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: SalesPosColors.bodyPanelBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SalesPosColors.bodyBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.file_copy_outlined,
                  color: SalesPosColors.bodyTextMain, size: 18),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Number of copies",
                          style: TextStyle(
                              color: SalesPosColors.bodyTextMain,
                              fontSize: SalesPosStyles.fontLabel,
                              fontWeight: FontWeight.w700)),
                      Text("Print multiple copies at once",
                          style: TextStyle(
                              color: SalesPosColors.shellTextMuted,
                              fontSize: SalesPosStyles.fontCaption)),
                    ]),
              ),
              _CopyStepper(
                value: _copies,
                onChanged: (v) {
                  setState(() => _copies = v);
                  widget.invoiceCtrl.updatePrintOptions(
                      copies: _copies, duplicate: _duplicateStamp);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: SalesPosColors.bodyPanelBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SalesPosColors.bodyBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.approval_outlined,
                  color: SalesPosColors.bodyTextMain, size: 18),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Mark as DUPLICATE",
                          style: TextStyle(
                              color: SalesPosColors.bodyTextMain,
                              fontSize: SalesPosStyles.fontLabel,
                              fontWeight: FontWeight.w700)),
                      Text("Adds a 'Duplicate Copy' watermark",
                          style: TextStyle(
                              color: SalesPosColors.shellTextMuted,
                              fontSize: SalesPosStyles.fontCaption)),
                    ]),
              ),
              Switch(
                value: _duplicateStamp,
                onChanged: (v) {
                  setState(() => _duplicateStamp = v);
                  widget.invoiceCtrl.updatePrintOptions(
                      copies: _copies, duplicate: _duplicateStamp);
                },
                activeThumbColor: SalesPosColors.brandGold,
                inactiveThumbColor: SalesPosColors.shellTextMuted,
                inactiveTrackColor: SalesPosColors.bodyBorder,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SalesPosColors.shellTextMuted,
                  side: const BorderSide(color: SalesPosColors.bodyBorder),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("CANCEL",
                    style: TextStyle(
                        fontWeight: FontWeight.w800, letterSpacing: 0)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.invoiceCtrl.selectedFormat = _selected;
                  widget.invoiceCtrl.printCopies = _copies;
                  widget.invoiceCtrl.includeDuplicateStamp = _duplicateStamp;
                  Navigator.pop(context);
                  widget.onPrint();
                },
                icon: const Icon(Icons.print_rounded,
                    color: Colors.white, size: 20),
                label: Text(
                    "PRINT NOW  ($_copies ${_copies == 1 ? 'COPY' : 'COPIES'})",
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: SalesPosStyles.fontLabel,
                        letterSpacing: 0)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SalesPosColors.brandGold,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormatOptionCard extends StatelessWidget {
  final PrintFormat format;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatOptionCard({
    required this.format,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? SalesPosColors.brandGold.withValues(alpha: 0.10)
              : SalesPosColors.bodyPanelBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? SalesPosColors.brandGold
                : SalesPosColors.bodyBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
          // Premium Selection Shadow added
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: SalesPosColors.brandGold.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(format.icon,
                color: isSelected
                    ? SalesPosColors.brandGold
                    : SalesPosColors.shellTextMuted,
                size: 24),
            const SizedBox(height: 6),
            Text(
              format.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected
                    ? SalesPosColors.brandGold
                    : SalesPosColors.shellTextMuted,
                fontSize: SalesPosStyles.fontCaption,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                height: 1.3,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: SalesPosColors.brandGold,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaperSizeThumbnail extends StatelessWidget {
  final PrintFormat format;

  const _PaperSizeThumbnail({super.key, required this.format});

  @override
  Widget build(BuildContext context) {
    double width, height;
    switch (format) {
      case PrintFormat.a4:
        width = 56;
        height = 79;
        break;
      case PrintFormat.thermal3inch:
        width = 28;
        height = 90;
        break;
      case PrintFormat.thermal2inch:
        width = 20;
        height = 90;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
                color: SalesPosColors.brandGold.withValues(alpha: 0.6),
                width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(2, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Column(
              children: List.generate(
                format == PrintFormat.a4 ? 6 : 8,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Container(
                    height: 2,
                    width: i == 0
                        ? double.infinity
                        : (i % 3 == 0 ? width * 0.5 : width * 0.8),
                    color: i == 0
                        ? Colors.black.withValues(alpha: 0.7)
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          format.subtitle.split(' - ').first.trim(),
          style: const TextStyle(
              color: SalesPosColors.shellTextMuted,
              fontSize: SalesPosStyles.fontCaption),
        ),
      ],
    );
  }
}

class _CopyStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _CopyStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepBtn(
          icon: Icons.remove,
          onTap: value > 1 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 36,
          child: Text(
            value.toString(),
            textAlign: TextAlign.center,
            // Selection text uses brand gold and a larger font.
            style: const TextStyle(
                color: SalesPosColors.brandGold,
                fontSize: SalesPosStyles.fontTitle,
                fontWeight: FontWeight.w900),
          ),
        ),
        _StepBtn(
          icon: Icons.add,
          onTap: value < 5 ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled
              ? SalesPosColors.brandGold.withValues(alpha: 0.12)
              : SalesPosColors.bodyBorder.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? SalesPosColors.brandGold.withValues(alpha: 0.40)
                : SalesPosColors.bodyBorder,
          ),
        ),
        child: Icon(icon,
            size: 16,
            color: enabled
                ? SalesPosColors.brandGold
                : SalesPosColors.shellTextMuted),
      ),
    );
  }
}

class _GoldDivider extends StatelessWidget {
  const _GoldDivider();

  @override
  Widget build(BuildContext context) => Container(
        height: 1.5,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            SalesPosColors.brandGold.withValues(alpha: 0.03),
            SalesPosColors.brandGold.withValues(alpha: 0.30),
            SalesPosColors.brandGold.withValues(alpha: 0.03),
          ]),
        ),
      );
}
