// =============================================================================
// FILE        : purchase_invoice_status_bar.dart
// MODULE      : Purchase Entry
// LAYER       : UI
// DESCRIPTION : Voucher number, date & time bar. Matching Sales POS design.
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/purchase/purchase_entry/purchase_entry_theme.dart';
import '../../../logic/purchase/purchase_entry_controller.dart';
import '../../../models/purchase/purchase_enums/purchase_enums.dart';
import 'package:lotus_erp/logic/dashboard/date_card/date_card_logic.dart';


class PurchaseInvoiceStatusBar extends StatefulWidget {
  final PurchaseEntryController ctrl;

  const PurchaseInvoiceStatusBar({super.key, required this.ctrl});

  @override
  State<PurchaseInvoiceStatusBar> createState() =>
      _PurchaseInvoiceStatusBarState();
}

class _PurchaseInvoiceStatusBarState extends State<PurchaseInvoiceStatusBar>
    with SingleTickerProviderStateMixin {
  late final DateCardLogic _dateLogic;
  late final AnimationController _slideCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _dateLogic = DateCardLogic();
    _dateLogic.init();

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnim  = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _dateLogic.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  bool get _isGst =>
      widget.ctrl.taxType == PurchaseTaxType.gst;

  Color get _accent =>
      _isGst ? PurchaseEntryColors.success : PurchaseEntryColors.purchaseAccent;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.ctrl,
      builder: (context, _) {
        return FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildCard(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: PurchaseEntryColors.bodyPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PurchaseEntryColors.bodyBorder),
        boxShadow: const [
          BoxShadow(
              color: PurchaseEntryColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2)),
          BoxShadow(
              color: PurchaseEntryColors.shadowDark,
              blurRadius: 20,
              offset: Offset(0, 6)),
        ],
      ),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HEADING ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _accentLine(20, 1.0),
                        const SizedBox(height: 3),
                        _accentLine(13, 0.45),
                        const SizedBox(height: 3),
                        _accentLine(7, 0.18),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          PurchaseEntryStrings.invoiceNumber,
                          style: PurchaseEntryStyles.highVisHeader,
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 260),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _isGst
                                ? PurchaseEntryColors.success
                                : PurchaseEntryColors.textDark,
                          ),
                          child: Text(
                            _isGst ? 'GST Purchase' : 'Normal Purchase',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(width: 40),

                // Status pill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isGst
                        ? PurchaseEntryColors.success.withOpacity(0.07)
                        : PurchaseEntryColors.bodyBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isGst
                          ? PurchaseEntryColors.success.withOpacity(0.35)
                          : PurchaseEntryColors.bodyBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isGst
                              ? PurchaseEntryColors.success
                              : PurchaseEntryColors.purchaseAccent,
                        ),
                      ),
                      const SizedBox(width: 6),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 260),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: _isGst
                              ? PurchaseEntryColors.success
                              : PurchaseEntryColors.purchaseAccent,
                        ),
                        child: Text(_isGst ? 'GST PURCHASE' : 'PURCHASE'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Divider
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 16),
              color: PurchaseEntryColors.bodyBorder,
            ),

            // CONTENT ROW
            SizedBox(
              height: 52,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon box
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _accent.withOpacity(0.25)),
                    ),
                    child: Icon(
                      PurchaseEntryIcons.invoiceOutline,
                      color: _accent, size: 24,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Voucher number
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VOUCHER NO.',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                          color: PurchaseEntryColors.textDark,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.ctrl.formattedPurchaseNo,
                        style: TextStyle(
                          color: _accent,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          height: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 24),

                  // Vertical rule
                  Container(
                    width: 1, height: 34,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          PurchaseEntryColors.bodyBorder,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Date + Time
                  StreamBuilder<DateCardModel>(
                    stream: _dateLogic.timeStream,
                    initialData: _dateLogic.initialData,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      return _buildDateTimeRow(snapshot.data!);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeRow(DateCardModel data) {
    final parts     = data.time.split(':');
    final cleanTime = parts.length >= 2 ? '${parts[0]} : ${parts[1]}' : data.time;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip(
          icon: PurchaseEntryIcons.calendarDate,
          iconColor: PurchaseEntryColors.textDark,
          label: 'DATE',
          value: data.date.toUpperCase(),
          valueColor: PurchaseEntryColors.textDark,
          fontSize: 13,
          bg: PurchaseEntryColors.bodyBg,
          border: PurchaseEntryColors.bodyBorder,
        ),
        const SizedBox(width: 8),
        Container(
          width: 4, height: 4,
          decoration: BoxDecoration(
            color: PurchaseEntryColors.textMuted,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        _chip(
          icon: PurchaseEntryIcons.clockTime,
          iconColor: PurchaseEntryColors.success,
          label: 'TIME',
          value: cleanTime,
          valueColor: PurchaseEntryColors.success,
          fontSize: 14,
          bg: PurchaseEntryColors.success.withOpacity(0.07),
          border: PurchaseEntryColors.success.withOpacity(0.25),
        ),
      ],
    );
  }

  Widget _chip({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
    required double fontSize,
    required Color bg,
    required Color border,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: iconColor.withOpacity(0.8),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _accentLine(double width, double opacity) => Container(
        width: width, height: 3,
        decoration: BoxDecoration(
          color: PurchaseEntryColors.purchaseAccent.withOpacity(opacity),
          borderRadius: BorderRadius.circular(2),
        ),
      );
}
