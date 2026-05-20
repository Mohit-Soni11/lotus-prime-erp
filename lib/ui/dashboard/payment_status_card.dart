// =============================================================================
// FILE        : payment_status_card.dart
// MODULE      : Dashboard / Payment Status
// LAYER       : UI
// DESCRIPTION : Premium Payment Status widget for Dashboard.
//
//               SECTIONS:
//               â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
//               â”‚  ðŸ’³ PAYMENT STATUS          [Today's summary]â”‚
//               â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”    â”‚
//               â”‚  â”‚ 5 Bills  â”‚ â”‚ â‚¹2.1L    â”‚ â”‚ â‚¹45K     â”‚    â”‚
//               â”‚  â”‚ Total    â”‚ â”‚ Collectedâ”‚ â”‚ Pending  â”‚    â”‚
//               â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜    â”‚
//               â”‚  [ALL] [DUE] [PAID]                         â”‚
//               â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”â”‚
//               â”‚  â”‚ ðŸ”µ Rajesh Kumar    â‚¹1,50,000  Dec 13    â”‚â”‚
//               â”‚  â”‚    #INV-1234    Paid:â‚¹1L Due:â‚¹50K PARTIALâ”‚
//               â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜â”‚
//               â”‚  ... more rows ...                           â”‚
//               â”‚  [â–¼ Show 2 More]                             â”‚
//               â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
//
//               ANIMATIONS:
//               â€¢ Header ShaderMask gold gradient
//               â€¢ Summary stat chips slide-in
//               â€¢ Filter tab switch â€” AnimatedContainer
//               â€¢ Each bill row â€” staggered entry (slide + fade)
//               â€¢ Row press â€” scale 0.98 + border highlight
//               â€¢ Show More/Less â€” AnimatedSize expand
//               â€¢ Shimmer loading state
//               â€¢ Customer tap â†’ navigate to profile
// =============================================================================

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../logic/dashboard/payment_status/payment_status_logic.dart';
import '../../models/dashboard/payment_bill_item.dart';
import '../../models/dashboard/payment_status_model.dart';
import '../../theme/dashboard/payment_status/payment_status_theme.dart';
import '../../constants/app_routes.dart';

class PaymentStatusCard extends StatefulWidget {
  final Function(String routeId) onNavigate;
  final Function(String routeId, {int? customerId})? onNavigateWithId;

  const PaymentStatusCard({
    super.key,
    required this.onNavigate,
    this.onNavigateWithId,
  });

  @override
  State<PaymentStatusCard> createState() => _PaymentStatusCardState();
}

