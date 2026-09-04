// -----------------------------------------------------------------------------
// FILE: customer_profile_screen.dart
// CHANGE LOG:
//   - Added: Dues & Pending section (above history tabs)
//   - Edit button now shows full-form dialog (not just name/mobile/city)
//   - Advance card: tappable "Convert to Sale" button
// -----------------------------------------------------------------------------

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../theme/customer/customer_profile/customer_profile_theme.dart';
import '../../../logic/customer/customer_profile_logic.dart';
import '../../../logic/girvi/girvi_invoice_hub_controller.dart';
import '../../../models/customer/customer_profile/customer_profile_model.dart';
import '../add_customer/add_customer_screen.dart';
import 'customer_profile_app_bar.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

enum _SalesInvoicePdfMode { postedOriginal, currentStatement }

class CustomerProfileScreen extends StatefulWidget {
  final int customerId;
  final int? initialBillId;
  final VoidCallback? onBack;
  final Function(int customerId)? onNewSale;
  final Function(int billId)? onEditBill;
  final Function(int loanId)? onEditGirvi;
  final Function(int advanceOrderId)? onEditAdvance;
  final Function(int customerId, String billNo)? onCollectDue;
  final VoidCallback? onDeleted;

  /// Called when user taps "Convert to Sale" on an advance order.
  /// Passes advanceOrderId + customerId to parent for POS navigation.
  final Function(int advanceOrderId, int customerId)? onConvertAdvanceToSale;

