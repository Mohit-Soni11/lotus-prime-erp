// =============================================================================
// FILE        : notice_auction_screen.dart
// MODULE      : Girvi / Pawn
// LAYER       : UI / Screen
// DESCRIPTION : Notice & Auction management screen.
//               Lists all OVERDUE girvi loans.
//               Actions: Send Notice, Mark Auctioned.
//               Shows days overdue, overdue interest, notice history.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../database/db/app_database.dart';
import '../../../logic/girvi/girvi_controllers.dart';
import '../../../models/girvi/girvi_enums.dart';
import '../../../models/girvi/girvi_loan_model.dart';
import '../../../repositories/girvi/girvi_repository.dart';
import '../../../theme/girvi/girvi_theme.dart';
import '../shared/girvi_shared_widgets.dart';

class NoticeAuctionScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const NoticeAuctionScreen({super.key, this.onBack});

  @override
  State<NoticeAuctionScreen> createState() => _NoticeAuctionScreenState();
}

class _NoticeAuctionScreenState extends State<NoticeAuctionScreen> {

  final AppDatabase      _db   = AppDatabase();
  late final GirviRepository    _repo;
  late GirviListController       _listCtrl;

  List<GirviLoanWithCustomer> _overdueLoans = [];
  bool   _loading = true;
  String? _error;

