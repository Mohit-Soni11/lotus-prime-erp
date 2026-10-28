import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../core/documents/issued_pdf_preview_dialog.dart';
import '../../../theme/customer/customer_profile/customer_profile_theme.dart';
import '../../../logic/customer/customer_profile_logic.dart';
import '../../../repositories/customer/customer_profile_repository.dart';
import '../../../logic/girvi/girvi_invoice_document_store.dart';
import '../../../logic/girvi/girvi_document_set_service.dart';
import '../../../logic/booking_advance/booking_invoice_preview_controller.dart';
import '../../../core/documents/issued_invoice_archive.dart';
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
  final VoidCallback? onBack;
  final Function(int customerId)? onNewSale;
  final Function(int billId)? onEditBill;
  final Function(int advanceOrderId)? onEditAdvance;
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
    this.onBack,
    this.onNewSale,
    this.onEditBill,
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
  final _issuedInvoiceArchive = const IssuedInvoiceArchive();
  final _girviInvoiceStore = const GirviInvoiceDocumentStore();
  late final AnimationController _pageAnim;
  late final Animation<double> _fadeIn;

  // Sales, due, active Girvi, and active advances.
  late final TabController _tabCtrl;

  final ScrollController _scrollCtrl = ScrollController();
  final GlobalKey _historyKey = GlobalKey();
  bool _deleteNavigationScheduled = false;
  int? _focusedInitialBillId;

  @override
  void initState() {
    super.initState();
    _logic = CustomerProfileLogic(
      customerId: widget.customerId,
      repo: widget.repository,
      onConvertAdvanceToSale: widget.onConvertAdvanceToSale,
    );

    _tabCtrl = TabController(length: 4, vsync: this);

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
}
