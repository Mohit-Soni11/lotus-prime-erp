import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/supplier_profile_logic.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_enums.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier_profile/supplier_profile_model.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier_profile/supplier_stock_batch.dart';
import 'package:lotus_erp/repositories/supplier/supplier_repository.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';
import 'package:lotus_erp/theme/stock/supplier/supplier_profile/supplier_profile_theme.dart';
import 'package:lotus_erp/ui/shared/system_status_badge.dart';
import '../add_supplier/add_supplier_screen.dart';
import 'supplier_profile_app_bar.dart';

part 'supplier_profile_widgets.dart';
part 'supplier_profile_business_widgets.dart';
part 'supplier_profile_info_widgets.dart';
part 'supplier_profile_purchase_widgets.dart';
part 'supplier_profile_batch_widgets.dart';
part 'supplier_profile_document_widgets.dart';
part 'supplier_profile_action_widgets.dart';
part 'supplier_profile_overview_sections.dart';
part 'supplier_profile_history_sections.dart';
part 'supplier_profile_ui_helpers.dart';
part 'supplier_profile_edit_actions.dart';
part 'supplier_profile_deactivate_actions.dart';
part 'supplier_profile_feedback.dart';

class SupplierProfileScreen extends StatefulWidget {
  final int supplierId;
  final int? initialVoucherId;
  final VoidCallback? onBack;
  final VoidCallback? onNewStock;
  final VoidCallback? onDeleted;

  const SupplierProfileScreen({
    super.key,
    required this.supplierId,
    this.initialVoucherId,
    this.onBack,
    this.onNewStock,
    this.onDeleted,
  });

  @override
  State<SupplierProfileScreen> createState() => _SupplierProfileScreenState();
}

class _SupplierProfileScreenState extends State<SupplierProfileScreen>
    with TickerProviderStateMixin {
  late final SupplierProfileLogic _logic;
  late final AnimationController _pageAnim;
  late final Animation<double> _fadeIn;
  late final TabController _tabCtrl;
  final ScrollController _scrollCtrl = ScrollController();
  final GlobalKey _purchaseHistoryKey = GlobalKey();
  bool _voucherFocusScheduled = false;
  bool _voucherPulse = false;

  @override
  void initState() {
    super.initState();
    _logic = SupplierProfileLogic(supplierId: widget.supplierId);
    _tabCtrl = TabController(length: 3, vsync: this);
    _pageAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fadeIn = CurvedAnimation(parent: _pageAnim, curve: Curves.easeOut);

    _logic.addListener(() {
      if (!mounted) return;
      if (_logic.state == SupplierProfileState.loaded && _pageAnim.value == 0) {
        _pageAnim.forward();
      }
      if (_logic.state == SupplierProfileState.deleted) {
        if (widget.onDeleted != null) {
          widget.onDeleted!.call();
        } else {
          _handleBack();
        }
        return;
      }
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant SupplierProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialVoucherId != widget.initialVoucherId) {
      _voucherFocusScheduled = false;
      _voucherPulse = false;
    }
  }

  @override
  void dispose() {
    _logic.dispose();
    _pageAnim.dispose();
    _tabCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SupplierProfileColors.bodyBg,
      appBar: SupplierProfileAppBar(
        onBack: _handleBack,
        status: _logic.isLoading
            ? SystemStatus.loading
            : _logic.state == SupplierProfileState.error
                ? SystemStatus.unavailable
                : SystemStatus.online,
      ),
      body: ListenableBuilder(
        listenable: _logic,
        builder: (context, _) {
          if (_logic.isLoading) return _buildLoading();
          if (_logic.state == SupplierProfileState.error) return _buildError();
          final profile = _logic.profile;
          if (profile == null) return _buildError();
          return _buildBody(profile);
        },
      ),
    );
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!.call();
      return;
    }
    Navigator.of(context).maybePop();
  }

  Widget _buildBody(SupplierProfileModel profile) {
    _scheduleVoucherFocus(profile);
    return RefreshIndicator(
      color: SupplierProfileColors.brandGold,
      onRefresh: _logic.refresh,
      child: FadeTransition(
        opacity: _fadeIn,
        child: SingleChildScrollView(
          controller: _scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: SupplierProfileStyles.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(profile),
              const SizedBox(height: 16),
              _buildActionButtons(profile),
              const SizedBox(height: 16),
              _buildStatsOverview(profile),
              const SizedBox(height: 16),
              _buildContactCard(profile),
              const SizedBox(height: 16),
              _buildBusinessCard(profile),
              const SizedBox(height: 16),
              _buildHistoryTabs(profile),
            ],
          ),
        ),
      ),
    );
  }

  void _scheduleVoucherFocus(SupplierProfileModel profile) {
    final voucherId = widget.initialVoucherId;
    if (voucherId == null ||
        _voucherFocusScheduled ||
        !profile.purchases.any((item) => item.voucherId == voucherId)) {
      return;
    }
    _voucherFocusScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _tabCtrl.animateTo(1);
      _logic.setTab(1);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted || widget.initialVoucherId != voucherId) return;
      final historyContext = _purchaseHistoryKey.currentContext;
      if (historyContext != null && historyContext.mounted) {
        await Scrollable.ensureVisible(
          historyContext,
          alignment: 0.05,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      }
      for (var i = 0;
          i < 6 && mounted && widget.initialVoucherId == voucherId;
          i++) {
        setState(() => _voucherPulse = i.isEven);
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      if (mounted) setState(() => _voucherPulse = false);
    });
  }
}
