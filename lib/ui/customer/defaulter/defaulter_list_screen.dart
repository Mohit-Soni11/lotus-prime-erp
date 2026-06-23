// ==========================================
// FILE: defaulter_list_screen.dart
// MODULE: Customer → Defaulter List
// DESCRIPTION: Master screen widget.
//              Composes: AppBar + StatsPanel + FilterBar + DataTable.
//              Manages DefaulterLogic lifecycle via ChangeNotifierProvider
//              pattern (manual, no external package dependency).
//              Matches full-page navigation pattern (like PosMasterSaleScreen).
// ==========================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_routes.dart';
import '../../../logic/customer/defaulter_logic.dart';
import '../../../models/customer/defaulter_model.dart';
import '../../../theme/customer/defaulter/defaulter_theme.dart';
import 'defaulter_app_bar.dart';
import 'defaulter_stats_panel.dart';
import 'defaulter_filter_bar.dart';
import 'defaulter_data_table.dart';

class DefaulterListScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const DefaulterListScreen({
    super.key,
    this.onBack,
  });

  @override
  State<DefaulterListScreen> createState() => _DefaulterListScreenState();
}

class _DefaulterListScreenState extends State<DefaulterListScreen>
    with SingleTickerProviderStateMixin {
  // ==========================================
  // LOGIC
  // ==========================================
  late final DefaulterLogic _logic;

  // ==========================================
  // ANIMATION (entry animation for body)
  // ==========================================
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // Init Logic
    _logic = DefaulterLogic();
    _logic.init();
    _logic.addListener(_onStateChanged);

    // Entry animation
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    // Start animation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entryController.forward();
    });
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _logic.removeListener(_onStateChanged);
    _logic.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _openGirviAccount(DefaulterModel account) {
    context.go(RoutePaths.girviAccountFor(account.loanId));
  }

  void _openInterestEntry(DefaulterModel account) {
    final route = RouteMapper.toPath(AppRoutes.interestCalcRoute);
    final uri = Uri(
      path: route,
      queryParameters: {
        'ticketNo': account.referenceNo,
        'returnTo': 'riskCollections',
      },
    );
    context.go(uri.toString());
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final state = _logic.state;

    return Scaffold(
      backgroundColor: DefaulterColors.bodyBg,

      // ── APP BAR (Fixed according to updated premium design) ──────
      appBar: DefaulterAppBar(
        onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
      ),

      // ── BODY ─────────────────────────────────
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Stats Summary Panel
              DefaulterStatsPanel(
                stats: state.stats,
                isLoading: state.isLoading,
              ),

              const SizedBox(height: 4),

              // 2. Filter & Search Bar
              DefaulterFilterBar(
                activeFilter: state.activeFilter,
                activeSort: state.activeSort,
                searchQuery: state.searchQuery,
                onFilterChanged: _logic.setFilter,
                onSortChanged: _logic.setSort,
                onSearchChanged: _logic.onSearch,
              ),

              // 3. Result Count Bar
              _ResultCountBar(
                displayedCount: state.displayedDefaulters.length,
                totalCount: state.allDefaulters.length,
                activeFilter: state.activeFilter,
                isLoading: state.isLoading,
              ),

              // 4. Data Table (Expanded — fills remaining space)
              Expanded(
                child: DefaulterDataTable(
                  defaulters: state.displayedDefaulters,
                  isLoading: state.isLoading,
                  errorMessage: state.errorMessage,
                  onOpenAccount: _openGirviAccount,
                  onOpenInterestEntry: _openInterestEntry,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// RESULT COUNT BAR
// ─────────────────────────────────────────

class _ResultCountBar extends StatelessWidget {
  final int displayedCount;
  final int totalCount;
  final DefaulterFilterBy activeFilter;
  final bool isLoading;

  const _ResultCountBar({
    required this.displayedCount,
    required this.totalCount,
    required this.activeFilter,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const SizedBox(height: 10);

    final String countText = displayedCount == totalCount
        ? 'Showing all $totalCount risk accounts'
        : 'Showing $displayedCount of $totalCount risk accounts';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
      child: Row(
        children: [
          Text(
            countText,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: DefaulterColors.bodyTextMuted,
            ),
          ),
          const Spacer(),
          Text(
            'Last updated: ${_timeNow()}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: DefaulterColors.bodyTextHint,
            ),
          ),
        ],
      ),
    );
  }

  String _timeNow() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
