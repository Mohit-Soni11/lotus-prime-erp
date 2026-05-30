// ==========================================
// FILE: pos_hold_list_dialog.dart
// TYPE: UI Component
// DESCRIPTION: Displays held POS bills and supports restore or delete actions.
// ==========================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import '../../../logic/sales & orders/sales pos/pos_billing_controller.dart';
import '../../../models/sales & orders/sales_pos_models/pos_hold_bill_model.dart';

class PosHoldListDialog extends StatefulWidget {
  final PosBillingController ctrl;
  const PosHoldListDialog({super.key, required this.ctrl});

  @override
  State<PosHoldListDialog> createState() => _PosHoldListDialogState();
}

class _PosHoldListDialogState extends State<PosHoldListDialog>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  String? _deletingId;

  @override
  void initState() {
    super.initState();
    _headerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _headerFade =
        CurvedAnimation(parent: _headerAnimCtrl, curve: Curves.easeOut);
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero).animate(
            CurvedAnimation(parent: _headerAnimCtrl, curve: Curves.easeOut));
    _headerAnimCtrl.forward();
  }

  @override
  void dispose() {
    _headerAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmAndDelete(
      BuildContext context, PosHoldBillModel hold) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SalesPosColors.shellBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Discard Invoice?",
            style: TextStyle(
                color: SalesPosColors.shellTextTitle,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
        content: Text(
          "This will permanently discard the parked invoice for "
          "${hold.customerName.isEmpty ? 'Walk-in Customer' : hold.customerName}.",
          style: const TextStyle(
              color: SalesPosColors.shellTextTitle,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel",
                style: TextStyle(
                    color: SalesPosColors.shellTextMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SalesPosColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Discard",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _deletingId = hold.holdId);
      await Future.delayed(const Duration(milliseconds: 300));

      widget.ctrl.deleteHeldBill(hold.holdId);

      if (mounted) setState(() => _deletingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: _buildDialogBody(context),
    );
  }

  Widget _buildDialogBody(BuildContext context) {
    return Container(
      width: 540,
      constraints: const BoxConstraints(maxHeight: 680),
      decoration: BoxDecoration(
        color: SalesPosColors.shellBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SalesPosColors.brandGold.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.50),
            blurRadius: 48,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: SalesPosColors.brandGold.withValues(alpha: 0.06),
            blurRadius: 80,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const _GoldDivider(),
            Flexible(
              child: ListenableBuilder(
                listenable: widget.ctrl,
                builder: (context, _) => _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerFade,
      child: SlideTransition(
        position: _headerSlide,
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 14, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SalesPosColors.brandGold.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: SalesPosColors.brandGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: SalesPosColors.brandGold.withValues(alpha: 0.30)),
                ),
                child: const Icon(Icons.pause_circle_outline_rounded,
                    color: SalesPosColors.brandGold, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "PARKED INVOICES",
                      style: TextStyle(
                        color: SalesPosColors.shellTextTitle,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "${widget.ctrl.heldBills.length} bill${widget.ctrl.heldBills.length == 1 ? '' : 's'} on hold",
                      style: const TextStyle(
                          color: SalesPosColors.shellTextMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (widget.ctrl.heldBills.isNotEmpty)
                // PERFECTLY CENTERED BADGE
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: SalesPosColors.brandGold,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.ctrl.heldBills.length.toString(),
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        height: 1.0), // height 1.0 ensures vertical centering
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: SalesPosColors.shellTextMuted, size: 24),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor:
                      SalesPosColors.bodyBorder.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (widget.ctrl.heldBills.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      shrinkWrap: true,
      itemCount: widget.ctrl.heldBills.length,
      itemBuilder: (context, index) {
        final hold = widget.ctrl.heldBills[index];
        return _AnimatedHoldCard(
          key: ValueKey(hold.holdId),
          hold: hold,
          index: index,
          isDeleting: _deletingId == hold.holdId,
          onResume: () {
            widget.ctrl.resumeBill(hold.holdId);
            Navigator.pop(context);
          },
          onDelete: () => _confirmAndDelete(context, hold),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: SalesPosColors.brandGold.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                  color: SalesPosColors.brandGold.withValues(alpha: 0.20),
                  width: 1.5),
            ),
            child: const Icon(Icons.inbox_outlined,
                color: SalesPosColors.brandGold, size: 36),
          ),
          const SizedBox(height: 18),
          const Text(
            "No Parked Invoices",
            style: TextStyle(
                color: SalesPosColors.shellTextTitle,
                fontSize: 18,
                fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          const Text(
            "Bills you put on hold will appear here.\nUse HOLD button to park an active invoice.",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: SalesPosColors.shellTextMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.6),
          ),
          const SizedBox(height: 28),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: SalesPosColors.brandGold,
              side:
                  const BorderSide(color: SalesPosColors.brandGold, width: 2.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            ),
            child: const Text("Back to Billing",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ANIMATED HOLD CARD WIDGET
// ==========================================
class _AnimatedHoldCard extends StatefulWidget {
  final PosHoldBillModel hold;
  final int index;
  final bool isDeleting;
  final VoidCallback onResume;
  final VoidCallback onDelete;

  const _AnimatedHoldCard({
    super.key,
    required this.hold,
    required this.index,
    required this.isDeleting,
    required this.onResume,
    required this.onDelete,
  });

  @override
  State<_AnimatedHoldCard> createState() => _AnimatedHoldCardState();
}

class _AnimatedHoldCardState extends State<_AnimatedHoldCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 380 + widget.index * 60),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: widget.isDeleting ? 0.0 : 1.0,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 250),
            scale: widget.isDeleting ? 0.96 : 1.0,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: _buildCard(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    final hold = widget.hold;
    final String formattedTime = DateFormat('hh:mm a').format(hold.holdTime);
    final String formattedDate = DateFormat('d MMM').format(hold.holdTime);
    final String displayName =
        hold.customerName.isEmpty ? "Walk-in Customer" : hold.customerName;
    final bool hasPhone = hold.customerMobile.isNotEmpty;
    final bool isWalkIn = hold.customerName.isEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _isHovered
                ? SalesPosColors.brandGold.withValues(alpha: 0.5)
                : SalesPosColors.bodyBorder,
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _isHovered
                ? SalesPosColors.brandGold.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.10),
            blurRadius: _isHovered ? 12 : 8,
            offset: Offset(0, _isHovered ? 5 : 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTimeStrip(formattedTime, formattedDate),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isWalkIn
                                  ? SalesPosColors.bodyTextMuted.withValues(
                                      alpha:
                                          0.12) // Uses muted body text.
                                  : SalesPosColors.brandGold
                                      .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                isWalkIn ? "?" : displayName[0].toUpperCase(),
                                style: TextStyle(
                                  color: isWalkIn
                                      ? SalesPosColors.bodyTextMain
                                      : SalesPosColors
                                          .brandGold, // Uses primary body text.
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: SalesPosColors
                                        .bodyTextMain, // Uses primary title color.
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                if (hasPhone)
                                  Text(
                                    hold.customerMobile,
                                    // Made phone number strictly dark/black
                                    style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Item count pill colors explicitly set to dark body text
                          _buildStatPill(
                            icon: Icons.shopping_bag_outlined,
                            label:
                                "${hold.totalItems} item${hold.totalItems == 1 ? '' : 's'}",
                            bgColor: SalesPosColors.bodyBg,
                            textColor: SalesPosColors.bodyTextMain,
                            iconColor: SalesPosColors.bodyTextMain,
                          ),
                          const SizedBox(width: 8),
                          _buildStatPill(
                            icon: Icons.currency_rupee_rounded,
                            label: hold.grandTotal.toStringAsFixed(0),
                            bgColor:
                                SalesPosColors.success.withValues(alpha: 0.10),
                            textColor: SalesPosColors.success,
                            iconColor: SalesPosColors.success,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _buildActionColumn(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeStrip(String time, String date) {
    return Container(
      width: 65,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            SalesPosColors.brandGold.withValues(alpha: 0.18),
            SalesPosColors.brandGold.withValues(alpha: 0.07),
          ],
        ),
        border: const Border(
            right: BorderSide(color: SalesPosColors.bodyBorder, width: 1.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.access_time_rounded,
              color: SalesPosColors.brandGold, size: 18),
          const SizedBox(height: 6),
          Text(
            time,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: SalesPosColors.brandGold,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1.3),
          ),
          const SizedBox(height: 3),
          // Date is now bold and dark
          Text(date,
              style: const TextStyle(
                  color: SalesPosColors.bodyTextMain,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border:
            Border.all(color: SalesPosColors.bodyBorder.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: textColor, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildActionColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 10, 6),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: SalesPosColors.brandGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: Size.zero,
              elevation: _isHovered ? 4 : 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text("RESUME",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8)),
            onPressed: widget.onResume,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 10, 10),
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: SalesPosColors.danger,
              side: BorderSide(
                  color: SalesPosColors.danger.withValues(alpha: 0.70),
                  width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            label: const Text("DISCARD",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8)),
            onPressed: widget.onDelete,
          ),
        ),
      ],
    );
  }
}

class _GoldDivider extends StatelessWidget {
  const _GoldDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2.0,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          SalesPosColors.brandGold.withValues(alpha: 0.03),
          SalesPosColors.brandGold.withValues(alpha: 0.40),
          SalesPosColors.brandGold.withValues(alpha: 0.03),
        ]),
      ),
    );
  }
}