  final _fmt     = NumberFormat('#,##,##0.00', 'en_IN');
  final _dateFmt = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _repo     = GirviRepository(_db);
    _listCtrl = GirviListController(_db);
    _load();
  }

  @override
  void dispose() {
    _listCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      await _repo.syncOverdueStatus();
      final all = await _repo.getLoansWithCustomer();
      _overdueLoans = all.where((g) =>
          g.loan.isOverdue ||
          g.loan.girviStatus == GirviStatus.overdue).toList();
      _overdueLoans.sort(
          (a, b) => b.loan.daysElapsed.compareTo(a.loan.daysElapsed));
    } catch (e) {
      _error = 'Failed to load overdue loans.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAuctioned(GirviLoanWithCustomer data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: GirviColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(GirviIcons.auctioned, color: GirviColors.danger),
          const SizedBox(width: 10),
          Text('Mark as Auctioned',
              style: GoogleFonts.manrope(
                  fontSize: 16, fontWeight: FontWeight.w800,
                  color: GirviColors.textDark)),
        ]),
        content: Text(
            'Mark ${data.loan.ticketNo} (${data.customerName}) as auctioned?\n\n'
            'This action is IRREVERSIBLE.',
            style: GoogleFonts.inter(fontSize: 13, color: GirviColors.textBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: GirviColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GirviColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Mark Auctioned',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    await _repo.updateStatus(data.loan.id, GirviStatus.auctioned);
    _load();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${data.loan.ticketNo} marked as auctioned.',
            style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: GirviColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _sendNotice(GirviLoanWithCustomer data) {
    // In production: trigger SMS/WhatsApp notification to customer.
    // For now, show confirmation snack.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.notifications_active_rounded,
            color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Text('Notice sent to ${data.customerName} (${data.customerMobile})',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 12)),
      ]),
      backgroundColor: GirviColors.warning,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GirviColors.bodyBg,
      appBar: GirviAppBar(
        screenTitle:    GirviStrings.noticeTitle,
        screenSubtitle: GirviStrings.noticeSub,
        onBack: widget.onBack ?? () => Navigator.pop(context),
        actions: [
          GestureDetector(
            onTap: _load,
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GirviColors.shellPanelBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GirviColors.shellBorder),
              ),
              child: const Icon(GirviIcons.refresh,
                  color: GirviColors.shellTextMuted, size: 18),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: GirviColors.brandGold))
          : _error != null
              ? Center(child: Text(_error!, style: GirviStyles.caption))
              : _overdueLoans.isEmpty
                  ? _EmptyOverdue()
                  : _buildList(),
    );
  }

  Widget _buildList() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Alert Banner ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: GirviColors.dangerBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GirviColors.dangerBorder),
            ),
            child: Row(children: [
              const Icon(GirviIcons.overdue, color: GirviColors.danger, size: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_overdueLoans.length} Overdue Loan${_overdueLoans.length > 1 ? 's' : ''}',
                      style: GoogleFonts.manrope(
                          color: GirviColors.danger,
                          fontSize: 14, fontWeight: FontWeight.w800)),
                  Text(
                    'Total: ₹${_fmt.format(_overdueLoans.fold(0.0, (s, g) => s + g.loan.loanAmount))} principal outstanding',
                    style: GirviStyles.caption.copyWith(color: GirviColors.danger),
                  ),
                ],
              ),
            ]),
          ),
        ),

        // ── Cards ────────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _OverdueCard(
                data:           _overdueLoans[i],
                onSendNotice:   () => _sendNotice(_overdueLoans[i]),
                onMarkAuctioned:() => _markAuctioned(_overdueLoans[i]),
              ),
              childCount: _overdueLoans.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _OverdueCard extends StatelessWidget {
  final GirviLoanWithCustomer data;
  final VoidCallback          onSendNotice;
  final VoidCallback          onMarkAuctioned;

  const _OverdueCard({
    required this.data,
    required this.onSendNotice,
    required this.onMarkAuctioned,
  });

  @override
  Widget build(BuildContext context) {
    final loan   = data.loan;
    final fmt    = NumberFormat('#,##,##0.00', 'en_IN');
    final dateFmt = DateFormat('dd MMM yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: GirviColors.danger, width: 4)),
        boxShadow: const [
          BoxShadow(
              color: GirviColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GirviColors.dangerBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(GirviIcons.overdue,
                    color: GirviColors.danger, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loan.ticketNo, style: GirviStyles.ticketNumber),
                    Text(data.customerName,
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: GirviColors.textDark)),
                    Text(data.customerMobile, style: GirviStyles.caption),
                  ],
                ),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: GirviColors.dangerBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: GirviColors.dangerBorder),
                  ),
                  child: Text('${loan.daysToMaturity.abs()} days overdue',
                      style: GoogleFonts.inter(
                          color: GirviColors.danger,
                          fontSize: 10, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 4),
                Text('Since ${loan.maturityDate != null ? dateFmt.format(loan.maturityDate!) : "N/A"}',
                    style: GirviStyles.caption.copyWith(fontSize: 10)),
              ]),
            ]),
          ),

          Container(height: 1, color: GirviColors.divider),

          // Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MiniInfo('Principal',
                    '₹${fmt.format(loan.loanAmount)}',
                    GirviColors.brandGold),
                _MiniInfo('Accrued Interest',
                    '₹${fmt.format(loan.accruedInterest)}',
                    GirviColors.warning),
                _MiniInfo('Total Due',
                    '₹${fmt.format(loan.totalDue)}',
                    GirviColors.danger),
              ],
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(children: [
              // Send Notice
              Expanded(
                child: GestureDetector(
                  onTap: onSendNotice,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: GirviColors.warningBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: GirviColors.warningBorder),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.notifications_active_rounded,
                          color: GirviColors.warning, size: 14),
                      const SizedBox(width: 6),
                      Text('Send Notice',
                          style: GoogleFonts.inter(
                              color: GirviColors.warning,
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Mark Auctioned
              Expanded(
                child: GestureDetector(
                  onTap: onMarkAuctioned,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: GirviColors.dangerBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: GirviColors.dangerBorder),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(GirviIcons.auctioned,
                          color: GirviColors.danger, size: 14),
                      const SizedBox(width: 6),
                      Text('Mark Auctioned',
                          style: GoogleFonts.inter(
                              color: GirviColors.danger,
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _MiniInfo(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(label, style: GirviStyles.caption.copyWith(fontSize: 10)),
      const SizedBox(height: 3),
      Text(value,
          style: GoogleFonts.manrope(
              fontSize: 12, fontWeight: FontWeight.w800, color: color)),
    ],
  );
}

class _EmptyOverdue extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(GirviIcons.released,
          color: GirviColors.success.withOpacity(0.5), size: 64),
      const SizedBox(height: 16),
      Text('No Overdue Loans! 🎉',
          style: GoogleFonts.manrope(
              fontSize: 18, fontWeight: FontWeight.w800,
              color: GirviColors.textMuted)),
      const SizedBox(height: 8),
      Text('All active girvi loans are within their maturity date.',
          style: GirviStyles.caption.copyWith(fontSize: 13),
          textAlign: TextAlign.center),
    ]),
  );
}
