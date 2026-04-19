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

import 'date_time_card.dart';
import '../dashboard/bill_card.dart';
import '../dashboard/customer_card.dart';
import '../dashboard/pending_order_card.dart';
import '../dashboard/shop_card.dart';
import '../dashboard/live_rates_card.dart';
import '../dashboard/quick_actions_card.dart';
import '../dashboard/alert_row.dart';
import '../dashboard/payment_status_card.dart';
import '../dashboard/daily_counter_card.dart';
import '../dashboard/cash_register_card.dart';
import '../dashboard/counter_security_card.dart';

class DashboardScreen extends StatefulWidget {
  final Function(String routeId) onNavigate;
  // ✅ FIX: onNavigateWithId — customerId pass karne ke liye (Payment Status → Profile)
  final Function(String routeId, {int? customerId})? onNavigateWithId;

  const DashboardScreen({
    super.key,
    required this.onNavigate,
    this.onNavigateWithId,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  final DashboardRepository _repository = DashboardRepository();
  UserProfile? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
      debugPrint('🔴 Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
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
    return Column(
      children: [

        // 1. 4 Stat Cards — ek row mein
        const Row(children: [
          Expanded(child: DateAndTimeCard()),
          SizedBox(width: 20),
          Expanded(child: BillGeneratedCard()),
          SizedBox(width: 20),
          Expanded(child: NewCustomerCard()),
          SizedBox(width: 20),
          Expanded(child: PendingOrdersCard()),
        ]),

        const SizedBox(height: 20),

        // 2. Live Rates Card
        const LiveRatesCard(),

        const SizedBox(height: 20),

        // 3. Alert Row
        AlertRow(onNavigate: widget.onNavigate),

        const SizedBox(height: 20),

        // 4. Daily Counter — full width (Cash Register right mein shift hua)
        const DailyCounterCard(),

        const SizedBox(height: 20),

        // 5. Counter Security Check
        const CounterSecurityCard(),

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
        ShopIdentityCard(repository: _repository),

        const SizedBox(height: 20),

        // 2. Quick Actions
        QuickActionsCard(onNavigate: widget.onNavigate),

        const SizedBox(height: 20),

        // 3. Payment Status
        PaymentStatusCard(
          onNavigate: widget.onNavigate,
          // ✅ FIX: customerId ab properly pass hoga parent ko
          onNavigateWithId: (routeId, {int? customerId}) {
            if (widget.onNavigateWithId != null) {
              widget.onNavigateWithId!(routeId, customerId: customerId);
            } else {
              widget.onNavigate(routeId);
            }
          },
        ),

        const SizedBox(height: 20),

        // 4. Cash Register — Payment Status ke neeche
        CashRegisterCard(onNavigate: widget.onNavigate),

      ],
    );
  }
}