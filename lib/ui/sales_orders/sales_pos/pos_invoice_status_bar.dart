// ==========================================
// FILE: pos_invoice_status_bar.dart
// TYPE: Smart UI Component (UPGRADED)
// AUTHOR: Senior System Architect
// DESCRIPTION: Invoice status box  -  redesigned to match PosTopControlBar.
//               Strictly mapped Colors, Icons, and TextStyles.
//               Compact wrap-content layout (zero dead space).
// ==========================================

import 'package:flutter/material.dart';

import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import '../../../logic/sales_orders/sales_pos/pos_billing_controller.dart';
import '../../../logic/dashboard/date_card/date_card_logic.dart';
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';

class PosInvoiceStatusBar extends StatefulWidget {
  final PosBillingController ctrl;

  const PosInvoiceStatusBar({
    super.key,
    required this.ctrl,
  });

  @override
  State<PosInvoiceStatusBar> createState() => _PosInvoiceStatusBarState();
}

class _PosInvoiceStatusBarState extends State<PosInvoiceStatusBar>
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
    _fadeAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _dateLogic.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  bool get _isGst => widget.ctrl.billType == BillType.gst;
  Color get _accentColor =>
      _isGst ? SalesPosColors.success : SalesPosColors.brandGold;

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

  //  MAIN CARD
  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SalesPosColors.bodyBorder),
        boxShadow: const [
          BoxShadow(
              color: SalesPosColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2)),
          BoxShadow(
              color: SalesPosColors.shadowDark,
              blurRadius: 20,
              offset: Offset(0, 6)),
        ],
      ),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            //
            // HEADING ROW
            //
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // LEFT PART: Accent Lines & Title
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                          "INVOICE NUMBER",
                          style: SalesPosStyles.highVisHeader,
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 260),
                          style: TextStyle(
                            fontSize: SalesPosStyles.fontCaption,
                            fontWeight: FontWeight.bold,
                            color: _isGst
                                ? SalesPosColors.success
                                : SalesPosColors.textDark,
                          ),
                          child: Text(_isGst ? "GST Invoice" : "Sales Invoice"),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(width: 40),

                // RIGHT PART: Status pill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isGst
                        ? SalesPosColors.success.withValues(alpha: 0.07)
                        : SalesPosColors.bodyBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isGst
                          ? SalesPosColors.success.withValues(alpha: 0.35)
                          : SalesPosColors.bodyBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isGst
                              ? SalesPosColors.success
                              : SalesPosColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 260),
                        style: TextStyle(
                          fontSize: SalesPosStyles.fontCaption,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                          color: _isGst
                              ? SalesPosColors.success
                              : SalesPosColors.textDark,
                        ),
                        child: Text(_isGst ? "GST INVOICE" : "SALES INVOICE"),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            //  Divider
            Container(
              height: 1,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 16),
              color: SalesPosColors.bodyBorder,
            ),

            //
            // CONTENT ROW
            //
            SizedBox(
              height: 52,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  //  Invoice icon box
                  _buildInvoiceIconBox(),

                  const SizedBox(width: 16),

                  //  Invoice number block
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        SalesPosStrings.lblInvoiceNo.trim(),
                        style: const TextStyle(
                          fontSize: SalesPosStyles.fontCaption,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                          color: SalesPosColors.textDark,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.ctrl.formattedInvoice,
                        style: TextStyle(
                          color:
                              _isGst ? _accentColor : SalesPosColors.textDark,
                          fontSize: SalesPosStyles.fontSection,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                          height: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 24),

                  //  Vertical rule
                  Container(
                    width: 1,
                    height: 34,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          SalesPosColors.bodyBorder,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  //  Date + Time chips
                  StreamBuilder<DateCardModel>(
                    stream: _dateLogic.timeStream,
                    initialData: _dateLogic.initialData,
                    builder: (context, snapshot) {
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

  Widget _buildInvoiceIconBox() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accentColor.withValues(alpha: 0.25)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 8,
            right: 8,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _accentColor.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons
                  .receipt_long_outlined, // Safe fallback, update to SalesPosIcons.invoiceOutline if available
              color: _accentColor,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeRow(DateCardModel data) {
    final timeParts = data.time.split(':');
    final cleanTime =
        timeParts.length >= 2 ? '${timeParts[0]} : ${timeParts[1]}' : data.time;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildChip(
          icon: SalesPosIcons.calendarDate,
          iconColor: SalesPosColors.textDark,
          subLabel: "DATE",
          value: data.date.toUpperCase(),
          valueColor: SalesPosColors.textDark,
          valueFontSize: 13,
          chipBg: SalesPosColors.bodyBg,
          chipBorder: SalesPosColors.bodyBorder,
        ),
        const SizedBox(width: 8),
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: SalesPosColors.bodyTextMuted,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        _buildChip(
          icon: SalesPosIcons.clockTime,
          iconColor: SalesPosColors.success,
          subLabel: "TIME",
          value: cleanTime,
          valueColor: SalesPosColors.success,
          valueFontSize: 14,
          chipBg: SalesPosColors.success.withValues(alpha: 0.07),
          chipBorder: SalesPosColors.success.withValues(alpha: 0.25),
        ),
      ],
    );
  }

  Widget _buildChip({
    required IconData icon,
    required Color iconColor,
    required String subLabel,
    required String value,
    required Color valueColor,
    required double valueFontSize,
    required Color chipBg,
    required Color chipBorder,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: chipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
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
                subLabel,
                style: TextStyle(
                  color: iconColor.withValues(alpha: 0.8),
                  fontSize: SalesPosStyles.fontCaption,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
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
        width: width,
        height: 3,
        decoration: BoxDecoration(
          color: SalesPosColors.brandGold.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(2),
        ),
      );
}
