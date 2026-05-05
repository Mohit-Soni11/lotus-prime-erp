// =============================================================================
// FILE        : girvi_list_screen.dart
// MODULE      : Girvi / Pawn
// LAYER       : UI / Screen
// DESCRIPTION : Full Girvi Ledger screen.
//               Shows summary stats dashboard, filter chips, search,
//               and scrollable list of GirviTicketCards.
//               - App Bar extracted to girvi_list_app_bar.dart
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../database/db/app_database.dart';
import '../../../logic/girvi/girvi_controllers.dart';
import '../../../models/girvi/girvi_enums.dart';
import '../../../models/girvi/girvi_loan_model.dart';
import '../../../theme/girvi/girvi_theme.dart';
import 'girvi_list_app_bar.dart'; // NAYA IMPORT
import '../shared/girvi_shared_widgets.dart';
import '../girvi_release/girvi_release_screen.dart';
import '../interest_calc/interest_calc_screen.dart';

class GirviListScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNewGirvi;

  const GirviListScreen({
    super.key,
    this.onBack,
    this.onNewGirvi,
  });

  @override
  State<GirviListScreen> createState() => _GirviListScreenState();
}

class _GirviListScreenState extends State<GirviListScreen>
    with SingleTickerProviderStateMixin {
  late final GirviListController _ctrl;
  final AppDatabase _db = AppDatabase();
  final _searchCtrl = TextEditingController();

  late final AnimationController _fadeAnim;
  late final Animation<double> _fade;

  final _fmt = NumberFormat('#,##,##0.00', 'en_IN');
  final _fmtShort = NumberFormat('#,##,##0', 'en_IN');

  @override
  void initState() {
    super.initState();
    _ctrl = GirviListController(_db);

    _fadeAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _fadeAnim, curve: Curves.easeOut);

    _searchCtrl.addListener(() => _ctrl.onSearchChanged(_searchCtrl.text));

    _ctrl.load().then((_) {
      if (mounted) _fadeAnim.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _searchCtrl.dispose();
    _fadeAnim.dispose();
    super.dispose();
  }

  void _openRelease(GirviLoanWithCustomer data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GirviReleaseScreen(
          loan: data.loan,
          customerName: data.customerName,
          db: _db,
          onReleased: () {
            Navigator.pop(context);
            _ctrl.reload();
          },
        ),
      ),
    );
  }

  void _openCalculator() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const InterestCalcScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GirviColors.bodyBg,
      // NAYA PREMIUM APP BAR
      appBar: GirviListAppBar(
        onBack: widget.onBack ?? () => Navigator.pop(context),
        onCalculatorTap: _openCalculator,
        onRefreshTap: () => _ctrl.reload(),
      ),
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          if (_ctrl.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: GirviColors.brandGold));
          }
          if (_ctrl.errorMessage != null) {
            return _ErrorState(
                message: _ctrl.errorMessage!, onRetry: _ctrl.reload);
          }

          return FadeTransition(
            opacity: _fade,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Stats Dashboard ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _buildStatsDashboard(_ctrl.summary),
                ),

                // ── Search ─────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _buildSearchBar(),
                ),

                // ── Filter Chips ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _buildFilterChips(),
                ),

                // ── List ───────────────────────────────────────────────────
                _ctrl.loans.isEmpty
                    ? SliverFillRemaining(
                        child: _EmptyState(
                          filter: _ctrl.filter,
                          onNewGirvi: widget.onNewGirvi,
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) {
                              final item = _ctrl.loans[i];
                              return GirviTicketCard(
                                data: item,
                                onTap: () => _openRelease(item),
                                onRelease:
                                    item.loan.isActive || item.loan.isOverdue
                                        ? () => _openRelease(item)
                                        : null,
                              );
                            },
                            childCount: _ctrl.loans.length,
                          ),
                        ),
                      ),
              ],
            ),
          );
        },
      ),

      // FAB: New Girvi
      floatingActionButton: widget.onNewGirvi != null
          ? FloatingActionButton.extended(
              onPressed: widget.onNewGirvi,
              backgroundColor: GirviColors.brandGold,
              foregroundColor: GirviColors.shellBg,
              icon: const Icon(GirviIcons.moduleIcon),
              label: Text('New Girvi',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
            )
          : null,
    );
  }

  // ── STATS DASHBOARD ───────────────────────────────────────────────────────

  Widget _buildStatsDashboard(GirviSummaryModel s) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GirviColors.shellBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GirviColors.brandGold.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: GirviColors.brandGold.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Portfolio value + collection
          Row(children: [
            Expanded(
                child: _DashboardStat(
              label: 'Active Portfolio',
              value: '₹${_fmtShort.format(s.totalPrincipalActive)}',
              subValue: '${s.totalActive + s.totalOverdue} loans',
              color: GirviColors.brandGold,
              icon: GirviIcons.loanTerms,
            )),
            Container(width: 1, height: 60, color: GirviColors.shellBorder),
            Expanded(
                child: _DashboardStat(
              label: 'Interest Due',
              value: '₹${_fmtShort.format(s.totalInterestDue)}',
              subValue: 'Accrued total',
              color: GirviColors.warning,
              icon: GirviIcons.interestRate,
            )),
          ]),
          const SizedBox(height: 12),
          Container(height: 1, color: GirviColors.shellBorder),
          const SizedBox(height: 12),
          // Bottom row: status breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatusPill('Active', s.totalActive, GirviColors.statusActive),
              _StatusPill('Overdue', s.totalOverdue, GirviColors.statusOverdue),
              _StatusPill(
                  'Released', s.totalReleased, GirviColors.statusReleased),
              _StatusPill(
                  'Auctioned', s.totalAuctioned, GirviColors.statusAuctioned),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: GirviColors.successBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GirviColors.successBorder),
            ),
            child: Row(children: [
              const Icon(GirviIcons.cash, color: GirviColors.success, size: 14),
              const SizedBox(width: 8),
              Text('This Month Collected: ',
                  style: GoogleFonts.inter(
                      color: GirviColors.shellTextMuted, fontSize: 12)),
              Text('₹${_fmtShort.format(s.totalCollectedThisMonth)}',
                  style: GoogleFonts.manrope(
                      color: GirviColors.success,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
        ],
      ),
    );
  }

  // ── SEARCH BAR ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: GirviStyles.inputNormal,
        child: TextField(
          controller: _searchCtrl,
          style: GirviStyles.fieldInput,
          decoration: InputDecoration(
            hintText: 'Search by ticket, name, mobile or item...',
            hintStyle: GirviStyles.fieldHint,
            prefixIcon: const Icon(GirviIcons.search,
                color: GirviColors.brandGold, size: 18),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                    },
                    child: const Icon(Icons.close_rounded,
                        color: GirviColors.textMuted, size: 18))
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ── FILTER CHIPS ──────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: GirviFilter.values.map((f) {
          final isSelected = f == _ctrl.filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _ctrl.setFilter(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      isSelected ? GirviColors.brandGold : GirviColors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? GirviColors.brandGold
                        : GirviColors.cardBorder,
                  ),
                ),
                child: Text(f.displayName,
                    style: GoogleFonts.inter(
                      color: isSelected
                          ? GirviColors.shellBg
                          : GirviColors.textBody,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Dashboard sub-widgets ─────────────────────────────────────────────────────

class _DashboardStat extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final Color color;
  final IconData icon;

  const _DashboardStat({
    required this.label,
    required this.value,
    required this.subValue,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      color: GirviColors.shellTextMuted, fontSize: 10)),
              Text(value,
                  style: GoogleFonts.manrope(
                      color: color, fontSize: 16, fontWeight: FontWeight.w900)),
              Text(subValue,
                  style: GoogleFonts.inter(
                      color: GirviColors.shellTextMuted, fontSize: 10)),
            ],
          ),
        ]),
      );
}

