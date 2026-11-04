import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../../core/documents/issued_pdf_preview_dialog.dart';
import '../../../theme/customer/customer_profile/customer_profile_theme.dart';
import '../../../logic/customer/customer_profile_logic.dart';
import '../../../repositories/customer/customer_profile_repository.dart';
import '../../../logic/girvi/girvi_invoice_document_store.dart';
import '../../../logic/girvi/girvi_document_set_service.dart';
import '../../../logic/booking_advance/booking_invoice_preview_controller.dart';
import '../../../core/documents/issued_invoice_archive.dart';
import '../../../features/sales_pos/application/documents/sales_invoice_payment_revision_service.dart';
import '../../../features/finance/due_management/domain/services/bill_due_policy.dart';
import '../../../core/logging/app_logger.dart';
import '../../../models/customer/customer_profile/customer_profile_model.dart';
import '../../../models/customer/customer_enums/customer_list_enums.dart';
import '../add_customer/add_customer_screen.dart';
import 'customer_profile_app_bar.dart';
import 'customer_profile_components.dart';
import 'customer_profile_metric_cards.dart';
import 'customer_profile_information_tiles.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

part 'customer_profile_overview_sections.dart';
part 'customer_profile_history_tabs.dart';
part 'customer_profile_bill_history.dart';
part 'customer_profile_girvi_history.dart';
part 'customer_profile_advance_history.dart';
part 'customer_profile_dialogs.dart';
part 'customer_profile_record_actions.dart';
part 'customer_profile_action_sheet.dart';
part 'customer_profile_document_actions.dart';
part 'customer_profile_issued_documents.dart';
part 'customer_profile_support_widgets.dart';

class CustomerProfileScreen extends StatefulWidget {
  final int customerId;
  final CustomerProfileRepository? repository;
  final int? initialBillId;
  final int? initialGirviId;
  final int? initialAdvanceId;
  final VoidCallback? onBack;
  final Function(int customerId)? onNewSale;
  final Function(int billId)? onEditBill;
  final Function(int loanId)? onEditGirvi;
  final Function(int customerId, String ticketNo)? onCollectGirviInterest;
  final Function(int loanId)? onOpenGirviAccount;
  final Function(int advanceOrderId)? onEditAdvance;
  final Function(String orderNo, int customerId)? onCancelAdvance;
  final Function(int customerId, String billNo)? onCollectDue;
  final VoidCallback? onDeleted;

  /// Called when user taps "Convert to Sale" on an advance order.
  /// Passes advanceOrderId + customerId to parent for POS navigation.
  final Function(int advanceOrderId, int customerId)? onConvertAdvanceToSale;

  const CustomerProfileScreen({
    super.key,
    required this.customerId,
    this.repository,
    this.initialBillId,
    this.initialGirviId,
    this.initialAdvanceId,
    this.onBack,
    this.onNewSale,
    this.onEditBill,
    this.onEditGirvi,
    this.onCollectGirviInterest,
    this.onOpenGirviAccount,
    this.onEditAdvance,
    this.onCancelAdvance,
    this.onCollectDue,
    this.onDeleted,
    this.onConvertAdvanceToSale,
  });

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen>
    with TickerProviderStateMixin {
  late CustomerProfileLogic _logic;
  final _issuedInvoiceArchive = const IssuedInvoiceArchive();
  final _girviInvoiceStore = const GirviInvoiceDocumentStore();
  late final AnimationController _pageAnim;
  late final Animation<double> _fadeIn;

  final ScrollController _scrollCtrl = ScrollController();
  final GlobalKey _historyKey = GlobalKey();
  bool _deleteNavigationScheduled = false;
  int? _focusedInitialBillId;
  String? _focusedRecordKey;
  bool _focusPulse = false;
  Timer? _focusTimer;

  @override
  void initState() {
    super.initState();
    _pageAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _pageAnim, curve: Curves.easeOut);

    _createLogic();
  }

  void _createLogic() {
    _logic = CustomerProfileLogic(
      customerId: widget.customerId,
      repo: widget.repository,
    )..addListener(_handleProfileStateChanged);
  }

  @override
  void didUpdateWidget(covariant CustomerProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customerId == widget.customerId &&
        oldWidget.repository == widget.repository) {
      return;
    }
    _logic.removeListener(_handleProfileStateChanged);
    _logic.dispose();
    _focusTimer?.cancel();
    _pageAnim.reset();
    _focusedInitialBillId = null;
    _focusedRecordKey = null;
    _focusPulse = false;
    _deleteNavigationScheduled = false;
    if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
    _createLogic();
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
    _focusTimer?.cancel();
    _logic.removeListener(_handleProfileStateChanged);
    _logic.dispose();
    _pageAnim.dispose();
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
            return _buildLoading(message: 'Returning to customer list...');
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
    _scheduleInitialActivityFocus(p);
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
            if (p.hasDues || p.activeLoans > 0) ...[
              _buildAccountSnapshotCard(p),
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
    final customerId = widget.customerId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          widget.customerId != customerId ||
          widget.initialBillId != billId) {
        return;
      }
      _focusHistoryTab(_CustomerHistorySection.sales, p);
      _revealHistory();
      _flashRecord('bill:$billId');
    });
  }

  void _scheduleInitialActivityFocus(CustomerProfileModel p) {
    final girviId = widget.initialGirviId;
    final advanceId = widget.initialAdvanceId;
    final key = girviId != null
        ? 'girvi:$girviId'
        : advanceId != null
            ? 'advance:$advanceId'
            : null;
    if (key == null || _focusedRecordKey == key) return;
    final exists = girviId != null
        ? p.loans.any((loan) => loan.id == girviId)
        : p.advanceOrders.any((order) => order.id == advanceId);
    if (!exists) return;
    _focusedRecordKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _focusedRecordKey != key) return;
      _focusHistoryTab(
        girviId != null
            ? _CustomerHistorySection.girvi
            : _CustomerHistorySection.advances,
        p,
      );
      _revealHistory();
      _flashRecord(key);
    });
  }

  void _focusHistoryTab(
      _CustomerHistorySection section, CustomerProfileModel profile) {
    final historyContext = _historyKey.currentContext;
    if (historyContext == null) return;
    final index = _visibleHistorySections(profile).indexOf(section);
    if (index >= 0) {
      DefaultTabController.maybeOf(historyContext)?.animateTo(index);
    }
  }

  void _revealHistory() {
    final historyContext = _historyKey.currentContext;
    if (historyContext == null) return;
    Scrollable.ensureVisible(
      historyContext,
      alignment: 0.05,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void _flashRecord(String key) {
    _focusTimer?.cancel();
    setState(() => _focusPulse = true);
    var step = 0;
    _focusTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      final targetChanged = key.startsWith('bill:')
          ? widget.initialBillId?.toString() != key.split(':').last
          : _focusedRecordKey != key;
      if (!mounted || targetChanged || ++step >= 6) {
        timer.cancel();
        if (mounted) setState(() => _focusPulse = false);
        return;
      }
      setState(() => _focusPulse = step.isEven);
    });
  }

  // 1. HERO CARD
}
