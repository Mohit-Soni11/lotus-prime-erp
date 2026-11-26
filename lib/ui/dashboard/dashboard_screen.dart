// =============================================================================
// FILE        : dashboard_screen.dart
// MODULE      : Dashboard
// LAYER       : UI
// DESCRIPTION : Main dashboard — Python layout exact match.
//
//               LEFT COLUMN:
//                 4 Stat Cards → Live Rates → Alert Row
//                 → [Daily Counter | Cash Register] (side by side)
//
//               RIGHT COLUMN:
//                 Shop Identity → Quick Actions → Payment Status
// =============================================================================

import 'package:flutter/material.dart';

import 'package:lotus_erp/theme/dashboard/topbar/topbar_theme.dart';
import '../../ui/dashboard/top_bar.dart';
import '../../logic/dashboard/dashboard_repository.dart';
import '../../models/dashboard/user_profile.dart';
import '../../constants/app_routes.dart';
import '../../core/events/shop_identity_updates.dart';
import '../../features/dashboard/shop_identity/data/shop_identity_repository.dart';

import 'date_time_card.dart';
import '../dashboard/bill_card.dart';
import '../dashboard/customer_card.dart';
import '../dashboard/pending_order_card.dart';
import '../../features/dashboard/shop_identity/presentation/shop_identity_card.dart';
import '../dashboard/live_rates_card.dart';
import '../dashboard/quick_actions_card.dart';
import '../dashboard/payment_status_card.dart';
import '../dashboard/daily_counter_card.dart';
import '../dashboard/cash_register_card.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';

class DashboardScreen extends StatefulWidget {
  final Function(String routeId) onNavigate;
  final ValueChanged<int> onOpenCustomer;
  final void Function(int billId, int? customerId) onOpenInvoice;

  const DashboardScreen({
    super.key,
    required this.onNavigate,
    required this.onOpenCustomer,
    required this.onOpenInvoice,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ShopIdentityRepository _shopIdentityRepository =
      ShopIdentityRepository();
  late final DashboardRepository _repository = DashboardRepository(
    shopIdentityReader: _shopIdentityRepository,
  );
  UserProfile? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    ShopIdentityUpdates.instance.revision.addListener(_refreshCurrentUser);
    _connectToDatabase();
  }

  Future<void> _connectToDatabase() async {
    try {
      final user = await _repository.fetchUserProfile();
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.debug('🔴 Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshCurrentUser() async {
    final user = await _repository.fetchUserProfile();
    if (!mounted) return;
    setState(() => _currentUser = user);
  }

  @override
  void dispose() {
    ShopIdentityUpdates.instance.revision.removeListener(_refreshCurrentUser);
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: TopBarColors.background,
        body: Center(
          child: CircularProgressIndicator(color: TopBarColors.accentGold),
        ),
      );
    }

    return Scaffold(
      backgroundColor: TopBarColors.background,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              currentUser: _currentUser ??
                  const UserProfile(
                      name: 'Guest', role: 'Viewer', isOnline: false),
              repository: _repository,
              onNavChange: (action) {
                if (action == 'New Sale') {
                  widget.onNavigate(AppRoutes.newSaleRoute);
                } else if (action == 'My Profile') {
                  widget.onNavigate(AppRoutes.accountProfileRoute);
                } else if (action.startsWith('/')) {
                  widget.onNavigate(action);
                }
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildLayout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayout(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 1100;

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _buildLeftSection()),
          const SizedBox(width: 20),
          Expanded(flex: 1, child: _buildRightSection()),
        ],
      );
    }

    return Column(children: [
      _buildLeftSection(),
      const SizedBox(height: 20),
      _buildRightSection(),
    ]);
  }

  // ==========================================
  // LEFT SECTION
  // Python: 4 cards → live rates → alert row → [daily counter | cash register]
  // ==========================================
  Widget _buildLeftSection() {
    return const Column(
      children: [
        // 1. 4 Stat Cards — ek row mein
        Row(children: [
          Expanded(child: DateAndTimeCard()),
          SizedBox(width: 20),
          Expanded(child: BillGeneratedCard()),
          SizedBox(width: 20),
          Expanded(child: NewCustomerCard()),
          SizedBox(width: 20),
          Expanded(child: PendingOrdersCard()),
        ]),

        SizedBox(height: 20),

        // 2. Live Rates Card
        LiveRatesCard(),

        SizedBox(height: 20),

        // Daily counter activity
        DailyCounterCard(),
      ],
    );
  }

  // ==========================================
  // RIGHT SECTION
  // Python: shop card → quick actions → payment tracker
  // ==========================================
  Widget _buildRightSection() {
    return Column(
      children: [
        // 1. Shop Identity Card
        ShopIdentityCard(reader: _shopIdentityRepository),

        const SizedBox(height: 20),

        // 2. Quick Actions
        QuickActionsCard(onNavigate: widget.onNavigate),

        const SizedBox(height: 20),

        // 3. Payment Status
        PaymentStatusCard(
          onOpenCustomer: widget.onOpenCustomer,
          onOpenInvoice: widget.onOpenInvoice,
        ),

        const SizedBox(height: 20),

        // 4. Cash Register — Payment Status ke neeche
        CashRegisterCard(onNavigate: widget.onNavigate),
      ],
    );
  }
}
