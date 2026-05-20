// =============================================================================
// FILE        : pending_jobs_screen.dart
// MODULE      : Karigar
// LAYER       : UI / Screen
// DESCRIPTION : Pending Jobs screen Ã¢â‚¬â€ live tracker for all open karigar jobs.
//               Features:
//               - App Bar extracted to pending_jobs_app_bar.dart
//               - 5 summary stat cards (karigars, jobs, overdue, weight, outstanding)
//               - Filter chips: All | Pending | In Progress | Overdue
//               - Search by karigar name, issue number, or item
//               - Job cards with overdue alert, days pending, quick-action swipe
//               - Empty state with contextual message
//               - ListenableBuilder Ã¢â‚¬â€ zero setState in UI
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../database/db/app_database.dart';
import '../../../logic/karigar/pending_jobs_controller.dart';
import '../../../models/karigar/karigar_enums/karigar_enums.dart';
import '../../../models/karigar/karigar_issue_model.dart';
import '../../../models/karigar/karigar_stats_model.dart';
import '../../../theme/karigar/karigar_theme.dart';
import 'pending_jobs_app_bar.dart'; // NAYA IMPORT
import '../shared/karigar_field_widgets.dart';

class PendingJobsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(int issueId)? onReceiveGoods;

  const PendingJobsScreen({
    super.key,
    this.onBack,
    this.onReceiveGoods,
  });

  @override
  State<PendingJobsScreen> createState() => _PendingJobsScreenState();
}

