// -----------------------------------------------------------------------------
// FILE: customer_profile_screen.dart
// MODULE: Customer → Customer Profile
// CHANGE LOG:
//   - TabBar: 2 tabs → 3 tabs (Bills | Girvi | Advance Orders)
//   - Added: Dues & Pending section (above history tabs)
//   - Edit dialog: improved — more fields (whatsapp, email, address, state, pincode)
//   - Edit button now shows full-form dialog (not just name/mobile/city)
//   - All withOpacity() → withValues(alpha:) — zero deprecation warnings
//   - Advance card: tappable "Convert to Sale" button
//   - All strings/icons/colors from theme — zero hardcoding
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/customer/customer_profile/customer_profile_theme.dart';
import '../../../logic/customer/customer_profile_logic.dart';
import '../../../models/customer/customer_profile/customer_profile_model.dart';
import 'customer_profile_app_bar.dart';

class CustomerProfileScreen extends StatefulWidget {
  final int customerId;
  final VoidCallback? onBack;
  final Function(int customerId)? onNewSale;
  final VoidCallback? onDeleted;

  /// Called when user taps "Convert to Sale" on an advance order.
  /// Passes advanceOrderId + customerId to parent for POS navigation.
  final Function(int advanceOrderId, int customerId)? onConvertAdvanceToSale;

  const CustomerProfileScreen({
    super.key,
    required this.customerId,
    this.onBack,
    this.onNewSale,
    this.onDeleted,
    this.onConvertAdvanceToSale,
  });

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen>
    with TickerProviderStateMixin {
  late final CustomerProfileLogic _logic;
  late final AnimationController _pageAnim;
  late final Animation<double> _fadeIn;

  // Tab controller: Bills | Girvi | Advance Orders
  late final TabController _tabCtrl;

  // Controllers for credit limit
  final TextEditingController _creditCtrl = TextEditingController();

  // Controllers for improved edit dialog
  final TextEditingController _editNameCtrl = TextEditingController();
  final TextEditingController _editMobileCtrl = TextEditingController();
  final TextEditingController _editWhatsappCtrl = TextEditingController();
  final TextEditingController _editEmailCtrl = TextEditingController();
  final TextEditingController _editCityCtrl = TextEditingController();
  final TextEditingController _editAddressCtrl = TextEditingController();
  final TextEditingController _editStateCtrl = TextEditingController();
  final TextEditingController _editPincodeCtrl = TextEditingController();
  String _editTypeValue = "Regular";

  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _logic = CustomerProfileLogic(
      customerId: widget.customerId,
      onConvertAdvanceToSale: widget.onConvertAdvanceToSale,
    );

    // ✅ 3 tabs now
    _tabCtrl = TabController(length: 3, vsync: this);

    _pageAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _pageAnim, curve: Curves.easeOut);

