import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_routes.dart';
import '../../../database/db/app_database.dart';
import '../../../logic/girvi/girvi_controllers.dart';
import '../../../models/girvi/girvi_enums.dart';
import '../../../models/girvi/girvi_loan_model.dart';
import '../../../theme/girvi/girvi_theme.dart';
import 'girvi_list_app_bar.dart';

part 'parts/girvi_ledger_controls.dart';
part 'parts/girvi_ledger_detail_panel.dart';
part 'parts/girvi_ledger_layout.dart';
part 'parts/girvi_ledger_overview.dart';
part 'parts/girvi_ledger_shared.dart';
part 'parts/girvi_ledger_ticket_list.dart';

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
  final AppDatabase _db = AppDatabase();
  final TextEditingController _searchController = TextEditingController();

  late final GirviListController _controller;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  final NumberFormat _moneyFormat = NumberFormat('#,##,##0', 'en_IN');
  final NumberFormat _preciseMoneyFormat = NumberFormat('#,##,##0.00', 'en_IN');
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  int? _selectedLoanId;

  @override
  void initState() {
    super.initState();
    _controller = GirviListController(_db);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _searchController.addListener(
      () => _controller.onSearchChanged(_searchController.text),
    );
    _loadLedger();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadLedger() async {
    _fadeController.reset();
    await _controller.load();
    if (!mounted) return;
    _fadeController.forward();
  }

  Future<void> _reloadLedger() async {
    _fadeController.reset();
    await _controller.reload();
    if (!mounted) return;
    _fadeController.forward();
  }

  GirviLoanWithCustomer? get _selectedLoan {
    final loans = _controller.loans;
    if (loans.isEmpty) return null;

    final selectedId = _selectedLoanId;
    if (selectedId != null) {
      for (final item in loans) {
        if (item.loan.id == selectedId) return item;
      }
    }

    return loans.first;
  }

  bool _isSelected(GirviLoanWithCustomer item) {
    return _selectedLoan?.loan.id == item.loan.id;
  }

  void _selectLoan(GirviLoanWithCustomer item) {
    setState(() => _selectedLoanId = item.loan.id);
  }

  void _setFilter(GirviFilter filter) {
    _controller.setFilter(filter);
  }

  void _clearSearch() {
    _searchController.clear();
  }

  void _openNewGirvi() {
    widget.onNewGirvi?.call();
  }

  void _openInterestEntry(GirviLoanWithCustomer item) {
    final route = RouteMapper.toPath(AppRoutes.interestCalcRoute);
    final uri = Uri(
      path: route,
      queryParameters: {
        'ticketNo': item.loan.ticketNo,
        'returnTo': 'girviLedger',
      },
    );
    context.go(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GirviColors.bodyBg,
      appBar: GirviListAppBar(
        onBack: widget.onBack ?? () => Navigator.maybePop(context),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const _GirviLedgerLoadingState();
          }

          if (_controller.errorMessage != null) {
            return _GirviLedgerErrorState(
              message: _controller.errorMessage!,
              onRetry: _reloadLedger,
            );
          }

          return _buildLedgerBody();
        },
      ),
    );
  }
}