  const CustomerProfileScreen({
    super.key,
    required this.customerId,
    this.initialBillId,
    this.onBack,
    this.onNewSale,
    this.onEditBill,
    this.onEditGirvi,
    this.onEditAdvance,
    this.onCollectDue,
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

  // Controller for the approved due limit.
  final TextEditingController _dueLimitCtrl = TextEditingController();

  // Kept temporarily for the legacy dialog code while the profile module is
  // migrated in stages. The Edit action now opens AddCustomerScreen instead.
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
  bool _deleteNavigationScheduled = false;
  int? _focusedInitialBillId;

  @override
  void initState() {
    super.initState();
    _logic = CustomerProfileLogic(
      customerId: widget.customerId,
      onConvertAdvanceToSale: widget.onConvertAdvanceToSale,
    );

    _tabCtrl = TabController(length: 3, vsync: this);

    _pageAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _pageAnim, curve: Curves.easeOut);

    _logic.addListener(_handleProfileStateChanged);
  }

  void _handleProfileStateChanged() {
    if (!mounted) return;
    if (_logic.state == ProfileState.loaded && _pageAnim.value == 0) {
      _pageAnim.forward();
    }
    if (_logic.state == ProfileState.deleted && !_deleteNavigationScheduled) {
      _deleteNavigationScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.onDeleted != null) {
          widget.onDeleted!();
        } else {
          widget.onBack?.call();
        }
      });
    }
  }

  @override
  void dispose() {
    _logic.removeListener(_handleProfileStateChanged);
    _logic.dispose();
    _pageAnim.dispose();
    _tabCtrl.dispose();
    _dueLimitCtrl.dispose();
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
      ),
      body: ListenableBuilder(
        listenable: _logic,
        builder: (context, _) {
          if (_logic.isLoading) return _buildLoading();
          if (_logic.state == ProfileState.deleting) {
            return _buildLoading(message: 'Deleting customer...');
          }
          if (_logic.state == ProfileState.deleted) {
            return _buildLoading(message: 'Returning to client directory...');
          }
          if (_logic.state == ProfileState.error) return _buildError();
          if (_logic.profile == null) return _buildError();
          return _buildBody(_logic.profile!);
        },
      ),
    );
  }

  // MAIN BODY
  Widget _buildBody(CustomerProfileModel p) {
    _scheduleInitialBillFocus(p);
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
            _buildAccountSnapshotCard(p),
            const SizedBox(height: 16),
            if (p.hasDues) ...[
              _buildDuesSection(p),
              const SizedBox(height: 16),
            ],
            _buildHistoryTabs(p),
          ],
        ),
      ),
    );
  }

  void _scheduleInitialBillFocus(CustomerProfileModel p) {
    final billId = widget.initialBillId;
    if (billId == null || _focusedInitialBillId == billId) return;

    CustomerBillModel? targetBill;
    for (final bill in p.bills) {
      if (bill.id == billId) {
        targetBill = bill;
        break;
      }
    }
    if (targetBill == null) return;

    _focusedInitialBillId = billId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tabCtrl.animateTo(0);
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      }
      _showBillActions(targetBill!);
    });
  }

  // 1. HERO CARD
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
                    _buildAccountStatusBadge(p.accountStatus),
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

  // 2. ACTION BUTTONS
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
            onTap: () => _openCustomerEditor(p),
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

  // 3. STATS OVERVIEW
  Widget _buildStatsOverview(CustomerProfileModel p) {
    return Container(
      decoration: CustomerProfileStyles.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.analytics_rounded,
            title: "Customer Portfolio Overview",
            color: const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: "Sales Bills",
                  value: p.totalBills.toString(),
                  icon: CustomerProfileIcons.invoice,
                  color: CustomerProfileColors.brandGold,
                  sub: "Total \u20B9${_fmt(p.totalBillAmount)}",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  label: "Settled Bills",
                  value: p.paidBillsCount.toString(),
                  icon: CustomerProfileIcons.clear,
                  color: const Color(0xFF10B981),
                  sub: "Paid \u20B9${_fmt(p.totalPaidAmount)}",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  label: "Due Bills",
                  value: p.unpaidBillsCount.toString(),
                  icon: CustomerProfileIcons.dueBills,
                  color: const Color(0xFFF59E0B),
                  sub: "Due \u20B9${_fmt(p.totalDueAmount)}",
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: "Girvi Tickets",
                  value: p.totalLoans.toString(),
                  icon: Icons.lock_outline_rounded,
                  color: const Color(0xFF7C3AED),
                  sub: "Principal \u20B9${_fmt(p.totalLoanAmount)}",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  label: "Active Girvi",
                  value: p.activeLoans.toString(),
                  icon: Icons.lock_rounded,
                  color: const Color(0xFFEF4444),
                  sub: "Balance \u20B9${_fmt(p.totalActiveLoanAmount)}",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  label: "Advance Orders",
                  value: p.activeAdvanceCount.toString(),
                  icon: CustomerProfileIcons.advanceOrder,
                  color: CustomerProfileColors.advanceAccent,
                  sub: "Advance \u20B9${_fmt(p.totalAdvancePaid)}",
                ),
              ),
            ],
          ),
          if (p.accountCreditBalance > 0.005) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  width: 1.4,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 20,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Customer Account Credit",
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    "\u20B9${_fmt(p.accountCreditBalance)}",
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

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
                child: _infoRow(
                    CustomerProfileIcons.phone,
                    CustomerProfileStrings.lblMobile,
                    p.mobile.isEmpty ? CustomerProfileStrings.lblNa : p.mobile),
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

  Widget _buildAccountSnapshotCard(CustomerProfileModel p) {
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
                  icon: Icons.account_balance_wallet_rounded,
                  title: CustomerProfileStrings.secAccountSnapshot,
                  color: const Color(0xFF7C3AED),
                ),
              ),
              GestureDetector(
                onTap: _logic.editingDueLimit
                    ? _logic.cancelEditDueLimit
                    : _logic.startEditDueLimit,
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
                        _logic.editingDueLimit
                            ? Icons.close_rounded
                            : CustomerProfileIcons.editLimit,
                        color: CustomerProfileColors.brandGold,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _logic.editingDueLimit ? "Cancel" : "Update Due Limit",
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
          if (_logic.editingDueLimit) ...[
            _buildDueLimitEdit(p),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: _ledgerSummaryBox(
                  title: "Due Ledger",
                  primaryLabel: CustomerProfileStrings.lblDueTotal,
                  primaryValue: "\u20B9${_fmt(p.totalDueAmount)}",
                  secondaryLabel: CustomerProfileStrings.lblDueBillValue,
                  secondaryValue: "\u20B9${_fmt(p.totalDueBillAmount)}",
                  tertiaryLabel: CustomerProfileStrings.lblDueLimit,
                  tertiaryValue: "\u20B9${_fmt(p.dueLimit)}",
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFFEA580C),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ledgerSummaryBox(
                  title: "Girvi Ledger",
                  primaryLabel: CustomerProfileStrings.lblGirviBalance,
                  primaryValue: "\u20B9${_fmt(p.totalActiveLoanAmount)}",
                  secondaryLabel: CustomerProfileStrings.lblGirviTotal,
                  secondaryValue: "\u20B9${_fmt(p.totalLoanAmount)}",
                  tertiaryLabel: "Active Tickets",
                  tertiaryValue: p.activeLoans.toString(),
                  icon: Icons.lock_rounded,
                  color: const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ledgerSummaryBox(
                  title: "Interest Ledger",
                  primaryLabel: CustomerProfileStrings.lblInterestAccrued,
                  primaryValue: "\u20B9${_fmt(p.totalInterestAccrued)}",
                  secondaryLabel: CustomerProfileStrings.lblInterestBase,
                  secondaryValue: "\u20B9${_fmt(p.totalActiveLoanAmount)}",
                  tertiaryLabel: CustomerProfileStrings.lblGirviReceivable,
                  tertiaryValue: "\u20B9${_fmt(p.totalGirviReceivable)}",
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF0F766E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
                        "Total Due: \u20B9${_fmt(p.totalDueAmount)}",
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
        onTap: () => _showBillActions(
          CustomerBillModel(
            id: due.billId,
            billNo: due.billNo,
            totalAmount: due.totalAmount,
            paidAmount: due.paidAmount,
            status: due.paidAmount > 0 ? 'PARTIAL' : 'UNPAID',
            billDate: due.billDate,
            sourceAdvanceOrderId: due.sourceAdvanceOrderId,
            sourceAdvanceOrderNo: due.sourceAdvanceOrderNo,
          ),
        ),
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
                      "${due.formattedDate} | Open invoice actions",
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
                Icons.more_horiz_rounded,
                size: 18,
                color: CustomerProfileColors.bodyTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                _buildAdvanceList(p),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
        onTap: () => _showBillActions(bill),
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
                      "Paid ${bill.formattedPaidAmount} | Due ${bill.formattedDueAmount}",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: CustomerProfileColors.bodyTextMuted,
                      ),
                    ),
                    if (bill.isFromAdvanceOrder) ...[
                      const SizedBox(height: 5),
                      _advanceSourceChip(bill.advanceSourceLabel),
                    ],
                    if (bill.hasLinkedDocuments) ...[
                      const SizedBox(height: 6),
                      _billLinkedDocumentStrip(bill),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      bill.formattedAmount,
                      style: CustomerProfileStyles.billAmount,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 6,
                      runSpacing: 6,
                      children: _billStatusChips(
                        bill,
                        paymentBg: statusBg,
                        paymentText: statusText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.more_horiz_rounded,
                size: 18,
                color: CustomerProfileColors.bodyTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _billStatusChips(
    CustomerBillModel bill, {
    required Color paymentBg,
    required Color paymentText,
  }) {
    final chips = <Widget>[
      _BillStatusChip(
        label: bill.paymentLabel,
        backgroundColor: paymentBg,
        textColor: paymentText,
      ),
    ];

    if (bill.lifecycleLabel.isNotEmpty) {
      chips.add(
        _BillStatusChip(
          label: bill.lifecycleLabel,
          backgroundColor: _billLifecycleBg(bill),
          textColor: _billLifecycleText(bill),
        ),
      );
    }
    if (bill.returnProgressLabel.isNotEmpty) {
      chips.add(
        _BillStatusChip(
          label: bill.returnProgressLabel,
          backgroundColor: CustomerProfileColors.brandGoldLight,
          textColor: CustomerProfileColors.bodyTextMain,
        ),
      );
    }
    if (bill.returnedAmount > 0.009) {
      chips.add(
        _BillStatusChip(
          label: 'RETURN ${bill.formattedReturnedAmount}',
          backgroundColor: CustomerProfileColors.advanceBg,
          textColor: CustomerProfileColors.advanceAccent,
        ),
      );
    }
    return chips;
  }

  Color _billLifecycleBg(CustomerBillModel bill) {
    if (bill.isCancelled) return CustomerProfileColors.deleteBg;
    if (bill.hasReturnActivity) return CustomerProfileColors.dueBg;
    return CustomerProfileColors.editBg;
  }

  Color _billLifecycleText(CustomerBillModel bill) {
    if (bill.isCancelled) return CustomerProfileColors.deleteText;
    if (bill.hasReturnActivity) return CustomerProfileColors.dueText;
    return CustomerProfileColors.editText;
  }

  Widget _billLinkedDocumentStrip(CustomerBillModel bill) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.account_tree_rounded,
          size: 13,
          color: CustomerProfileColors.historyText,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            bill.linkedDocumentSummary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: CustomerProfileColors.bodyTextMain,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGirviList(CustomerProfileModel p) {
    if (p.loans.isEmpty) {
      return _emptyState(
        icon: Icons.lock_outline_rounded,
        title: "No Girvi tickets yet",
        sub: "Pledge records will appear here after the first Girvi entry.",
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showGirviActions(loan),
        child: Container(
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: CustomerProfileColors.bodyTextMuted,
                            )),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.more_horiz_rounded,
                    size: 20,
                    color: CustomerProfileColors.bodyTextMuted,
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
                      "Girvi Principal",
                      "\u20B9${loan.loanAmount.toStringAsFixed(0)}",
                      const Color(0xFF7C3AED),
                    ),
                  ),
                  Expanded(
                    child: _girviDetail(
                      "Weight",
                      "${loan.grossWeight.toStringAsFixed(2)} g",
                      CustomerProfileColors.brandGold,
                    ),
                  ),
                  Expanded(
                    child: _girviDetail(
                      "Interest Rate",
                      "${loan.interestRate.toStringAsFixed(0)}%",
                      const Color(0xFFEA580C),
                    ),
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
                        "\u20B9${loan.accruedInterest.toStringAsFixed(0)}",
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
                        "Started On",
                        loan.formattedDate,
                        CustomerProfileColors.bodyTextMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

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

    return GestureDetector(
      onTap: () => _showAdvanceActions(order),
      child: Container(
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
                          "${order.itemName} | ${order.metalType} ${order.purity}",
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
                      "Approx. Weight",
                      "${order.approxWeight.toStringAsFixed(2)}g",
                      CustomerProfileColors.brandGold,
                    ),
                  ),
                  Expanded(
                    child: _advanceDetail(
                      CustomerProfileStrings.totalAdvancePaid,
                      "\u20B9${_fmt(order.totalAdvancePaid)}",
                      CustomerProfileColors.advanceAccent,
                    ),
                  ),
                  Expanded(
                    child: _advanceDetail(
                      CustomerProfileStrings.remainingBalance,
                      "\u20B9${_fmt(order.remainingBalance)}",
                      order.remainingBalance > 0
                          ? CustomerProfileColors.advanceRemaining
                          : CustomerProfileColors.clearIcon,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(CustomerProfileIcons.calendar,
                      size: 12, color: CustomerProfileColors.bodyTextMuted),
                  const SizedBox(width: 4),
                  Text(
                    "Booked ${order.formattedDate}",
                    style: const TextStyle(
                      fontSize: 11,
                      color: CustomerProfileColors.bodyTextMuted,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(CustomerProfileIcons.deliveryDate,
                      size: 12, color: CustomerProfileColors.bodyTextMuted),
                  const SizedBox(width: 4),
                  Text(
                    "Delivery ${order.formattedDelivery}",
                    style: const TextStyle(
                      fontSize: 11,
                      color: CustomerProfileColors.bodyTextMuted,
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _advanceSourceChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: CustomerProfileColors.advanceBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CustomerProfileColors.advanceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CustomerProfileIcons.advanceOrder,
            size: 11,
            color: CustomerProfileColors.advanceAccent,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: CustomerProfileColors.advanceAccent,
            ),
          ),
        ],
      ),
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

  Future<void> _openCustomerEditor(CustomerProfileModel profile) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (editorContext) => AddCustomerScreen(
          customerId: profile.id,
          onBack: () => Navigator.of(editorContext).pop(false),
          onSaved: () => Navigator.of(editorContext).pop(true),
        ),
      ),
    );

    if (updated == true && mounted) {
      await _logic.refresh();
    }
  }

  // ignore: unused_element
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
                        final dialogNavigator = Navigator.of(ctx);
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
                          dialogNavigator.pop();
                          AppFeedback.success(
                            context,
                            message: CustomerProfileStrings.editSuccess,
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
        style: const TextStyle(
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

  // Due limit edit
  Widget _buildDueLimitEdit(CustomerProfileModel p) {
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
              controller: _dueLimitCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: CustomerProfileColors.bodyTextMain,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14),
                hintText: CustomerProfileStrings.hintDueLimit,
                hintStyle:
                    TextStyle(color: CustomerProfileColors.bodyTextMuted),
                prefixIcon: Icon(CustomerProfileIcons.amount,
                    color: CustomerProfileColors.brandGold, size: 18),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () async {
            final val = double.tryParse(_dueLimitCtrl.text);
            if (val == null || val < 0) return;
            final ok = await _logic.saveDueLimit(val);
            if (ok && mounted) {
              AppFeedback.show(
                context,
                type: AppFeedbackType.success,
                message: CustomerProfileStrings.savedLimit,
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
            child: _logic.savingDueLimit
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

  // DELETE DIALOG
  void _showDeleteDialog(CustomerProfileModel p) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.of(dialogContext).pop(),
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
              final dialogNavigator = Navigator.of(dialogContext);
              dialogNavigator.pop();
              await Future<void>.delayed(Duration.zero);
              if (!mounted) return;
              final ok = await _logic.deleteCustomer();
              if (!ok && mounted) {
                AppFeedback.show(
                  context,
                  type: AppFeedbackType.error,
                  message:
                      _logic.deleteError ?? CustomerProfileStrings.deleteError,
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

  // SHARED HELPERS
  void _showBillActions(CustomerBillModel bill) {
    _showRecordActionSheet(
      title: 'Sales Bill ${bill.billNo}',
      subtitle: bill.hasLinkedDocuments
          ? 'Original invoice is locked. Linked return documents are tracked below.'
          : bill.isFromAdvanceOrder
              ? 'Converted from ${bill.advanceSourceLabel}. Edit, preview, or print.'
              : 'Edit the sale, preview the invoice, or print a clean copy.',
      linkedDocuments: bill.linkedDocuments,
      actions: [
        if (bill.hasLinkedDocuments)
          _ProfileRecordAction(
            icon: Icons.lock_open_rounded,
            title: 'View Original Invoice',
            subtitle:
                'Open the locked posted bill with every original item line.',
            color: CustomerProfileColors.historyText,
            onTap: () {
              _previewBillPdf(
                bill.id,
                mode: _SalesInvoicePdfMode.postedOriginal,
              );
            },
          )
        else
          _ProfileRecordAction(
            icon: Icons.edit_note_rounded,
            title: 'Edit Sales Bill',
            subtitle:
                'Continue in the sales workspace with this bill selected.',
            color: CustomerProfileColors.editText,
            onTap: () {
              if (widget.onEditBill != null) {
                widget.onEditBill!(bill.id);
              } else {
                _showInfoFeedback('Sales editing is not configured yet.');
              }
            },
          ),
        _ProfileRecordAction(
          icon: Icons.visibility_rounded,
          title: bill.hasLinkedDocuments ? 'View Updated PDF' : 'View Invoice',
          subtitle: bill.hasLinkedDocuments
              ? 'Open the latest statement after posted returns.'
              : 'Open the complete printable invoice preview.',
          color: CustomerProfileColors.brandGold,
          onTap: () {
            _previewBillPdf(
              bill.id,
              mode: bill.hasLinkedDocuments
                  ? _SalesInvoicePdfMode.currentStatement
                  : _SalesInvoicePdfMode.postedOriginal,
            );
          },
        ),
        _ProfileRecordAction(
          icon: Icons.print_rounded,
          title:
              bill.hasLinkedDocuments ? 'Print Updated PDF' : 'Print Invoice',
          subtitle: bill.hasLinkedDocuments
              ? 'Print the current return-adjusted statement.'
              : 'Send the finished invoice directly to the printer.',
          color: CustomerProfileColors.clearIcon,
          onTap: () {
            _printBillPdf(
              bill.id,
              mode: bill.hasLinkedDocuments
                  ? _SalesInvoicePdfMode.currentStatement
                  : _SalesInvoicePdfMode.postedOriginal,
            );
          },
        ),
        if (bill.dueAmount > 0.5)
          _ProfileRecordAction(
            icon: Icons.payments_rounded,
            title: 'Collect Due',
            subtitle: 'Open due collection with this invoice selected.',
            color: CustomerProfileColors.duesAmount,
            onTap: () {
              if (widget.onCollectDue != null) {
                widget.onCollectDue!(widget.customerId, bill.billNo);
              } else {
                _showInfoFeedback('Due collection is not configured yet.');
              }
            },
          ),
      ],
    );
  }

  void _showGirviActions(CustomerLoanModel loan) {
    _showRecordActionSheet(
      title: 'Girvi Ticket ${loan.loanNo}',
      subtitle: 'Edit, view, or print this pledged-loan receipt.',
      actions: [
        _ProfileRecordAction(
          icon: Icons.edit_note_rounded,
          title: 'Edit Girvi Ticket',
          subtitle:
              'Continue in the Girvi workspace with this ticket selected.',
          color: CustomerProfileColors.editText,
          onTap: () {
            if (widget.onEditGirvi != null) {
              widget.onEditGirvi!(loan.id);
            } else {
              _showInfoFeedback('Girvi editing is not configured yet.');
            }
          },
        ),
        _ProfileRecordAction(
          icon: Icons.receipt_long_rounded,
          title: 'View Girvi Receipt',
          subtitle: 'Open the receipt as a clean PDF preview only.',
          color: CustomerProfileColors.brandGold,
          onTap: () {
            _previewGirviInvoice(loan.id);
          },
        ),
        _ProfileRecordAction(
          icon: Icons.print_rounded,
          title: 'Print Girvi Receipt',
          subtitle: 'Print the professional pledge receipt.',
          color: CustomerProfileColors.clearIcon,
          onTap: () {
            _printGirviInvoice(loan.id);
          },
        ),
      ],
    );
  }

  void _showAdvanceActions(CustomerAdvanceOrderModel order) {
    _showRecordActionSheet(
      title: 'Advance Order ${order.orderNo}',
      subtitle: 'Edit, preview, or print this advance booking record.',
      actions: [
        _ProfileRecordAction(
          icon: Icons.edit_note_rounded,
          title: 'Edit Advance Order',
          subtitle:
              'Continue in the advance workspace with this order selected.',
          color: CustomerProfileColors.editText,
          onTap: () {
            if (widget.onEditAdvance != null) {
              widget.onEditAdvance!(order.id);
            } else {
              _showInfoFeedback('Advance editing is not configured yet.');
            }
          },
        ),
        _ProfileRecordAction(
          icon: Icons.visibility_rounded,
          title: 'View Advance Receipt',
          subtitle: 'Open the complete printable booking preview.',
          color: CustomerProfileColors.brandGold,
          onTap: () {
            _previewAdvancePdf(order);
          },
        ),
        _ProfileRecordAction(
          icon: Icons.print_rounded,
          title: 'Print Advance Receipt',
          subtitle: 'Send the advance receipt directly to the printer.',
          color: CustomerProfileColors.clearIcon,
          onTap: () {
            _printAdvancePdf(order);
          },
        ),
        if (order.isPending || order.isReady)
          _ProfileRecordAction(
            icon: Icons.point_of_sale_rounded,
            title: 'Convert to Sale',
            subtitle: 'Carry this booking into the sales workspace.',
            color: CustomerProfileColors.advanceConvertBtn,
            onTap: () {
              _logic.triggerConvertAdvanceToSale(order.id);
            },
          ),
      ],
    );
  }

  void _showRecordActionSheet({
    required String title,
    required String subtitle,
    required List<_ProfileRecordAction> actions,
    List<CustomerLinkedDocumentModel> linkedDocuments = const [],
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.all(18),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: CustomerProfileColors.bodyBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: CustomerProfileColors.brandGold.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.manage_search_rounded,
                      color: CustomerProfileColors.brandGold,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: CustomerProfileColors.bodyTextMain,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CustomerProfileColors.bodyTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(sheetContext).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (linkedDocuments.isNotEmpty) ...[
                _linkedDocumentsPanel(linkedDocuments, sheetContext),
                const SizedBox(height: 14),
              ],
              ...actions.map(
                (action) => _recordActionTile(action, sheetContext),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _linkedDocumentsPanel(
    List<CustomerLinkedDocumentModel> linkedDocuments,
    BuildContext sheetContext,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CustomerProfileColors.historyBg.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CustomerProfileColors.historyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_tree_rounded,
                size: 17,
                color: CustomerProfileColors.historyText,
              ),
              SizedBox(width: 7),
              Text(
                'Linked Documents',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: CustomerProfileColors.bodyTextMain,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...linkedDocuments.map(
            (document) => _linkedDocumentTile(document, sheetContext),
          ),
        ],
      ),
    );
  }

  Widget _linkedDocumentTile(
    CustomerLinkedDocumentModel document,
    BuildContext sheetContext,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () async {
            await Navigator.of(sheetContext).maybePop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _previewLinkedDocumentPdf(document);
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CustomerProfileColors.bodyBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: CustomerProfileColors.clearBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.assignment_return_rounded,
                    size: 18,
                    color: CustomerProfileColors.clearText,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${document.documentNo}  |  ${document.documentTitle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: CustomerProfileColors.bodyTextMain,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${document.formattedDate}  |  ${document.lineCountLabel}  |  Making ${document.formattedMakingReturned}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: CustomerProfileColors.bodyTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      document.formattedReturnValue,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: CustomerProfileColors.bodyTextMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _BillStatusChip(
                      label: document.statusLabel,
                      backgroundColor: CustomerProfileColors.clearBg,
                      textColor: CustomerProfileColors.clearText,
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Print linked document',
                  onPressed: () async {
                    await Navigator.of(sheetContext).maybePop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _printLinkedDocumentPdf(document);
                    });
                  },
                  icon: const Icon(
                    Icons.print_rounded,
                    size: 17,
                    color: CustomerProfileColors.historyText,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _recordActionTile(
    _ProfileRecordAction action,
    BuildContext sheetContext,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: action.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () async {
            await Navigator.of(sheetContext).maybePop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              action.onTap();
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: action.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(action.icon, color: action.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: CustomerProfileColors.bodyTextMain,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        action.subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: CustomerProfileColors.bodyTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: action.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _previewBillPdf(
    int billId, {
    _SalesInvoicePdfMode mode = _SalesInvoicePdfMode.postedOriginal,
  }) async {
    final detail = await _logic.fetchBillDetails(billId);
    if (!mounted) return;
    if (detail == null) {
      _showInfoFeedback('Sales invoice details could not be loaded.');
      return;
    }
    final bytes = await _buildSalesInvoicePdf(detail: detail, mode: mode);
    if (!mounted) return;
    if (bytes == null) {
      _showInfoFeedback('Sales invoice PDF could not be generated.');
      return;
    }
    await _showDocumentPreview(pdfBytes: bytes);
  }

  Future<void> _printBillPdf(
    int billId, {
    _SalesInvoicePdfMode mode = _SalesInvoicePdfMode.postedOriginal,
  }) async {
    final detail = await _logic.fetchBillDetails(billId);
    if (!mounted) return;
    if (detail == null) {
      _showInfoFeedback('Sales invoice details could not be loaded.');
      return;
    }
    final bytes = await _buildSalesInvoicePdf(detail: detail, mode: mode);
    if (!mounted) return;
    if (bytes == null) {
      _showInfoFeedback('Sales invoice PDF could not be generated.');
      return;
    }
    await Printing.layoutPdf(
      name: mode == _SalesInvoicePdfMode.currentStatement
          ? 'sales_invoice_${detail.bill.billNo}_updated_statement.pdf'
          : 'sales_invoice_${detail.bill.billNo}_original.pdf',
      onLayout: (_) async => bytes,
    );
  }

  Future<Uint8List?> _buildSalesInvoicePdf({
    required CustomerBillDetailModel detail,
    required _SalesInvoicePdfMode mode,
  }) async {
    final doc = pw.Document();
    final isCurrent = mode == _SalesInvoicePdfMode.currentStatement;
    final activeItems =
        detail.items.where((item) => !item.isReturned).toList(growable: false);
    final returnedItems =
        detail.items.where((item) => item.isReturned).toList(growable: false);
    final printableItems = isCurrent ? activeItems : detail.items;
    final grossSource = detail.bill.grossAmount > 0
        ? detail.bill.grossAmount
        : detail.items.fold<double>(0, (sum, item) => sum + item.itemTotal);
    final paidTotal = detail.bill.cashPaid +
        detail.bill.upiPaid +
        detail.bill.cardPaid +
        detail.bill.advancePaid;
    final returnValue = detail.bill.linkedReturnValue;
    final currentInvoiceValue = detail.bill.currentInvoiceValue;

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(28),
        ),
        build: (context) => [
          _pdfHeader(
            isCurrent ? 'UPDATED SALES STATEMENT' : 'ORIGINAL TAX INVOICE',
            detail.bill.billNo,
          ),
          pw.SizedBox(height: 14),
          _pdfStatusStrip(
            isCurrent
                ? 'Return adjusted view. Original invoice remains locked.'
                : 'Immutable posted invoice snapshot. Return documents are linked separately.',
            detail.bill.hasLinkedDocuments
                ? detail.bill.lifecycleLabel
                : detail.bill.paymentLabel,
          ),
          pw.SizedBox(height: 14),
          _pdfInfoGrid([
            ['Customer', detail.customerName],
            ['Mobile', detail.customerMobile],
            ['Invoice Date', detail.bill.formattedDate],
            ['Payment Status', detail.bill.paymentLabel],
            [
              'Place of Supply',
              detail.bill.placeOfSupply.isEmpty
                  ? '-'
                  : detail.bill.placeOfSupply
            ],
            [
              'Document Type',
              detail.bill.documentType.isEmpty
                  ? 'TAX INVOICE'
                  : detail.bill.documentType
            ],
          ]),
          pw.SizedBox(height: 16),
          _pdfSectionTitle(
            isCurrent ? 'Active Item Details' : 'Original Item Details',
          ),
          pw.SizedBox(height: 8),
          _pdfSalesItemsTable(printableItems, showReturnStatus: !isCurrent),
          if (isCurrent && returnedItems.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _pdfSectionTitle('Returned Item Adjustments'),
            pw.SizedBox(height: 8),
            _pdfSalesItemsTable(returnedItems, showReturnStatus: true),
          ],
          pw.SizedBox(height: 16),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _pdfPaymentPanel(detail.bill, paidTotal)),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: isCurrent
                    ? _pdfCurrentAmountPanel(
                        bill: detail.bill,
                        grossSource: grossSource,
                        returnValue: returnValue,
                        currentInvoiceValue: currentInvoiceValue,
                      )
                    : _pdfOriginalAmountPanel(
                        bill: detail.bill,
                        grossSource: grossSource,
                      ),
              ),
            ],
          ),
          if (detail.bill.linkedDocuments.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _pdfLinkedDocumentsSummary(detail.bill.linkedDocuments),
          ],
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _pdfStatusStrip(String note, String status) {
    final cleanStatus = status.trim().isEmpty ? 'POSTED' : status.trim();
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFFAEC),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE5B04C)),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              note,
              style: const pw.TextStyle(
                color: PdfColor.fromInt(0xFF111827),
                fontSize: 9,
              ),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFFFFFFF),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFE5B04C)),
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Text(
              cleanStatus.toUpperCase(),
              style: pw.TextStyle(
                color: const PdfColor.fromInt(0xFF8A5D0A),
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSalesItemsTable(
    List<CustomerBillLineItemModel> items, {
    required bool showReturnStatus,
  }) {
    if (items.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: const PdfColor.fromInt(0xFFE1E7F0)),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(
          'No active invoice items in this view.',
          style: const pw.TextStyle(
            color: PdfColor.fromInt(0xFF111827),
            fontSize: 10,
          ),
        ),
      );
    }

    final headers = [
      'No',
      'Metal',
      'Item Detail',
      'Unit',
      'Purity',
      'Net Wt',
      'Rate',
      'Making',
      'Amount',
      if (showReturnStatus) 'Status',
    ];
    final data = items.map((item) {
      return [
        item.lineNo.toString(),
        item.metalType.toUpperCase(),
        _pdfItemDescription(item),
        item.unitLabel,
        item.purity?.trim().isEmpty ?? true ? '-' : item.purity!,
        '${item.netWeight.toStringAsFixed(3)} g',
        _rs(item.rate),
        _makingDisplay(item),
        _rs(item.displayInvoiceValue),
        if (showReturnStatus)
          item.isReturned
              ? 'RETURNED ${item.returnVoucherNo}'.trim()
              : 'ACTIVE',
      ];
    }).toList(growable: false);

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(
        color: const PdfColor.fromInt(0xFFE2E8F0),
        width: 0.6,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF7F3EA),
      ),
      headerStyle: pw.TextStyle(
        color: const PdfColor.fromInt(0xFF111827),
        fontSize: 7,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(
        color: PdfColor.fromInt(0xFF111827),
        fontSize: 7,
      ),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      columnWidths: {
        0: const pw.FixedColumnWidth(22),
        1: const pw.FixedColumnWidth(44),
        2: const pw.FlexColumnWidth(2.3),
        3: const pw.FixedColumnWidth(40),
        4: const pw.FixedColumnWidth(38),
        5: const pw.FixedColumnWidth(52),
        6: const pw.FixedColumnWidth(54),
        7: const pw.FixedColumnWidth(58),
        8: const pw.FixedColumnWidth(58),
        if (showReturnStatus) 9: const pw.FixedColumnWidth(62),
      },
    );
  }

  String _pdfItemDescription(CustomerBillLineItemModel item) {
    final lines = <String>[item.itemName];
    final hsn = item.hsnCode.trim();
    final huid = item.huid?.trim() ?? '';
    if (hsn.isNotEmpty) lines.add('HSN $hsn');
    if (huid.isNotEmpty) lines.add('HUID $huid');
    return lines.join('\n');
  }

  String _makingDisplay(CustomerBillLineItemModel item) {
    final input = item.makingChargeInput;
    final type = item.makingChargeType.trim().toUpperCase();
    final prefix = switch (type) {
      'PERCENTAGE' => '${_fmt(input)}%',
      'PER_PIECE' => '${_fmt(input)}/pc',
      'PER_KG' => '${_fmt(input)}/kg',
      _ => input > 0 ? '${_fmt(input)}/g' : '',
    };
    if (prefix.isEmpty) return _rs(item.makingCharge);
    return '$prefix\n${_rs(item.makingCharge)}';
  }

  pw.Widget _pdfPaymentPanel(CustomerBillModel bill, double paidTotal) {
    final rows = <List<String>>[
      if (bill.cashPaid > 0.005) ['Cash', _rs(bill.cashPaid)],
      if (bill.upiPaid > 0.005) ['UPI / Bank', _rs(bill.upiPaid)],
      if (bill.cardPaid > 0.005) ['Card', _rs(bill.cardPaid)],
      if (bill.advancePaid > 0.005) ['Advance', _rs(bill.advancePaid)],
      ['Total Received', _rs(paidTotal > 0 ? paidTotal : bill.paidAmount)],
      ['Current Due', _rs(bill.dueAmount)],
    ];
    return _pdfSummaryPanel(
      title: 'Payment Received',
      rows: rows,
      footerLabel: 'Payment Status',
      footerValue: bill.paymentLabel,
    );
  }

  pw.Widget _pdfOriginalAmountPanel({
    required CustomerBillModel bill,
    required double grossSource,
  }) {
    return _pdfSummaryPanel(
      title: 'Original Amount Summary',
      rows: [
        ['Gross Sale Value', _rs(grossSource)],
        ['Making Charges', _rs(bill.makingTotal)],
        ['Invoice Discount', '- ${_rs(bill.discountAmount)}'],
        ['Taxable Value', _rs(bill.taxableAmount)],
        if (bill.igstAmount > 0.005)
          ['IGST', _rs(bill.igstAmount)]
        else ...[
          ['CGST', _rs(bill.cgstAmount)],
          ['SGST', _rs(bill.sgstAmount)],
        ],
        if (bill.tradeInDeduction > 0.005)
          ['Customer Metal Settlement', '- ${_rs(bill.tradeInDeduction)}'],
        if (bill.roundOffAmount.abs() > 0.005)
          ['Round Off', _rs(bill.roundOffAmount)],
      ],
      footerLabel: 'Original Invoice Total',
      footerValue: _rs(bill.totalAmount),
    );
  }

  pw.Widget _pdfCurrentAmountPanel({
    required CustomerBillModel bill,
    required double grossSource,
    required double returnValue,
    required double currentInvoiceValue,
  }) {
    return _pdfSummaryPanel(
      title: 'Updated Statement Summary',
      rows: [
        ['Original Invoice Total', _rs(bill.totalAmount)],
        ['Linked Return Value', '- ${_rs(returnValue)}'],
        ['Current Sale Value', _rs(currentInvoiceValue)],
        ['Amount Received', _rs(bill.paidAmount)],
        ['Current Due', _rs(bill.dueAmount)],
      ],
      footerLabel: 'Current Customer Position',
      footerValue: bill.dueAmount <= 0.5 ? 'SETTLED' : _rs(bill.dueAmount),
    );
  }

  pw.Widget _pdfSummaryPanel({
    required String title,
    required List<List<String>> rows,
    required String footerLabel,
    required String footerValue,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE1E7F0)),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              color: const PdfColor.fromInt(0xFF8A5D0A),
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          ...rows.map(
            (row) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    row[0],
                    style: const pw.TextStyle(
                      color: PdfColor.fromInt(0xFF344256),
                      fontSize: 8.5,
                    ),
                  ),
                  pw.Text(
                    row[1],
                    style: pw.TextStyle(
                      color: const PdfColor.fromInt(0xFF111827),
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.Divider(color: const PdfColor.fromInt(0xFFE5B04C)),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                footerLabel,
                style: pw.TextStyle(
                  color: const PdfColor.fromInt(0xFF111827),
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                footerValue,
                style: pw.TextStyle(
                  color: const PdfColor.fromInt(0xFF8A5D0A),
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfLinkedDocumentsSummary(
    List<CustomerLinkedDocumentModel> documents,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF6F0FF),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFC4B5FD)),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'LINKED RETURN / REVERSAL DOCUMENTS',
            style: pw.TextStyle(
              color: const PdfColor.fromInt(0xFF4C1D95),
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 7),
          ...documents.map(
            (document) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      '${document.documentNo} | ${document.documentTitle} | ${document.lineCountLabel}',
                      style: const pw.TextStyle(
                        color: PdfColor.fromInt(0xFF111827),
                        fontSize: 8,
                      ),
                    ),
                  ),
                  pw.Text(
                    document.formattedReturnValue.replaceFirst('\u20B9', 'Rs'),
                    style: pw.TextStyle(
                      color: const PdfColor.fromInt(0xFF111827),
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _previewLinkedDocumentPdf(
    CustomerLinkedDocumentModel document,
  ) async {
    final bytes = await _buildLinkedDocumentPdf(document);
    if (!mounted) return;
    await _showDocumentPreview(pdfBytes: bytes);
  }

  Future<void> _printLinkedDocumentPdf(
    CustomerLinkedDocumentModel document,
  ) {
    return Printing.layoutPdf(
      name: '${document.documentNo}_return_settlement.pdf',
      onLayout: (_) => _buildLinkedDocumentPdf(document),
    );
  }

  Future<Uint8List> _buildLinkedDocumentPdf(
    CustomerLinkedDocumentModel document,
  ) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
        ),
        build: (context) => [
          _pdfHeader(document.documentTitle.toUpperCase(), document.documentNo),
          pw.SizedBox(height: 18),
          _pdfSectionTitle('Document Link'),
          pw.SizedBox(height: 8),
          _pdfInfoGrid([
            ['Source Invoice', document.sourceNumber],
            ['Document Status', document.statusLabel],
            ['Document Date', document.formattedDate],
            ['Returned Items', document.lineCountLabel],
            [
              'Received Net Weight',
              '${document.netWeight.toStringAsFixed(3)} g'
            ],
            ['Return Value', document.formattedReturnValue],
            ['Making Returned', document.formattedMakingReturned],
            ['Due Adjusted', document.formattedDueAdjusted],
            ['Customer Credit', document.formattedCustomerCredit],
          ]),
          pw.SizedBox(height: 18),
          _pdfSectionTitle('Audit Note'),
          pw.SizedBox(height: 8),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF7F3EA),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFE1E7F0)),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Text(
              'Original sales invoice remains locked. This linked document records the return settlement, inventory routing, due adjustment, and customer credit impact.',
              style: const pw.TextStyle(
                color: PdfColor.fromInt(0xFF111827),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> _previewGirviInvoice(int loanId) async {
    final draft = await _logic.fetchGirviInvoiceDraft(loanId);
    if (!mounted) return;
    if (draft == null) {
      _showInfoFeedback('Girvi receipt details could not be loaded.');
      return;
    }
    final controller = GirviInvoiceHubController(
      draft: draft,
      onFinalize: () async => true,
    );
    try {
      await controller.generatePreview();
      if (!mounted) return;
      final bytes = controller.pdfBytes;
      if (bytes == null) {
        _showInfoFeedback('Girvi receipt PDF could not be generated.');
        return;
      }
      await _showDocumentPreview(pdfBytes: bytes);
    } finally {
      controller.dispose();
    }
  }

  Future<void> _printGirviInvoice(int loanId) async {
    final draft = await _logic.fetchGirviInvoiceDraft(loanId);
    if (!mounted) return;
    if (draft == null) {
      _showInfoFeedback('Girvi receipt details could not be loaded.');
      return;
    }
    final controller = GirviInvoiceHubController(
      draft: draft,
      onFinalize: () async => true,
    );
    try {
      final printed = await controller.printInvoice();
      if (!mounted) return;
      if (!printed) _showInfoFeedback('Girvi receipt could not be printed.');
    } finally {
      controller.dispose();
    }
  }

  Future<void> _previewAdvancePdf(CustomerAdvanceOrderModel order) async {
    final bytes = await _buildAdvanceOrderPdf(order, _logic.profile);
    if (!mounted) return;
    await _showDocumentPreview(pdfBytes: bytes);
  }

  Future<void> _printAdvancePdf(CustomerAdvanceOrderModel order) {
    return Printing.layoutPdf(
      name: 'advance_order_${order.orderNo}.pdf',
      onLayout: (_) => _buildAdvanceOrderPdf(order, _logic.profile),
    );
  }

  Future<void> _showCleanPdfPreview({
    required Future<Uint8List> Function(PdfPageFormat format) builder,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (dialogContext) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: SizedBox.expand(
          child: Stack(
            children: [
              Positioned.fill(
                child: PdfPreview(
                  build: builder,
                  initialPageFormat: PdfPageFormat.a4,
                  allowPrinting: false,
                  allowSharing: false,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                  useActions: false,
                  maxPageWidth: 820,
                  scrollViewDecoration: const BoxDecoration(
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Positioned(
                top: 18,
                right: 18,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.62),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Close preview',
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDocumentPreview({required Uint8List pdfBytes}) async {
    final sides = await _rasterPdfSides(pdfBytes);
    if (!mounted) return;
    if (sides.isEmpty) {
      await _showCleanPdfPreview(builder: (_) async => pdfBytes);
      return;
    }

    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      useSafeArea: false,
      builder: (dialogContext) => Material(
        type: MaterialType.transparency,
        child: _CustomerDocumentPreview(
          sides: sides,
          onClose: () => Navigator.of(dialogContext).pop(),
        ),
      ),
    );
  }

  Future<List<PdfRaster>> _rasterPdfSides(Uint8List pdfBytes) async {
    try {
      final info = await Printing.info();
      if (!info.canRaster) return const [];

      final sides = <PdfRaster>[];
      await for (final page in Printing.raster(pdfBytes, dpi: 144)) {
        sides.add(page);
        if (sides.length == 2) break;
      }
      return List.unmodifiable(sides);
    } catch (_) {
      return const [];
    }
  }

  Future<Uint8List> _buildAdvanceOrderPdf(
    CustomerAdvanceOrderModel order,
    CustomerProfileModel? profile,
  ) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
        ),
        build: (context) => [
          _pdfHeader('BOOKING ADVANCE RECEIPT', order.orderNo),
          pw.SizedBox(height: 18),
          _pdfInfoGrid([
            ['Customer', profile?.name ?? 'Customer'],
            ['Mobile', profile?.mobile ?? '-'],
            ['City', profile?.city.isNotEmpty == true ? profile!.city : '-'],
            ['Order Number', order.orderNo],
            ['Item', order.itemName],
            ['Metal', order.metalType],
            ['Purity', order.purity],
            ['Approx Weight', '${order.approxWeight.toStringAsFixed(3)} g'],
            ['Locked Rate', _rs(order.lockedRate)],
            ['Booking Type', order.bookingType],
            ['Status', order.status.label],
            ['Created On', order.formattedDate],
            ['Delivery Date', order.formattedDelivery],
            ['Estimated Total', _rs(order.estimatedTotal)],
            ['Advance Paid', _rs(order.totalAdvancePaid)],
            ['Remaining Balance', _rs(order.remainingBalance)],
          ]),
          if (order.notes != null && order.notes!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _pdfSectionTitle('Order Notes'),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border:
                    pw.Border.all(color: const PdfColor.fromInt(0xFFD8DEE9)),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Text(order.notes!.trim()),
            ),
          ],
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _pdfHeader(String title, String number) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFF0B1E33),
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            height: 42,
            width: 42,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFD59A2B),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Text(
              'L',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  number,
                  style: const pw.TextStyle(
                    color: PdfColor.fromInt(0xFFF7C66A),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          pw.Text(
            'LOTUS PRIME ERP',
            style: const pw.TextStyle(
              color: PdfColor.fromInt(0xFFF7C66A),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfInfoGrid(List<List<String>> rows) {
    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: rows.map((row) {
        return pw.Container(
          width: 248,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: const PdfColor.fromInt(0xFFE1E7F0)),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                row[0].toUpperCase(),
                style: const pw.TextStyle(
                  color: PdfColor.fromInt(0xFF637083),
                  fontSize: 7,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                row[1],
                style: pw.TextStyle(
                  color: const PdfColor.fromInt(0xFF111827),
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _pdfSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF7F3EA),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE5B04C)),
      ),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          color: const PdfColor.fromInt(0xFF8A5D0A),
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  String _rs(double value) => 'Rs ${_fmt(value)}';

  void _showInfoFeedback(String message) {
    if (!mounted) return;
    AppFeedback.show(
      context,
      type: AppFeedbackType.info,
      message: message,
    );
  }

  Widget _buildLoading({String message = "Loading profile..."}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: CustomerProfileColors.brandGold,
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
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

  Widget _ledgerSummaryBox({
    required String title,
    required String primaryLabel,
    required String primaryValue,
    required String secondaryLabel,
    required String secondaryValue,
    required IconData icon,
    required Color color,
    String? tertiaryLabel,
    String? tertiaryValue,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: CustomerProfileColors.bodyTextMain,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            primaryLabel,
            style: CustomerProfileStyles.snapshotLabel,
          ),
          const SizedBox(height: 3),
          Text(
            primaryValue,
            style: CustomerProfileStyles.snapshotAmount.copyWith(color: color),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.14)),
            ),
            child: Column(
              children: [
                _summaryInlineMetric(
                  secondaryLabel,
                  secondaryValue,
                  color,
                ),
                if (tertiaryLabel != null && tertiaryValue != null) ...[
                  const SizedBox(height: 6),
                  Divider(height: 1, color: color.withValues(alpha: 0.14)),
                  const SizedBox(height: 6),
                  _summaryInlineMetric(
                    tertiaryLabel,
                    tertiaryValue,
                    color,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryInlineMetric(String label, String value, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: CustomerProfileColors.bodyTextMuted,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
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

  Widget _buildAccountStatusBadge(CreditStatus status) {
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

class _CustomerDocumentPreview extends StatefulWidget {
  const _CustomerDocumentPreview({
    required this.sides,
    required this.onClose,
  });

  final List<PdfRaster> sides;
  final VoidCallback onClose;

  @override
  State<_CustomerDocumentPreview> createState() =>
      _CustomerDocumentPreviewState();
}

class _CustomerDocumentPreviewState extends State<_CustomerDocumentPreview>
    with SingleTickerProviderStateMixin {
  static const double _minZoom = 0.70;
  static const double _maxZoom = 4.0;

  late final AnimationController _flipController;
  late final TransformationController _viewController;
  DateTime? _lastPointerDownAt;
  Offset? _lastPointerDownPosition;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _viewController = TransformationController();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _viewController.dispose();
    super.dispose();
  }

  void _toggleSide() {
    if (widget.sides.length < 2 || _flipController.isAnimating) return;
    if (_flipController.value < 0.5) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    final now = DateTime.now();
    final lastAt = _lastPointerDownAt;
    final lastPosition = _lastPointerDownPosition;
    final isDoubleClick = lastAt != null &&
        now.difference(lastAt) <= const Duration(milliseconds: 360) &&
        lastPosition != null &&
        (event.position - lastPosition).distance <= 16;

    _lastPointerDownAt = now;
    _lastPointerDownPosition = event.position;

    if (isDoubleClick) {
      _lastPointerDownAt = null;
      _lastPointerDownPosition = null;
      _toggleSide();
    }
  }

  void _zoomBy(double factor) {
    final currentScale = _viewController.value.getMaxScaleOnAxis();
    if (currentScale <= 0) return;
    final nextScale =
        (currentScale * factor).clamp(_minZoom, _maxZoom).toDouble();
    if ((nextScale - currentScale).abs() < 0.01) return;
    final scaleDelta = nextScale / currentScale;
    _viewController.value = _viewController.value.clone()
      ..scaleByDouble(scaleDelta, scaleDelta, scaleDelta, 1.0);
  }

  void _resetZoom() {
    _viewController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFF111827)),
            ),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final firstSide = widget.sides.first;
                final aspectRatio = firstSide.width / firstSide.height;
                return Listener(
                  onPointerDown: _handlePointerDown,
                  child: InteractiveViewer(
                    transformationController: _viewController,
                    minScale: _minZoom,
                    maxScale: _maxZoom,
                    scaleFactor: 160,
                    trackpadScrollCausesScale: true,
                    boundaryMargin: const EdgeInsets.all(320),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth:
                              math.min(constraints.maxWidth * 0.94, 1180.0),
                          maxHeight: constraints.maxHeight * 0.94,
                        ),
                        child: AspectRatio(
                          aspectRatio: aspectRatio,
                          child: MouseRegion(
                            cursor: widget.sides.length > 1
                                ? SystemMouseCursors.click
                                : MouseCursor.defer,
                            child: AnimatedBuilder(
                              animation: _flipController,
                              builder: (context, _) {
                                final angle = _flipController.value * math.pi;
                                final showingBack = angle > math.pi / 2 &&
                                    widget.sides.length > 1;
                                final side = showingBack
                                    ? widget.sides[1]
                                    : widget.sides.first;

                                return Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.0012)
                                    ..rotateY(angle),
                                  child: showingBack
                                      ? Transform(
                                          alignment: Alignment.center,
                                          transform: Matrix4.identity()
                                            ..rotateY(math.pi),
                                          child: _PdfFlipSide(raster: side),
                                        )
                                      : _PdfFlipSide(raster: side),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 18,
            right: 18,
            child: Material(
              color: Colors.black.withValues(alpha: 0.62),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Close preview',
                onPressed: widget.onClose,
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: _FlipPreviewToolbar(
              canFlip: widget.sides.length > 1,
              onFlip: _toggleSide,
              onZoomIn: () => _zoomBy(1.18),
              onZoomOut: () => _zoomBy(0.84),
              onReset: _resetZoom,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlipPreviewToolbar extends StatelessWidget {
  const _FlipPreviewToolbar({
    required this.canFlip,
    required this.onFlip,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final bool canFlip;
  final VoidCallback onFlip;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.62),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FlipPreviewToolButton(
              tooltip: 'Zoom out',
              icon: Icons.remove_rounded,
              onPressed: onZoomOut,
            ),
            _FlipPreviewToolButton(
              tooltip: 'Reset zoom',
              icon: Icons.center_focus_strong_rounded,
              onPressed: onReset,
            ),
            _FlipPreviewToolButton(
              tooltip: 'Zoom in',
              icon: Icons.add_rounded,
              onPressed: onZoomIn,
            ),
            if (canFlip)
              _FlipPreviewToolButton(
                tooltip: 'Flip page',
                icon: Icons.flip_rounded,
                onPressed: onFlip,
              ),
          ],
        ),
      ),
    );
  }
}

class _FlipPreviewToolButton extends StatelessWidget {
  const _FlipPreviewToolButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 42, height: 42),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
    );
  }
}

class _PdfFlipSide extends StatelessWidget {
  const _PdfFlipSide({required this.raster});

  final PdfRaster raster;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 36,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image(
          image: PdfRasterImage(raster),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

// STAT BOX
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? sub;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.sub,
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
              fontSize: 24,
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

class _BillStatusChip extends StatelessWidget {
  const _BillStatusChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: textColor.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

// ACTION BUTTON
class _ProfileRecordAction {
  const _ProfileRecordAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
}

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

// TYPE TOGGLE (Regular / VIP)
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

// CONVERT TO SALE BUTTON
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