class _StatusPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusPill(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
        Text('$count',
            style: GoogleFonts.manrope(
                color: color, fontSize: 18, fontWeight: FontWeight.w900)),
        Text(label,
            style: GoogleFonts.inter(
                color: GirviColors.shellTextMuted, fontSize: 10)),
      ]);
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline_rounded,
              color: GirviColors.danger, size: 48),
          const SizedBox(height: 16),
          Text(message,
              style: GirviStyles.caption.copyWith(fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: GirviColors.brandGold,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Retry', style: GirviStyles.saveButtonText),
            ),
          ),
        ]),
      );
}

class _EmptyState extends StatelessWidget {
  final GirviFilter filter;
  final VoidCallback? onNewGirvi;
  const _EmptyState({required this.filter, this.onNewGirvi});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(GirviIcons.moduleIcon,
              color: GirviColors.textHint.withOpacity(0.4), size: 64),
          const SizedBox(height: 16),
          Text(
            filter == GirviFilter.all
                ? 'No Girvi loans yet'
                : 'No ${filter.displayName.toLowerCase()} loans',
            style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: GirviColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text('Start by creating a new girvi ticket',
              style: GirviStyles.caption.copyWith(fontSize: 13)),
          if (onNewGirvi != null) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onNewGirvi,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: GirviColors.brandGold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add_rounded, color: GirviColors.shellBg),
                  const SizedBox(width: 8),
                  Text('New Girvi', style: GirviStyles.saveButtonText),
                ]),
              ),
            ),
          ],
        ]),
      );
}