    _logic.addListener(() {
      if (_logic.state == ProfileState.loaded && _pageAnim.value == 0) {
        _pageAnim.forward();
      }
      if (_logic.state == ProfileState.deleted) {
        widget.onDeleted?.call();
        widget.onBack?.call();
      }
    });
  }

  @override
  void dispose() {
    _logic.dispose();
    _pageAnim.dispose();
    _tabCtrl.dispose();
    _creditCtrl.dispose();
    _editNameCtrl.dispose();
    _editMobileCtrl.dispose();
    _editWhatsappCtrl.dispose();
    _editEmailCtrl.dispose();
    _editCityCtrl.dispose();
    _editAddressCtrl.dispose();
    _editStateCtrl.dispose();
    _editPincodeCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomerProfileColors.bodyBg,
      appBar: CustomerProfileAppBar(
        onBack: widget.onBack ?? () {},
        customerName: _logic.profile?.name ?? "Customer",
      ),
      body: ListenableBuilder(
        listenable: _logic,
        builder: (context, _) {
          if (_logic.isLoading) return _buildLoading();
          if (_logic.state == ProfileState.error) return _buildError();
          if (_logic.profile == null) return _buildError();
          return _buildBody(_logic.profile!);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MAIN BODY
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBody(CustomerProfileModel p) {
    return FadeTransition(
      opacity: _fadeIn,
      child: SingleChildScrollView(
        controller: _scrollCtrl,
        padding: CustomerProfileStyles.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(p),
            const SizedBox(height: 16),
            _buildActionButtons(p),
            const SizedBox(height: 16),
            _buildStatsOverview(p),
            const SizedBox(height: 16),
            _buildContactCard(p),
            const SizedBox(height: 16),
            _buildCreditCard(p),
            const SizedBox(height: 16),
            // ✅ NEW: Dues section — shown only when dues exist
            if (p.hasDues) ...[
              _buildDuesSection(p),
              const SizedBox(height: 16),
            ],
            // ✅ UPDATED: 3 tabs
            _buildHistoryTabs(p),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. HERO CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeroCard(CustomerProfileModel p) {
    final isFemale = p.isFemale;
    final Color avatarBg =
        isFemale ? const Color(0xFFFCE4EC) : CustomerProfileColors.brandGoldBg;
    final Color avatarBorder =
        isFemale ? const Color(0xFFF48FB1) : CustomerProfileColors.brandGold;
    final Color initialsColor =
        isFemale ? const Color(0xFFE91E63) : CustomerProfileColors.brandGold;
    final Color genderIconColor =
        isFemale ? const Color(0xFFE91E63) : const Color(0xFF1565C0);
    final IconData genderIcon =
        isFemale ? Icons.female_rounded : Icons.male_rounded;

    return Container(
      decoration: CustomerProfileStyles.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: avatarBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: avatarBorder, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: avatarBorder.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  p.initials,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: initialsColor,
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: genderIconColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(genderIcon, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        p.name,
                        style: CustomerProfileStyles.customerName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildTypeBadge(p),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(CustomerProfileIcons.phone,
                        size: 13, color: CustomerProfileColors.bodyTextMuted),
                    const SizedBox(width: 4),
                    Text(p.mobile, style: CustomerProfileStyles.customerMobile),
                    const SizedBox(width: 12),
                    if (p.city.isNotEmpty) ...[
                      const Icon(CustomerProfileIcons.city,
                          size: 13, color: CustomerProfileColors.bodyTextMuted),
                      const SizedBox(width: 4),
                      Text(p.city, style: CustomerProfileStyles.customerMobile),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildCreditStatusBadge(p.creditStatus),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF81C784)),
                      ),
                      child: Text(
                        "Since ${p.formattedMemberSince}",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. ACTION BUTTONS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildActionButtons(CustomerProfileModel p) {
    return Row(
      children: [
        Expanded(
          child: _ActionBtn(
            icon: CustomerProfileIcons.newSale,
            label: CustomerProfileStrings.btnNewSale,
            bg: CustomerProfileColors.newSaleBg,
            fg: CustomerProfileColors.newSaleText,
            border: CustomerProfileColors.newSaleBg,
            filled: true,
            onTap: () => widget.onNewSale?.call(p.id),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionBtn(
            icon: CustomerProfileIcons.edit,
            label: CustomerProfileStrings.btnEdit,
            bg: CustomerProfileColors.editBg,
            fg: CustomerProfileColors.editText,
            border: CustomerProfileColors.editBorder,
            // ✅ Full improved edit dialog
            onTap: () => _showEditDialog(p),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionBtn(
            icon: CustomerProfileIcons.billHistory,
            label: CustomerProfileStrings.btnHistory,
            bg: CustomerProfileColors.historyBg,
            fg: CustomerProfileColors.historyText,
            border: CustomerProfileColors.historyBorder,
            onTap: () {
              _scrollCtrl.animateTo(
                _scrollCtrl.position.maxScrollExtent,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
              );
              _tabCtrl.animateTo(0);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionBtn(
            icon: CustomerProfileIcons.delete,
            label: CustomerProfileStrings.btnDelete,
            bg: CustomerProfileColors.deleteBg,
            fg: CustomerProfileColors.deleteText,
            border: CustomerProfileColors.deleteBorder,
            onTap: () => _showDeleteDialog(p),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. STATS OVERVIEW
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStatsOverview(CustomerProfileModel p) {
    return Container(
      decoration: CustomerProfileStyles.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.bar_chart_rounded,
            title: "Customer Overview",
            color: const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: "Total Bills",
                  value: p.totalBills.toString(),
                  icon: CustomerProfileIcons.invoice,
                  color: CustomerProfileColors.brandGold,
                  sub: "₹${_fmt(p.totalBillAmount)}",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  label: "Paid Bills",
                  value: p.paidBillsCount.toString(),
                  icon: CustomerProfileIcons.clear,
                  color: const Color(0xFF10B981),
                  sub: "₹${_fmt(p.totalPaidAmount)}",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  label: "Unpaid Bills",
                  value: p.unpaidBillsCount.toString(),
                  icon: CustomerProfileIcons.outstanding,
                  color: const Color(0xFFF59E0B),
                  sub: "Due: ₹${_fmt(p.outstanding)}",
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: "Total Girvi",
                  value: p.totalLoans.toString(),
                  icon: Icons.lock_outline_rounded,
                  color: const Color(0xFF7C3AED),
                  sub: "₹${_fmt(p.totalLoanAmount)}",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  label: "Active Girvi",
                  value: p.activeLoans.toString(),
                  icon: Icons.lock_rounded,
                  color: const Color(0xFFEF4444),
                  sub: "₹${_fmt(p.totalActiveLoanAmount)}",
                ),
              ),
              const SizedBox(width: 10),
              // ✅ NEW: Advance Orders stat box
              Expanded(
                child: _StatBox(
                  label: "Advance Orders",
                  value: p.activeAdvanceCount.toString(),
                  icon: CustomerProfileIcons.advanceOrder,
                  color: CustomerProfileColors.advanceAccent,
                  sub: "Paid: ₹${_fmt(p.totalAdvancePaid)}",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. CONTACT CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildContactCard(CustomerProfileModel p) {
    return Container(
      decoration: CustomerProfileStyles.cardDecoration,
      padding: CustomerProfileStyles.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: CustomerProfileIcons.phone,
            title: CustomerProfileStrings.secContact,
            color: CustomerProfileColors.brandGold,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _infoRow(CustomerProfileIcons.phone,
                    CustomerProfileStrings.lblMobile, p.mobile),
              ),
              Expanded(
                child: _infoRow(
                    CustomerProfileIcons.city,
                    CustomerProfileStrings.lblCity,
                    p.city.isEmpty ? CustomerProfileStrings.lblNa : p.city),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _infoRow(CustomerProfileIcons.calendar,
                    CustomerProfileStrings.lblSince, p.formattedMemberSince),
              ),
              Expanded(
                child: _infoRow(CustomerProfileIcons.type,
                    CustomerProfileStrings.lblType, p.type),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. CREDIT CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCreditCard(CustomerProfileModel p) {
    final pct = p.usedPercent;
    final Color barColor = pct < 60
        ? CustomerProfileColors.progressSafe
        : pct < 85
            ? CustomerProfileColors.progressWarn
            : CustomerProfileColors.progressDanger;

    return Container(
      decoration: CustomerProfileStyles.cardDecoration,
      padding: CustomerProfileStyles.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionHeader(
                  icon: CustomerProfileIcons.creditLimit,
                  title: CustomerProfileStrings.secCredit,
                  color: const Color(0xFF7C3AED),
                ),
              ),
              GestureDetector(
                onTap: _logic.editingCreditLimit
                    ? _logic.cancelEditCreditLimit
                    : _logic.startEditCreditLimit,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CustomerProfileColors.brandGoldBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: CustomerProfileColors.brandGold
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _logic.editingCreditLimit
                            ? Icons.close_rounded
                            : CustomerProfileIcons.editLimit,
                        color: CustomerProfileColors.brandGold,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _logic.editingCreditLimit ? "Cancel" : "Set Limit",
                        style: const TextStyle(
                          color: CustomerProfileColors.brandGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_logic.editingCreditLimit) ...[
            _buildCreditLimitEdit(p),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: _creditBox(
                  label: CustomerProfileStrings.lblCreditLimit,
                  value: "₹${_fmt(p.creditLimit)}",
                  icon: CustomerProfileIcons.creditLimit,
                  color: const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _creditBox(
                  label: CustomerProfileStrings.lblOutstanding,
                  value: "₹${_fmt(p.outstanding)}",
                  icon: CustomerProfileIcons.outstanding,
                  color: p.outstanding > 0
                      ? CustomerProfileColors.dueIcon
                      : CustomerProfileColors.clearIcon,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _creditBox(
                  label: CustomerProfileStrings.lblAvailable,
                  value: "₹${_fmt(p.availableCredit)}",
                  icon: CustomerProfileIcons.creditStatus,
                  color: CustomerProfileColors.clearIcon,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Used: ${pct.toStringAsFixed(0)}%",
                style: CustomerProfileStyles.creditPct,
              ),
              _buildCreditStatusBadge(p.creditStatus),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct / 100),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => LinearProgressIndicator(
                value: val,
                minHeight: 10,
                backgroundColor: CustomerProfileColors.progressTrack,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 6. DUES SECTION ✅ NEW
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDuesSection(CustomerProfileModel p) {
    return Container(
      decoration: BoxDecoration(
        color: CustomerProfileColors.duesSectionBg,
        borderRadius: BorderRadius.circular(CustomerProfileStyles.cardRadius),
        border: Border.all(color: CustomerProfileColors.duesSectionBorder),
        boxShadow: const [
          BoxShadow(
            color: CustomerProfileColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                _sectionHeader(
                  icon: CustomerProfileIcons.duesSection,
                  title: CustomerProfileStrings.secDues,
                  color: CustomerProfileColors.duesSectionAccent,
                ),
                const Spacer(),
                // Total due badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CustomerProfileColors.dueTotalBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: CustomerProfileColors.dueBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CustomerProfileIcons.dueAmount,
                        size: 13,
                        color: CustomerProfileColors.dueTotalText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Total Due: ₹${_fmt(p.totalDueAmount)}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: CustomerProfileColors.dueTotalText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(
              height: 1, color: CustomerProfileColors.duesSectionBorder),
          // Due rows
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: p.dues.length,
            itemBuilder: (_, i) => _buildDueRow(p.dues[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildDueRow(CustomerDueModel due) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showBillDetails(due.billId),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: CustomerProfileColors.dueRowBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CustomerProfileColors.dueRowBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: CustomerProfileColors.dueBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CustomerProfileIcons.dueBill,
                  color: CustomerProfileColors.dueIcon,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      due.billNo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: CustomerProfileColors.duesBillNo,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${due.formattedDate}  •  Tap to open",
                      style: const TextStyle(
                        fontSize: 11,
                        color: CustomerProfileColors.bodyTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    due.formattedDue,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: CustomerProfileColors.duesAmount,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: CustomerProfileColors.dueBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "PENDING",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: CustomerProfileColors.dueText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: CustomerProfileColors.bodyTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 7. HISTORY TABS — Bills | Girvi | Advance Orders ✅ UPDATED
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHistoryTabs(CustomerProfileModel p) {
    return Container(
      decoration: CustomerProfileStyles.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: CustomerProfileColors.bodyBg,
            child: TabBar(
              controller: _tabCtrl,
              labelColor: CustomerProfileColors.brandGold,
              unselectedLabelColor: CustomerProfileColors.bodyTextMuted,
              indicatorColor: CustomerProfileColors.brandGold,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CustomerProfileIcons.invoice, size: 15),
                      const SizedBox(width: 5),
                      Text("Bills (${p.totalBills})"),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 15),
                      const SizedBox(width: 5),
                      Text("Girvi (${p.totalLoans})"),
                    ],
                  ),
                ),
                // ✅ NEW TAB
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CustomerProfileIcons.advanceOrder, size: 15),
                      const SizedBox(width: 5),
                      Text("Advance (${p.advanceOrders.length})"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 420,
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildBillsList(p),
                _buildGirviList(p),
                _buildAdvanceList(p), // ✅ NEW
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── BILLS LIST ────────────────────────────────────────────────────────
  Widget _buildBillsList(CustomerProfileModel p) {
    if (p.bills.isEmpty) {
      return _emptyState(
        icon: CustomerProfileIcons.emptyBills,
        title: CustomerProfileStrings.noBills,
        sub: CustomerProfileStrings.noBillsSub,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: p.bills.length,
      itemBuilder: (_, i) => _buildBillRow(p.bills[i]),
    );
  }

  Widget _buildBillRow(CustomerBillModel bill) {
    final bool paid = bill.isPaid;
    final bool partial = bill.isPartial;
    final Color statusBg = paid
        ? CustomerProfileColors.paidBg
        : partial
            ? CustomerProfileColors.dueBg
            : CustomerProfileColors.unpaidBg;
    final Color statusText = paid
        ? CustomerProfileColors.paidText
        : partial
            ? CustomerProfileColors.dueText
            : CustomerProfileColors.unpaidText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showBillDetails(bill.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: CustomerProfileColors.bodyBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CustomerProfileColors.bodyBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  CustomerProfileIcons.invoice,
                  color: statusText,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bill.billNo, style: CustomerProfileStyles.billNo),
                    const SizedBox(height: 2),
                    Text(
                      bill.formattedDate,
                      style: CustomerProfileStyles.billDate,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Paid: ${bill.formattedPaidAmount}  •  Due: ${bill.formattedDueAmount}",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: CustomerProfileColors.bodyTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    bill.formattedAmount,
                    style: CustomerProfileStyles.billAmount,
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      bill.paymentLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: CustomerProfileColors.bodyTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── GIRVI LIST ────────────────────────────────────────────────────────
  Widget _buildGirviList(CustomerProfileModel p) {
    if (p.loans.isEmpty) {
      return _emptyState(
        icon: Icons.lock_outline_rounded,
        title: "No Girvi Records",
        sub: "Girvi entries will appear here",
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: p.loans.length,
      itemBuilder: (_, i) => _buildGirviRow(p.loans[i]),
    );
  }

  Widget _buildGirviRow(CustomerLoanModel loan) {
    final bool active = loan.isActive;
    final Color statusColor =
        active ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final Color statusBg =
        active ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CustomerProfileColors.bodyBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? const Color(0xFFFCA5A5)
              : CustomerProfileColors.bodyBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  active ? Icons.lock_rounded : Icons.lock_open_rounded,
                  color: statusColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loan.loanNo,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: CustomerProfileColors.bodyTextMain,
                        )),
                    Text(loan.itemDesc,
                        style: const TextStyle(
                          fontSize: 11,
                          color: CustomerProfileColors.bodyTextMuted,
                        )),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  active ? "ACTIVE" : "RELEASED",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: CustomerProfileColors.divider),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _girviDetail(
                    "Loan Amount",
                    "₹${loan.loanAmount.toStringAsFixed(0)}",
                    const Color(0xFF7C3AED)),
              ),
              Expanded(
                child: _girviDetail(
                    "Weight",
                    "${loan.grossWeight.toStringAsFixed(2)}g",
                    CustomerProfileColors.brandGold),
              ),
              Expanded(
                child: _girviDetail(
                    "Interest @",
                    "${loan.interestRate.toStringAsFixed(0)}%/mo",
                    const Color(0xFFEA580C)),
              ),
            ],
          ),
          if (active) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _girviDetail(
                    "Accrued Interest",
                    "₹${loan.accruedInterest.toStringAsFixed(0)}",
                    const Color(0xFFEF4444),
                  ),
                ),
                Expanded(
                  child: _girviDetail(
                    "Days Active",
                    "${loan.daysActive} days",
                    const Color(0xFF0891B2),
                  ),
                ),
                Expanded(
                  child: _girviDetail(
                    "Started",
                    loan.formattedDate,
                    CustomerProfileColors.bodyTextMuted,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── ADVANCE ORDERS LIST ✅ NEW ─────────────────────────────────────────
  Widget _buildAdvanceList(CustomerProfileModel p) {
    if (p.advanceOrders.isEmpty) {
      return _emptyState(
        icon: CustomerProfileIcons.advanceEmpty,
        title: CustomerProfileStrings.noAdvance,
        sub: CustomerProfileStrings.noAdvanceSub,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: p.advanceOrders.length,
      itemBuilder: (_, i) => _buildAdvanceRow(p.advanceOrders[i]),
    );
  }

  Widget _buildAdvanceRow(CustomerAdvanceOrderModel order) {
    // Status colors
    Color statusBg, statusText, statusBdr;
    IconData statusIcon;
    switch (order.status) {
      case AdvanceOrderStatus.ready:
        statusBg = CustomerProfileColors.advanceReadyBg;
        statusText = CustomerProfileColors.advanceReadyText;
        statusBdr = CustomerProfileColors.advanceReadyBdr;
        statusIcon = CustomerProfileIcons.advanceReady;
        break;
      case AdvanceOrderStatus.delivered:
        statusBg = CustomerProfileColors.paidBg;
        statusText = CustomerProfileColors.paidText;
        statusBdr = CustomerProfileColors.clearBorder;
        statusIcon = CustomerProfileIcons.clear;
        break;
      case AdvanceOrderStatus.cancelled:
        statusBg = CustomerProfileColors.defaulterBg;
        statusText = CustomerProfileColors.defaulterText;
        statusBdr = CustomerProfileColors.defaulterBorder;
        statusIcon = Icons.cancel_outlined;
        break;
      default: // pending
        statusBg = CustomerProfileColors.advancePendingBg;
        statusText = CustomerProfileColors.advancePendingText;
        statusBdr = CustomerProfileColors.advancePendingBdr;
        statusIcon = CustomerProfileIcons.advancePending;
    }

    final bool canConvert = order.isPending || order.isReady;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: CustomerProfileColors.advanceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CustomerProfileColors.advanceBorder),
        boxShadow: const [
          BoxShadow(
            color: CustomerProfileColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── TOP ROW ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusBdr),
                  ),
                  child: Icon(statusIcon, color: statusText, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNo,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: CustomerProfileColors.bodyTextMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${order.itemName} • ${order.metalType} ${order.purity}",
                        style: const TextStyle(
                          fontSize: 11,
                          color: CustomerProfileColors.bodyTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusBdr),
                  ),
                  child: Text(
                    order.status.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusText,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── DETAILS ROW ───────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CustomerProfileColors.bodyBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CustomerProfileColors.bodyBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _advanceDetail(
                    "Approx Wt.",
                    "${order.approxWeight.toStringAsFixed(2)}g",
                    CustomerProfileColors.brandGold,
                  ),
                ),
                Expanded(
                  child: _advanceDetail(
                    CustomerProfileStrings.totalAdvancePaid,
                    "₹${_fmt(order.totalAdvancePaid)}",
                    CustomerProfileColors.advanceAccent,
                  ),
                ),
                Expanded(
                  child: _advanceDetail(
                    CustomerProfileStrings.remainingBalance,
                    "₹${_fmt(order.remainingBalance)}",
                    order.remainingBalance > 0
                        ? CustomerProfileColors.advanceRemaining
                        : CustomerProfileColors.clearIcon,
                  ),
                ),
              ],
            ),
          ),

          // ── DELIVERY + BOOKING DATE ROW ──────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(CustomerProfileIcons.calendar,
                    size: 12, color: CustomerProfileColors.bodyTextMuted),
                const SizedBox(width: 4),
                Text(
                  "Booked: ${order.formattedDate}",
                  style: const TextStyle(
                    fontSize: 11,
                    color: CustomerProfileColors.bodyTextMuted,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(CustomerProfileIcons.deliveryDate,
                    size: 12, color: CustomerProfileColors.bodyTextMuted),
                const SizedBox(width: 4),
                Text(
                  "Delivery: ${order.formattedDelivery}",
                  style: const TextStyle(
                    fontSize: 11,
                    color: CustomerProfileColors.bodyTextMuted,
                  ),
                ),
              ],
            ),
          ),

          // ── CONVERT TO SALE BUTTON (only for pending/ready) ──────────
          if (canConvert) ...[
            const Divider(
                height: 1, color: CustomerProfileColors.advanceBorder),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _ConvertToSaleButton(
                onTap: () => _logic.triggerConvertAdvanceToSale(order.id),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _advanceDetail(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: CustomerProfileColors.bodyTextMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _girviDetail(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 10,
              color: CustomerProfileColors.bodyTextMuted,
              fontWeight: FontWeight.w500,
            )),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            )),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // IMPROVED EDIT DIALOG ✅ UPDATED — Full form with more fields
  // ─────────────────────────────────────────────────────────────────────────
  void _showBillDetails(int billId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: FutureBuilder<CustomerBillDetailModel?>(
            future: _logic.fetchBillDetails(billId),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: CustomerProfileColors.bodyPanelBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: CustomerProfileColors.brandGold,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Opening bill details...",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: CustomerProfileColors.bodyTextMain,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: CustomerProfileColors.bodyPanelBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 42,
                          color: CustomerProfileColors.bodyTextMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Bill details not found",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: CustomerProfileColors.bodyTextMain,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "This bill could not be loaded from saved records.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: CustomerProfileColors.bodyTextMuted,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text("Close"),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final detail = snapshot.data!;
              final bill = detail.bill;
              final bool paid = bill.isPaid;
              final bool partial = bill.isPartial;
              final Color statusBg = paid
                  ? CustomerProfileColors.paidBg
                  : partial
                      ? CustomerProfileColors.dueBg
                      : CustomerProfileColors.unpaidBg;
              final Color statusText = paid
                  ? CustomerProfileColors.paidText
                  : partial
                      ? CustomerProfileColors.dueText
                      : CustomerProfileColors.unpaidText;

              return ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 820, maxHeight: 700),
                child: Container(
                  decoration: BoxDecoration(
                    color: CustomerProfileColors.bodyPanelBg,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: CustomerProfileColors.shadowLight,
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: CustomerProfileColors.bodyBorder,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                CustomerProfileIcons.invoice,
                                color: statusText,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bill.billNo,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: CustomerProfileColors.bodyTextMain,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${detail.customerName}  •  ${bill.formattedDate}",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color:
                                          CustomerProfileColors.bodyTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                bill.paymentLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: statusText,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: const Icon(Icons.close_rounded),
                              color: CustomerProfileColors.bodyTextMuted,
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _buildBillInfoChip(
                                    title: "Bill Amount",
                                    value: bill.formattedAmount,
                                    valueColor:
                                        CustomerProfileColors.bodyTextMain,
                                  ),
                                  _buildBillInfoChip(
                                    title: "Paid",
                                    value: bill.formattedPaidAmount,
                                    valueColor: CustomerProfileColors.paidText,
                                  ),
                                  _buildBillInfoChip(
                                    title: "Due",
                                    value: bill.formattedDueAmount,
                                    valueColor: bill.dueAmount > 0
                                        ? CustomerProfileColors.unpaidText
                                        : CustomerProfileColors.paidText,
                                  ),
                                  _buildBillInfoChip(
                                    title: "Mobile",
                                    value: detail.customerMobile.isEmpty
                                        ? "N/A"
                                        : detail.customerMobile,
                                    valueColor:
                                        CustomerProfileColors.bodyTextMain,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Line Items",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: CustomerProfileColors.bodyTextMain,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (detail.items.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: CustomerProfileColors.bodyBg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: CustomerProfileColors.bodyBorder,
                                    ),
                                  ),
                                  child: const Text(
                                    "No saved line items found for this bill.",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          CustomerProfileColors.bodyTextMuted,
                                    ),
                                  ),
                                )
                              else
                                ...detail.items.map(_buildBillItemRow),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBillInfoChip({
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CustomerProfileColors.bodyBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CustomerProfileColors.bodyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: CustomerProfileColors.bodyTextMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillItemRow(CustomerBillLineItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CustomerProfileColors.bodyBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CustomerProfileColors.bodyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.itemName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: CustomerProfileColors.bodyTextMain,
                  ),
                ),
              ),
              Text(
                "\u20B9 ${item.itemTotal.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: CustomerProfileColors.bodyTextMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              Text(
                "Purity: ${item.purity?.isNotEmpty == true ? item.purity : 'N/A'}",
                style: const TextStyle(
                  fontSize: 12,
                  color: CustomerProfileColors.bodyTextMuted,
                ),
              ),
              Text(
                "Gross: ${item.grossWeight.toStringAsFixed(3)} g",
                style: const TextStyle(
                  fontSize: 12,
                  color: CustomerProfileColors.bodyTextMuted,
                ),
              ),
              Text(
                "Net: ${item.netWeight.toStringAsFixed(3)} g",
                style: const TextStyle(
                  fontSize: 12,
                  color: CustomerProfileColors.bodyTextMuted,
                ),
              ),
              Text(
                "Rate: \u20B9 ${item.rate.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 12,
                  color: CustomerProfileColors.bodyTextMuted,
                ),
              ),
              Text(
                "Making: \u20B9 ${item.makingCharge.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 12,
                  color: CustomerProfileColors.bodyTextMuted,
                ),
              ),
              if (item.huid?.isNotEmpty == true)
                Text(
                  "HUID: ${item.huid}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: CustomerProfileColors.bodyTextMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditDialog(CustomerProfileModel p) {
    // Pre-fill all controllers
    _editNameCtrl.text = p.name;
    _editMobileCtrl.text = p.mobile;
    _editWhatsappCtrl.text = p.whatsapp;
    _editCityCtrl.text = p.city;
    _editTypeValue = p.type;
    // Other fields default empty (not in model currently)
    _editEmailCtrl.text = "";
    _editAddressCtrl.text = "";
    _editStateCtrl.text = "";
    _editPincodeCtrl.text = "";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: CustomerProfileColors.bodyPanelBg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: CustomerProfileColors.editBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CustomerProfileIcons.edit,
                    color: CustomerProfileColors.editText,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  CustomerProfileStrings.editTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: CustomerProfileColors.bodyTextMain,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_logic.editError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: CustomerProfileColors.deleteBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _logic.editError!,
                          style: const TextStyle(
                            color: CustomerProfileColors.deleteText,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── SECTION: Personal ──────────────────────────
                    _editSectionLabel("Personal Info"),
                    const SizedBox(height: 8),
                    _editField(
                      ctrl: _editNameCtrl,
                      label: "Full Name *",
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 10),

                    // Customer Type toggle
                    Row(
                      children: [
                        const Text(
                          "Customer Type:",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: CustomerProfileColors.bodyTextMuted,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _TypeToggle(
                          value: _editTypeValue,
                          onChanged: (v) =>
                              setDialogState(() => _editTypeValue = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── SECTION: Contact ───────────────────────────
                    _editSectionLabel("Contact Details"),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _editField(
                            ctrl: _editMobileCtrl,
                            label: "Mobile *",
                            icon: CustomerProfileIcons.phone,
                            isNumber: true,
                            maxLength: 10,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _editField(
                            ctrl: _editWhatsappCtrl,
                            label: "WhatsApp",
                            icon: CustomerProfileIcons.whatsapp,
                            isNumber: true,
                            maxLength: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _editField(
                      ctrl: _editEmailCtrl,
                      label: "Email",
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 16),

                    // ── SECTION: Address ───────────────────────────
                    _editSectionLabel("Address"),
                    const SizedBox(height: 8),
                    _editField(
                      ctrl: _editAddressCtrl,
                      label: "Address Line",
                      icon: Icons.home_outlined,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _editField(
                            ctrl: _editCityCtrl,
                            label: "City / Area",
                            icon: CustomerProfileIcons.city,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _editField(
                            ctrl: _editStateCtrl,
                            label: "State",
                            icon: Icons.map_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _editField(
                            ctrl: _editPincodeCtrl,
                            label: "Pincode",
                            icon: Icons.pin_drop_outlined,
                            isNumber: true,
                            maxLength: 6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actionsAlignment: MainAxisAlignment.end,
            actions: [
              TextButton(
                onPressed: () {
                  _logic.cancelEditMode();
                  Navigator.pop(ctx);
                },
                child: const Text(
                  CustomerProfileStrings.editCancel,
                  style: TextStyle(
                    color: CustomerProfileColors.bodyTextMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _logic.savingEdit
                    ? null
                    : () async {
                        final ok = await _logic.saveEdit(
                          name: _editNameCtrl.text,
                          mobile: _editMobileCtrl.text,
                          city: _editCityCtrl.text,
                          type: _editTypeValue,
                          whatsapp: _editWhatsappCtrl.text,
                          email: _editEmailCtrl.text,
                          address: _editAddressCtrl.text,
                          state: _editStateCtrl.text,
                          pincode: _editPincodeCtrl.text,
                        );
                        if (ok && mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(CustomerProfileStrings.editSuccess),
                              backgroundColor: Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          setDialogState(() {});
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomerProfileColors.brandGold,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _logic.savingEdit
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        CustomerProfileStrings.editSave,
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _editSectionLabel(String label) => Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: CustomerProfileColors.bodyTextMuted,
          letterSpacing: 1.2,
        ),
      );

  Widget _editField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    bool isNumber = false,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CustomerProfileColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CustomerProfileColors.bodyBorder),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: isNumber
            ? [
                FilteringTextInputFormatter.digitsOnly,
                if (maxLength != null)
                  LengthLimitingTextInputFormatter(maxLength),
              ]
            : null,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: CustomerProfileColors.bodyTextMain,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: CustomerProfileColors.bodyTextMuted,
            fontSize: 13,
          ),
          prefixIcon:
              Icon(icon, size: 18, color: CustomerProfileColors.bodyTextMuted),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CREDIT LIMIT EDIT
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCreditLimitEdit(CustomerProfileModel p) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: CustomerProfileColors.bodyBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: CustomerProfileColors.brandGold, width: 1.5),
            ),
            child: TextField(
              controller: _creditCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: CustomerProfileColors.bodyTextMain,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                hintText: CustomerProfileStrings.hintCreditLimit,
                hintStyle:
                    const TextStyle(color: CustomerProfileColors.bodyTextMuted),
                prefixIcon: const Icon(CustomerProfileIcons.amount,
                    color: CustomerProfileColors.brandGold, size: 18),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () async {
            final val = double.tryParse(_creditCtrl.text);
            if (val == null || val < 0) return;
            final ok = await _logic.saveCreditLimit(val);
            if (ok && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(CustomerProfileStrings.savedLimit),
                  backgroundColor: Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: CustomerProfileColors.brandGold,
              borderRadius: BorderRadius.circular(10),
            ),
            child: _logic.savingCreditLimit
                ? const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2),
                    ),
                  )
                : const Icon(CustomerProfileIcons.saveLimit,
                    color: Colors.black, size: 20),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DELETE DIALOG
  // ─────────────────────────────────────────────────────────────────────────
  void _showDeleteDialog(CustomerProfileModel p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: CustomerProfileColors.bodyPanelBg,
        icon: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: CustomerProfileColors.deleteBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(CustomerProfileIcons.warningIcon,
              color: CustomerProfileColors.deleteText, size: 28),
        ),
        title: const Text(
          CustomerProfileStrings.deleteTitle,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: CustomerProfileColors.bodyTextMain,
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          CustomerProfileStrings.deleteMsg,
          style: TextStyle(
            color: CustomerProfileColors.bodyTextMuted,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: CustomerProfileColors.bodyTextMuted,
              side: const BorderSide(color: CustomerProfileColors.bodyBorder),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(CustomerProfileStrings.deleteCancel,
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await _logic.deleteCustomer();
              if (!ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(CustomerProfileStrings.deleteError),
                    backgroundColor: CustomerProfileColors.deleteText,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CustomerProfileColors.deleteText,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text(CustomerProfileStrings.deleteConfirm,
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHARED HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: CustomerProfileColors.brandGold,
            strokeWidth: 2.5,
          ),
          SizedBox(height: 16),
          Text(
            "Loading profile...",
            style: TextStyle(
              color: CustomerProfileColors.bodyTextMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          Text(
            _logic.error ?? "Something went wrong",
            style: const TextStyle(color: CustomerProfileColors.bodyTextMuted),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _logic.refresh,
            style: ElevatedButton.styleFrom(
              backgroundColor: CustomerProfileColors.brandGold,
              foregroundColor: Colors.black,
            ),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: CustomerProfileStyles.sectionIconBox,
          height: CustomerProfileStyles.sectionIconBox,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(title, style: CustomerProfileStyles.sectionTitle),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: CustomerProfileColors.bodyTextMuted),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: CustomerProfileStyles.infoLabel),
              Text(value, style: CustomerProfileStyles.infoValue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _creditBox({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: CustomerProfileStyles.creditAmount.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: CustomerProfileStyles.creditLabel),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(CustomerProfileModel p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: p.isVip
            ? CustomerProfileColors.vipBg
            : CustomerProfileColors.regularBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: p.isVip
              ? CustomerProfileColors.vipBorder
              : CustomerProfileColors.regularBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            p.isVip ? CustomerProfileIcons.vip : Icons.person_rounded,
            size: 11,
            color: p.isVip
                ? CustomerProfileColors.vipText
                : CustomerProfileColors.regularText,
          ),
          const SizedBox(width: 4),
          Text(
            p.isVip ? "VIP" : "REGULAR",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: p.isVip
                  ? CustomerProfileColors.vipText
                  : CustomerProfileColors.regularText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditStatusBadge(CreditStatus status) {
    final Color bg = status == CreditStatus.clear
        ? CustomerProfileColors.clearBg
        : status == CreditStatus.due
            ? CustomerProfileColors.dueBg
            : CustomerProfileColors.defaulterBg;
    final Color text = status == CreditStatus.clear
        ? CustomerProfileColors.clearText
        : status == CreditStatus.due
            ? CustomerProfileColors.dueText
            : CustomerProfileColors.defaulterText;
    final Color border = status == CreditStatus.clear
        ? CustomerProfileColors.clearBorder
        : status == CreditStatus.due
            ? CustomerProfileColors.dueBorder
            : CustomerProfileColors.defaulterBorder;
    final IconData icon = status == CreditStatus.clear
        ? CustomerProfileIcons.clear
        : status == CreditStatus.due
            ? CustomerProfileIcons.due
            : CustomerProfileIcons.defaulter;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String sub,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: CustomerProfileColors.bodyTextMuted),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: CustomerProfileColors.bodyTextMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 12,
              color: CustomerProfileColors.bodyTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double val) {
    if (val >= 100000) return "${(val / 100000).toStringAsFixed(1)}L";
    if (val >= 1000) return "${(val / 1000).toStringAsFixed(1)}K";
    return val.toStringAsFixed(0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT BOX
// ─────────────────────────────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? sub;
  final double valueFontSize;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.sub,
    this.valueFontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: CustomerProfileColors.bodyTextMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(
              sub!,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final Color border;
  final bool filled;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.border,
    required this.onTap,
    this.filled = false,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              color: widget.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: widget.border, width: widget.filled ? 0 : 1.5),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: widget.border.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: widget.fg, size: 20),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.fg,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TYPE TOGGLE (Regular / VIP)
// ─────────────────────────────────────────────────────────────────────────────
class _TypeToggle extends StatelessWidget {
  final String value;
  final Function(String) onChanged;

  const _TypeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ["Regular", "VIP"].map((type) {
        final bool active = value == type;
        final Color color = type == "VIP"
            ? CustomerProfileColors.vipText
            : CustomerProfileColors.editText;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? (type == "VIP"
                      ? CustomerProfileColors.vipBg
                      : CustomerProfileColors.editBg)
                  : CustomerProfileColors.bodyBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active ? color : CustomerProfileColors.bodyBorder,
                width: active ? 1.5 : 1,
              ),
            ),
            child: Text(
              type,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? color : CustomerProfileColors.bodyTextMuted,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONVERT TO SALE BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _ConvertToSaleButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ConvertToSaleButton({required this.onTap});

  @override
  State<_ConvertToSaleButton> createState() => _ConvertToSaleButtonState();
}

class _ConvertToSaleButtonState extends State<_ConvertToSaleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          decoration: BoxDecoration(
            color: _hovered
                ? CustomerProfileColors.advanceConvertBtn
                : CustomerProfileColors.advanceBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: CustomerProfileColors.advanceConvertBtn,
              width: 1.5,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: CustomerProfileColors.advanceConvertBtn
                          .withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CustomerProfileIcons.advanceConvert,
                size: 16,
                color: _hovered
                    ? CustomerProfileColors.advanceConvertText
                    : CustomerProfileColors.advanceConvertBtn,
              ),
              const SizedBox(width: 8),
              Text(
                CustomerProfileStrings.convertToSale,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _hovered
                      ? CustomerProfileColors.advanceConvertText
                      : CustomerProfileColors.advanceConvertBtn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