class _PendingJobsScreenState extends State<PendingJobsScreen>
    with TickerProviderStateMixin {
  late final PendingJobsController _ctrl;
  final _searchCtrl = TextEditingController();

  // Stagger animation for header cards
  late final AnimationController _headerAnim;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = PendingJobsController(AppDatabase());

    _headerAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeInOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _headerAnim, curve: Curves.easeOutCubic));

    _ctrl.loadData().then((_) {
      if (mounted) _headerAnim.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _searchCtrl.dispose();
    _headerAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: KarigarColors.shellBg,
        // NAYA APP BAR CALL
        appBar: PendingJobsAppBar(
          onBack: widget.onBack ?? () => Navigator.maybePop(context),
        ),
        body: SafeArea(
          child: Container(
            color: KarigarColors.bodyBg,
            child: ListenableBuilder(
              listenable: _ctrl,
              builder: (context, _) {
                if (_ctrl.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: KarigarColors.brandGold,
                      strokeWidth: 2,
                    ),
                  );
                }

                return Column(children: [
                  // Ã¢â€â‚¬Ã¢â€â‚¬ Stats Header Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                  FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                      position: _headerSlide,
                      child: _StatsHeader(stats: _ctrl.stats),
                    ),
                  ),

                  // Ã¢â€â‚¬Ã¢â€â‚¬ Search + Filters Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                  _SearchAndFilterBar(
                    ctrl: _ctrl,
                    searchCtrl: _searchCtrl,
                    onSearch: _ctrl.onSearchChanged,
                    onFilter: _ctrl.onFilterChanged,
                  ),

                  // Ã¢â€â‚¬Ã¢â€â‚¬ Job List Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                  Expanded(
                    child: _ctrl.filteredJobs.isEmpty
                        ? _EmptyState(filter: _ctrl.activeFilter)
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _ctrl.filteredJobs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final job = _ctrl.filteredJobs[i];
                              return _JobCard(
                                job: job,
                                onMarkInProgress: () =>
                                    _ctrl.markInProgress(job.id),
                                onCancel: () => _confirmCancel(job),
                                onReceive: () =>
                                    widget.onReceiveGoods?.call(job.id),
                              );
                            },
                          ),
                  ),
                ]);
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCancel(KarigarIssueWithKarigar job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: KarigarColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Job?', style: KarigarStyles.sectionTitle),
        content: Text(
          'Cancel issue #${job.issueNumber} for ${job.karigarName}?\nThis action cannot be undone.',
          style: KarigarStyles.caption.copyWith(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No, Keep It',
                style: GoogleFonts.inter(
                    color: KarigarColors.textMuted,
                    fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: KarigarColors.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Cancel Job',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _ctrl.markCancelled(job.id);
  }
}

// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
// STATS HEADER
// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

class _StatsHeader extends StatelessWidget {
  final OverallKarigarStats stats;
  const _StatsHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    final rupee = NumberFormat('Ã¢â€šÂ¹##,##,##0', 'en_IN');
    final wt = NumberFormat('##0.00', 'en_IN');

    return Container(
      color: KarigarColors.shellPanelBg,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(children: [
        _StatChip(
          icon: KarigarIcons.karigar,
          label: KarigarStrings.statActiveKarigars,
          value: '${stats.totalKarigars}',
          color: KarigarColors.brandGold,
        ),
        const SizedBox(width: 10),
        _StatChip(
          icon: KarigarIcons.pending,
          label: KarigarStrings.statActiveJobs,
          value: '${stats.totalActiveJobs}',
          color: KarigarColors.statusInProgress,
        ),
        const SizedBox(width: 10),
        _StatChip(
          icon: KarigarIcons.overdue,
          label: KarigarStrings.statOverdueJobs,
          value: '${stats.totalOverdueJobs}',
          color: stats.totalOverdueJobs > 0
              ? KarigarColors.danger
              : KarigarColors.textMuted,
        ),
        const SizedBox(width: 10),
        _StatChip(
          icon: KarigarIcons.statsWeight,
          label: KarigarStrings.statWeightPending,
          value: '${wt.format(stats.totalWeightWithKarigar)}g',
          color: KarigarColors.info,
        ),
        const SizedBox(width: 10),
        _StatChip(
          icon: KarigarIcons.statsMoney,
          label: KarigarStrings.statOutstanding,
          value: rupee.format(stats.totalOutstanding),
          color: KarigarColors.warning,
        ),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: KarigarColors.shellTextTitle,
                )),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: KarigarColors.shellTextMuted,
                ),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
// SEARCH + FILTER BAR
// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

class _SearchAndFilterBar extends StatelessWidget {
  final PendingJobsController ctrl;
  final TextEditingController searchCtrl;
  final Function(String) onSearch;
  final Function(PendingJobsFilter) onFilter;

  const _SearchAndFilterBar({
    required this.ctrl,
    required this.searchCtrl,
    required this.onSearch,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: KarigarColors.cardBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(children: [
        // Search bar
        TextField(
          controller: searchCtrl,
          onChanged: onSearch,
          style: KarigarStyles.fieldInput.copyWith(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search by karigar, issue number, or item...',
            hintStyle: KarigarStyles.fieldHint,
            prefixIcon: const Icon(KarigarIcons.search,
                color: KarigarColors.textHint, size: 20),
            suffixIcon: searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(KarigarIcons.close,
                        color: KarigarColors.textHint, size: 18),
                    onPressed: () {
                      searchCtrl.clear();
                      onSearch('');
                    },
                  )
                : null,
            filled: true,
            fillColor: KarigarColors.inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: KarigarColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: KarigarColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: KarigarColors.brandGold, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 10),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: PendingJobsFilter.values.map((filter) {
              final isActive = ctrl.activeFilter == filter;
              final color = _filterColor(filter);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onFilter(filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? color.withValues(alpha: 0.12)
                          : KarigarColors.inputBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? color : KarigarColors.cardBorder,
                        width: isActive ? 1.5 : 1.0,
                      ),
                    ),
                    child: Text(filter.label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive ? color : KarigarColors.textMuted,
                        )),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  Color _filterColor(PendingJobsFilter filter) {
    switch (filter) {
      case PendingJobsFilter.all:
        return KarigarColors.brandGold;
      case PendingJobsFilter.pending:
        return KarigarColors.statusPending;
      case PendingJobsFilter.inProgress:
        return KarigarColors.statusInProgress;
      case PendingJobsFilter.overdue:
        return KarigarColors.danger;
    }
  }
}

// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
// JOB CARD
// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

class _JobCard extends StatelessWidget {
  final KarigarIssueWithKarigar job;
  final VoidCallback onMarkInProgress;
  final VoidCallback onCancel;
  final VoidCallback? onReceive;

  const _JobCard({
    required this.job,
    required this.onMarkInProgress,
    required this.onCancel,
    this.onReceive,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yy');
    final statusColor = _statusColor(job.statusEnum, job.isOverdue);

    return Container(
      decoration: BoxDecoration(
        color: KarigarColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: job.isOverdue
              ? KarigarColors.danger.withValues(alpha: 0.4)
              : KarigarColors.cardBorder,
          width: job.isOverdue ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: job.isOverdue
                ? KarigarColors.danger.withValues(alpha: 0.06)
                : KarigarColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: [
        // Card body
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(children: [
            // Row 1: Issue # + Status
            Row(children: [
              Text(job.issueNumber, style: KarigarStyles.issueNumber),
              const SizedBox(width: 10),
              KarigarStatusPill(
                label: job.isOverdue
                    ? KarigarStrings.statusOverdue
                    : job.statusEnum.label,
                color: statusColor,
                icon: job.isOverdue ? KarigarIcons.overdue : null,
              ),
              const Spacer(),
              if (job.isOverdue) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: KarigarColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${job.daysOverdue}d overdue',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: KarigarColors.danger,
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: KarigarColors.textHint.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${job.daysPending}d pending',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: KarigarColors.textMuted,
                    ),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 10),

            // Row 2: Karigar + Item
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: KarigarColors.brandGoldLight,
                child: Text(job.karigarInitials,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: KarigarColors.brandGold,
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.karigarName, style: KarigarStyles.jobTitle),
                  const SizedBox(height: 2),
                  Text(job.itemDescription,
                      style: KarigarStyles.jobSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              )),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${job.netWeightIssued.toStringAsFixed(3)}g',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: KarigarColors.brandGold,
                      )),
                  Text('Net wt. issued', style: KarigarStyles.caption),
                ],
              ),
            ]),
            const SizedBox(height: 10),

            // Row 3: Metal + Qty + Dates
            Row(children: [
              _InfoChip(job.metalDisplay),
              const SizedBox(width: 8),
              _InfoChip('${job.quantity} ${KarigarStrings.unitPieces}'),
              const SizedBox(width: 8),
              _InfoChip(job.itemCategory),
              const Spacer(),
              if (job.expectedDelivery != null)
                Text(
                  'Due: ${fmt.format(job.expectedDelivery!)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: job.isOverdue
                        ? KarigarColors.danger
                        : KarigarColors.textMuted,
                  ),
                ),
            ]),
          ]),
        ),

        // Divider
        Container(height: 1, color: KarigarColors.divider),

        // Action Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            if (job.statusEnum == IssueStatus.pending)
              _ActionButton(
                icon: KarigarIcons.inProgress,
                label: 'In Progress',
                color: KarigarColors.info,
                onTap: onMarkInProgress,
              ),
            const Spacer(),
            if (onReceive != null)
              _ActionButton(
                icon: KarigarIcons.receive,
                label: 'Receive Goods',
                color: KarigarColors.success,
                onTap: onReceive!,
                isPrimary: true,
              ),
            const SizedBox(width: 8),
            _ActionButton(
              icon: KarigarIcons.cancel,
              label: 'Cancel',
              color: KarigarColors.danger,
              onTap: onCancel,
            ),
          ]),
        ),
      ]),
    );
  }

  Color _statusColor(IssueStatus status, bool isOverdue) {
    if (isOverdue) return KarigarColors.danger;
    switch (status) {
      case IssueStatus.pending:
        return KarigarColors.statusPending;
      case IssueStatus.inProgress:
        return KarigarColors.statusInProgress;
      case IssueStatus.completed:
        return KarigarColors.statusCompleted;
      case IssueStatus.cancelled:
        return KarigarColors.statusCancelled;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: KarigarColors.inputBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: KarigarColors.cardBorder),
      ),
      child: Text(label,
          style: KarigarStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: KarigarColors.textBody,
          )),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isPrimary ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPrimary
                ? color.withValues(alpha: 0.4)
                : color.withValues(alpha: 0.25),
            width: isPrimary ? 1.5 : 1.0,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              )),
        ]),
      ),
    );
  }
}

// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
// EMPTY STATE
// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

class _EmptyState extends StatelessWidget {
  final PendingJobsFilter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            filter == PendingJobsFilter.overdue
                ? KarigarIcons.completed
                : KarigarIcons.emptyJobs,
            size: 64,
            color: KarigarColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(KarigarStrings.emptyJobsTitle,
              style: KarigarStyles.sectionTitle.copyWith(fontSize: 16)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              filter == PendingJobsFilter.overdue
                  ? 'All jobs are on track Ã¢â‚¬â€ no overdue work!'
                  : KarigarStrings.emptyJobsSub,
              style: KarigarStyles.caption.copyWith(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