class _PaymentStatusCardState extends State<PaymentStatusCard>
    with TickerProviderStateMixin {
  late final PaymentStatusLogic _logic;

  // Staggered entry for bill rows
  final List<AnimationController> _rowCtrl = [];
  final List<Animation<double>> _rowSlide = [];
  final List<Animation<double>> _rowFade = [];

  // Header entry animation
  late final AnimationController _headerCtrl;
  late final Animation<double> _headerFade;

  // Row press states
  final Set<int> _pressedRows = {};

  @override
  void initState() {
    super.initState();
    _logic = PaymentStatusLogic();
    _logic.addListener(_onDataChanged);

    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _headerFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));
    _headerCtrl.forward();
  }

  void _onDataChanged() {
    if (!mounted) return;
    // Naye rows ke liye animations setup karo
    _setupRowAnimations(_logic.data.filteredBills.length);
    setState(() {});
  }

  void _setupRowAnimations(int count) {
    // Purane controllers dispose karo
    for (final c in _rowCtrl) {
      c.dispose();
    }
    _rowCtrl.clear();
    _rowSlide.clear();
    _rowFade.clear();

    // Naye banao
    for (int i = 0; i < count; i++) {
      final ctrl = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 400));
      _rowCtrl.add(ctrl);
      _rowSlide.add(Tween<double>(begin: 15.0, end: 0.0)
          .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic)));
      _rowFade.add(Tween<double>(begin: 0.0, end: 1.0)
          .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut)));
    }

    // Staggered play
    for (int i = 0; i < count; i++) {
      Future.delayed(Duration(milliseconds: 60 * i), () {
        if (mounted && i < _rowCtrl.length) _rowCtrl[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _logic.removeListener(_onDataChanged);
    _logic.dispose();
    for (final c in _rowCtrl) {
      c.dispose();
    }
    _headerCtrl.dispose();
    super.dispose();
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PaymentStatusStyles.cardDecoration,
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(PaymentStatusStyles.cardBorderRadius),
        child: Stack(children: [
          // BG ambient glow
          const Positioned.fill(child: _AmbientGlows()),

          Padding(
            padding: PaymentStatusStyles.cardPadding,
            child: FadeTransition(
              opacity: _headerFade,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // â”€â”€ HEADER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  _buildHeader(),
                  const SizedBox(height: 16),

                  // â”€â”€ SUMMARY STATS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  _buildSummaryRow(),
                  const SizedBox(height: 16),

                  // â”€â”€ FILTER TABS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  _buildFilterTabs(),
                  const SizedBox(height: 14),

                  // â”€â”€ BILL ROWS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  _buildBillsList(),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // â”€â”€ HEADER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildHeader() {
    return Row(
      children: [
        // Gold icon
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: PaymentStatusColors.accentGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: PaymentStatusColors.accentGold.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: ShaderMask(
              shaderCallback: (b) =>
                  PaymentStatusColors.goldGradient.createShader(b),
              child: const Icon(PaymentStatusIcons.header,
                  size: 18, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Title
        ShaderMask(
          shaderCallback: (b) =>
              PaymentStatusColors.goldGradient.createShader(b),
          child: const Text('PAYMENT STATUS',
              style: PaymentStatusStyles.headerStyle),
        ),

        const Spacer(),

        // Live dot
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: PaymentStatusColors.paidAccent,
            boxShadow: [
              BoxShadow(
                  color: PaymentStatusColors.paidAccent,
                  blurRadius: 6,
                  spreadRadius: 1)
            ],
          ),
        ),
        const SizedBox(width: 5),
        const Text('LIVE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: PaymentStatusColors.paidAccent,
              letterSpacing: 0.8,
            )),
      ],
    );
  }

  // â”€â”€ SUMMARY STATS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildSummaryRow() {
    if (_logic.isLoading) return _buildSummaryShimmer();

    final s = _logic.data.summary;

    return Row(children: [
      _statChip(
        value: '${s.totalBills}',
        label: 'BILLS',
        color: PaymentStatusColors.accentGold,
      ),
      const SizedBox(width: 8),
      _statChip(
        value: PaymentStatusLogic.formatAmount(s.totalCollected),
        label: 'COLLECTED',
        color: PaymentStatusColors.paidAccent,
      ),
      const SizedBox(width: 8),
      _statChip(
        value: PaymentStatusLogic.formatAmount(s.totalPending),
        label: 'PENDING',
        color: s.totalPending > 0
            ? PaymentStatusColors.unpaidAccent
            : PaymentStatusColors.textSecondary,
      ),
    ]);
  }

  Widget _statChip(
      {required String value, required String label, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style:
                    PaymentStatusStyles.statValueStyle.copyWith(color: color)),
            const SizedBox(height: 2),
            Text(label, style: PaymentStatusStyles.statLabelStyle),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryShimmer() {
    return Row(
        children: List.generate(
            3,
            (i) => [
                  Expanded(
                      child: Shimmer.fromColors(
                    baseColor: PaymentStatusColors.shimmerBase,
                    highlightColor: PaymentStatusColors.shimmerHighlight,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: PaymentStatusColors.shimmerBase,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  )),
                  if (i < 2) const SizedBox(width: 8),
                ]).expand((e) => e).toList());
  }

  // â”€â”€ FILTER TABS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildFilterTabs() {
    final tabs = [
      (PaymentFilterTab.all, 'ALL'),
      (PaymentFilterTab.due, 'DUE'),
      (PaymentFilterTab.paid, 'PAID'),
    ];

    return Row(
      children: tabs.map((tab) {
        final isActive = _logic.data.activeTab == tab.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => _logic.setTab(tab.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: PaymentStatusStyles.tabHeight,
              decoration: PaymentStatusStyles.tabDecoration(isActive: isActive),
              child: Center(
                child: Text(
                  tab.$2,
                  style: PaymentStatusStyles.tabStyle.copyWith(
                    color: isActive
                        ? PaymentStatusColors.tabActiveText
                        : PaymentStatusColors.tabInactiveText,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // â”€â”€ BILLS LIST â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildBillsList() {
    if (_logic.isLoading) return _buildListShimmer();

    final bills = _logic.data.filteredBills;

    if (bills.isEmpty) {
      return _buildEmptyState();
    }

    // Kitne dikhane hain
    final showCount = (_logic.isExpanded ? 10 : 3).clamp(0, bills.length);
    final visibleBills = bills.take(showCount).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bill rows
        ...List.generate(visibleBills.length, (i) {
          final bill = visibleBills[i];
          if (i < _rowCtrl.length) {
            return AnimatedBuilder(
              animation: _rowCtrl[i],
              builder: (_, child) => Transform.translate(
                offset: Offset(0, _rowSlide[i].value),
                child: Opacity(opacity: _rowFade[i].value, child: child),
              ),
              child: _buildBillRow(bill, i),
            );
          }
          return _buildBillRow(bill, i);
        }),

        // Show More / Show Less button
        if (bills.length > 3) ...[
          const SizedBox(height: 10),
          _buildShowMoreBtn(bills.length - showCount),
        ],
      ],
    );
  }

  // â”€â”€ BILL ROW â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildBillRow(PaymentBillItem bill, int index) {
    final bool isPressed = _pressedRows.contains(bill.billId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressedRows.add(bill.billId)),
        onTapCancel: () => setState(() => _pressedRows.remove(bill.billId)),
        onTapUp: (_) {
          setState(() => _pressedRows.remove(bill.billId));
          // Customer profile navigate
          if (bill.customerId != null && widget.onNavigateWithId != null) {
            widget.onNavigateWithId!(
              AppRoutes.customerProfileRoute,
              customerId: bill.customerId,
            );
          } else {
            widget.onNavigate(AppRoutes.customerListRoute);
          }
        },
        child: AnimatedScale(
          scale: isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: PaymentStatusStyles.rowPadding,
            decoration: PaymentStatusStyles.rowDecoration(bill.status,
                isPressed: isPressed),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // â”€â”€ TOP ROW: Avatar + Name + Amount + Date â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Row(
                  children: [
                    // Avatar circle
                    Container(
                      width: PaymentStatusStyles.avatarSize,
                      height: PaymentStatusStyles.avatarSize,
                      decoration:
                          PaymentStatusStyles.avatarDecoration(bill.status),
                      child: Center(
                        child: Text(
                          bill.customerInitials,
                          style: PaymentStatusStyles.avatarStyle.copyWith(
                            color: PaymentStatusColors.accentFor(bill.status),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Name + Invoice
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill.customerName,
                            style: PaymentStatusStyles.customerNameStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Invoice #${bill.billNo}',
                            style: PaymentStatusStyles.billNoStyle,
                          ),
                        ],
                      ),
                    ),

                    // Amount + Date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          PaymentStatusLogic.formatAmountFull(bill.totalAmount),
                          style: PaymentStatusStyles.totalAmountStyle,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          PaymentStatusLogic.formatDate(bill.billDate),
                          style: PaymentStatusStyles.dateStyle,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // â”€â”€ BOTTOM ROW: Paid + Due + Status Badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Row(
                  children: [
                    // Paid
                    const Text('Paid: ',
                        style: PaymentStatusStyles.amountLabelStyle),
                    Text(
                      PaymentStatusLogic.formatAmountFull(bill.paidAmount),
                      style: PaymentStatusStyles.paidAmountStyle,
                    ),

                    const SizedBox(width: 12),

                    // Due
                    const Text('Due: ',
                        style: PaymentStatusStyles.amountLabelStyle),
                    Text(
                      PaymentStatusLogic.formatAmountFull(bill.dueAmount),
                      style: PaymentStatusStyles.dueAmountStyle(bill.dueAmount),
                    ),

                    const Spacer(),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration:
                          PaymentStatusStyles.badgeDecoration(bill.status),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PaymentStatusIcons.forStatus(bill.status),
                            size: 9,
                            color:
                                PaymentStatusColors.badgeTextFor(bill.status),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            PaymentStatusColors.badgeLabelFor(bill.status),
                            style: PaymentStatusStyles.badgeStyle.copyWith(
                              color:
                                  PaymentStatusColors.badgeTextFor(bill.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // â”€â”€ SHOW MORE BUTTON â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildShowMoreBtn(int remaining) {
    return GestureDetector(
      onTap: _logic.toggleExpanded,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: PaymentStatusColors.accentGold.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: PaymentStatusColors.accentGold.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _logic.isExpanded ? 'Show Less' : 'Show $remaining More',
              style: PaymentStatusStyles.showMoreStyle,
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: _logic.isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: const Icon(
                PaymentStatusIcons.chevron,
                size: 16,
                color: PaymentStatusColors.accentGold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ EMPTY STATE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildEmptyState() {
    final tab = _logic.data.activeTab;
    final msg = tab == PaymentFilterTab.paid
        ? 'No paid invoices are available yet.'
        : tab == PaymentFilterTab.due
            ? 'Koi due payment nahi! ðŸŽ‰'
            : 'Aaj koi bill nahi bana';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(children: [
          const Icon(PaymentStatusIcons.header,
              size: 32, color: PaymentStatusColors.textMuted),
          const SizedBox(height: 8),
          Text(msg, style: PaymentStatusStyles.emptyStyle),
        ]),
      ),
    );
  }

  // â”€â”€ SHIMMER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildListShimmer() {
    return Column(
      children: List.generate(
          3,
          (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Shimmer.fromColors(
                  baseColor: PaymentStatusColors.shimmerBase,
                  highlightColor: PaymentStatusColors.shimmerHighlight,
                  child: Container(
                    height: 88,
                    decoration: BoxDecoration(
                      color: PaymentStatusColors.shimmerBase,
                      borderRadius: BorderRadius.circular(
                          PaymentStatusStyles.rowBorderRadius),
                    ),
                  ),
                ),
              )),
    );
  }
}

// â”€â”€ Ambient Glows â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _AmbientGlows extends StatelessWidget {
  const _AmbientGlows();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(children: [
        Positioned(
          top: -50,
          right: -40,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PaymentStatusColors.accentGold.withValues(alpha: 0.04),
              boxShadow: [
                BoxShadow(
                    color:
                        PaymentStatusColors.accentGold.withValues(alpha: 0.06),
                    blurRadius: 80,
                    spreadRadius: 10)
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -30,
          left: -20,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PaymentStatusColors.accentGold.withValues(alpha: 0.03),
              boxShadow: [
                BoxShadow(
                    color:
                        PaymentStatusColors.accentGold.withValues(alpha: 0.04),
                    blurRadius: 50,
                    spreadRadius: 5)
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
