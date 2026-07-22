import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lotus_erp/features/stock/shared/application/supplier_profile_logic.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_enums.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier_profile/supplier_profile_model.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';
import 'package:lotus_erp/theme/stock/supplier/supplier_profile/supplier_profile_theme.dart';
import 'supplier_profile_app_bar.dart';

part 'supplier_profile_widgets.dart';

class SupplierProfileScreen extends StatefulWidget {
  final int supplierId;
  final VoidCallback? onBack;
  final VoidCallback? onNewStock;
  final VoidCallback? onDeleted;

  const SupplierProfileScreen({
    super.key,
    required this.supplierId,
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

  final TextEditingController _businessNameCtrl = TextEditingController();
  final TextEditingController _contactPersonCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _whatsappCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _alternateCtrl = TextEditingController();
  final TextEditingController _panCtrl = TextEditingController();
  final TextEditingController _gstCtrl = TextEditingController();
  final TextEditingController _address1Ctrl = TextEditingController();
  final TextEditingController _address2Ctrl = TextEditingController();
  final TextEditingController _stateCtrl = TextEditingController();
  final TextEditingController _pincodeCtrl = TextEditingController();
  final TextEditingController _countryCtrl = TextEditingController();
  final TextEditingController _openingBalanceCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  String _editType = SupplierType.manufacturer.label;

  @override
  void initState() {
    super.initState();
    _logic = SupplierProfileLogic(supplierId: widget.supplierId);
    _tabCtrl = TabController(length: 5, vsync: this);
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
  void dispose() {
    _logic.dispose();
    _pageAnim.dispose();
    _tabCtrl.dispose();
    _scrollCtrl.dispose();
    _businessNameCtrl.dispose();
    _contactPersonCtrl.dispose();
    _mobileCtrl.dispose();
    _whatsappCtrl.dispose();
    _emailCtrl.dispose();
    _alternateCtrl.dispose();
    _panCtrl.dispose();
    _gstCtrl.dispose();
    _address1Ctrl.dispose();
    _address2Ctrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _countryCtrl.dispose();
    _openingBalanceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SupplierProfileColors.bodyBg,
      appBar: SupplierProfileAppBar(
        onBack: _handleBack,
        supplierName: _logic.profile?.businessName ?? 'Supplier',
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
              _buildLedgerCard(profile),
              const SizedBox(height: 16),
              if (profile.hasOutstandingDue) ...[
                _buildDuesSection(profile),
                const SizedBox(height: 16),
              ],
              _buildBusinessCard(profile),
              const SizedBox(height: 16),
              _buildHistoryTabs(profile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(SupplierProfileModel profile) {
    final healthColor = _healthColor(profile.ledgerHealth);
    final typeColor = _typeColor(profile.supplierType);
    return Container(
      decoration: SupplierProfileStyles.cardDecoration,
      padding: SupplierProfileStyles.cardPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: SupplierProfileStyles.avatarSize,
            height: SupplierProfileStyles.avatarSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SupplierProfileColors.brandGoldBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: SupplierProfileColors.brandGold.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      SupplierProfileColors.brandGold.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              profile.avatarInitials,
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                color: SupplierProfileColors.brandGold,
                letterSpacing: 0,
              ),
            ),
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
                        profile.businessName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SupplierProfileStyles.supplierName,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _statusBadge(
                      profile.ledgerHealth.label,
                      healthColor,
                      profile.ledgerHealth == SupplierLedgerHealth.clear
                          ? SupplierProfileIcons.clear
                          : SupplierProfileIcons.due,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${profile.primaryContactName} | ${profile.mobile}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SupplierProfileStyles.supplierMeta,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _softChip(profile.typeLabel, typeColor),
                    _softChip(profile.statusLabel, SupplierProfileColors.info),
                    _softChip(
                      'Since ${profile.formattedSince}',
                      SupplierProfileColors.documentAccent,
                    ),
                    if ((profile.gstNumber ?? '').trim().isNotEmpty)
                      _softChip(
                        'GST ${profile.gstNumber}',
                        SupplierProfileColors.violet,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 220,
            padding: const EdgeInsets.all(16),
            decoration: SupplierProfileStyles.tintedPanel(healthColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CURRENT BAKI', style: SupplierProfileStyles.statLabel),
                const SizedBox(height: 8),
                Text(
                  _money(profile.outstandingDue),
                  style: SupplierProfileStyles.statValue.copyWith(
                    color: healthColor,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  profile.hasOutstandingDue
                      ? '${profile.dueVoucherCount} purchase voucher(s) pending'
                      : 'All supplier dues are clear',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SupplierProfileStyles.historyMeta.copyWith(
                    color: healthColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(SupplierProfileModel profile) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: SupplierProfileIcons.addStock,
            label: SupplierProfileStrings.btnAddStock,
            bg: SupplierProfileColors.brandGold,
            fg: Colors.black,
            border: SupplierProfileColors.brandGold,
            filled: true,
            onTap: widget.onNewStock ?? _handleBack,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: SupplierProfileIcons.edit,
            label: SupplierProfileStrings.btnEdit,
            bg: SupplierProfileColors.infoBg,
            fg: SupplierProfileColors.info,
            border: SupplierProfileColors.info.withValues(alpha: 0.35),
            onTap: () => _showEditDialog(profile),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: SupplierProfileIcons.ledger,
            label: SupplierProfileStrings.btnLedger,
            bg: SupplierProfileColors.violetBg,
            fg: SupplierProfileColors.violet,
            border: SupplierProfileColors.violet.withValues(alpha: 0.35),
            onTap: _jumpToHistory,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: SupplierProfileIcons.deactivate,
            label: SupplierProfileStrings.btnDeactivate,
            bg: SupplierProfileColors.dangerBg,
            fg: SupplierProfileColors.danger,
            border: SupplierProfileColors.danger.withValues(alpha: 0.35),
            onTap: () => _showDeactivateDialog(profile),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsOverview(SupplierProfileModel profile) {
    return _supplierProfileStatsOverview(profile);
  }

  Widget _buildContactCard(SupplierProfileModel profile) {
    return _supplierProfileContactCard(
      profile,
      sectionHeader: _sectionHeader,
    );
  }

  Widget _buildLedgerCard(SupplierProfileModel profile) {
    return _supplierProfileLedgerCard(
      profile,
      sectionHeader: _sectionHeader,
    );
  }

  Widget _buildDuesSection(SupplierProfileModel profile) {
    return _supplierProfileDuesSection(
      profile,
      sectionHeader: _sectionHeader,
    );
  }

  Widget _buildBusinessCard(SupplierProfileModel profile) {
    return _supplierProfileBusinessCard(
      profile,
      sectionHeader: _sectionHeader,
    );
  }

  Widget _buildHistoryTabs(SupplierProfileModel profile) {
    return Container(
      decoration: SupplierProfileStyles.cardDecoration,
      padding: SupplierProfileStyles.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Supplier Activity',
            'Purchase vouchers, metal returns and bill photos',
            SupplierProfileIcons.purchases,
            SupplierProfileColors.info,
          ),
          const SizedBox(height: 16),
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: SupplierProfileColors.bodyBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SupplierProfileColors.bodyBorder),
            ),
            child: TabBar(
              controller: _tabCtrl,
              onTap: _logic.setTab,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: BoxDecoration(
                color: SupplierProfileColors.bodyPanelBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: SupplierProfileColors.brandGold.withValues(alpha: 0.5),
                ),
              ),
              indicatorPadding: const EdgeInsets.all(4),
              dividerColor: Colors.transparent,
              labelColor: SupplierProfileColors.bodyTextMain,
              unselectedLabelColor: SupplierProfileColors.bodyTextMuted,
              labelStyle: SupplierProfileStyles.chipText,
              tabs: const [
                Tab(text: 'All Purchases'),
                Tab(text: 'GST Purchases'),
                Tab(text: 'Non-GST'),
                Tab(text: SupplierProfileStrings.secMetal),
                Tab(text: SupplierProfileStrings.secDocuments),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: switch (_logic.activeTab) {
              1 => _buildGstPurchaseList(profile),
              2 => _buildNonGstPurchaseList(profile),
              3 => _buildMetalList(profile),
              4 => _buildDocumentsList(profile),
              _ => _buildPurchaseList(profile),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseList(SupplierProfileModel profile) {
    return _buildPurchaseListFor(
      items: profile.purchases,
      emptyTitle: SupplierProfileStrings.noPurchases,
      emptySubtitle: SupplierProfileStrings.noPurchasesSub,
      keyValue: 'purchase-list',
    );
  }

  Widget _buildGstPurchaseList(SupplierProfileModel profile) {
    return _buildPurchaseListFor(
      items: profile.gstPurchases,
      emptyTitle: 'No GST purchases yet',
      emptySubtitle: 'GST purchase vouchers will appear here separately.',
      keyValue: 'gst-purchase-list',
    );
  }

  Widget _buildNonGstPurchaseList(SupplierProfileModel profile) {
    return _buildPurchaseListFor(
      items: profile.nonGstPurchases,
      emptyTitle: 'No Non-GST purchases yet',
      emptySubtitle: 'No-ITC purchase vouchers will appear here separately.',
      keyValue: 'non-gst-purchase-list',
    );
  }

  Widget _buildPurchaseListFor({
    required List<SupplierProfilePurchaseModel> items,
    required String emptyTitle,
    required String emptySubtitle,
    required String keyValue,
  }) {
    if (items.isEmpty) {
      return _EmptyState(
        key: ValueKey('$keyValue-empty'),
        icon: SupplierProfileIcons.empty,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }
    return Column(
      key: ValueKey(keyValue),
      children: [
        for (final item in items) ...[
          _PurchaseHistoryCard(item: item),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildMetalList(SupplierProfileModel profile) {
    final items = profile.metalSettlements;
    if (items.isEmpty) {
      return const _EmptyState(
        key: ValueKey('metal-empty'),
        icon: SupplierProfileIcons.metal,
        title: SupplierProfileStrings.noMetal,
        subtitle: SupplierProfileStrings.noMetalSub,
      );
    }
    return Column(
      key: const ValueKey('metal-list'),
      children: [
        for (final item in items) ...[
          _MetalSettlementCard(item: item),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildDocumentsList(SupplierProfileModel profile) {
    final items = profile.billDocuments;
    if (items.isEmpty) {
      return const _EmptyState(
        key: ValueKey('docs-empty'),
        icon: SupplierProfileIcons.photo,
        title: SupplierProfileStrings.noDocuments,
        subtitle: SupplierProfileStrings.noDocumentsSub,
      );
    }
    return Column(
      key: const ValueKey('docs-list'),
      children: [
        for (final item in items) ...[
          _BillDocumentCard(item: item),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _sectionHeader(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: SupplierProfileStyles.tintedPanel(color),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: SupplierProfileStyles.sectionTitle),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SupplierProfileStyles.sectionSubtitle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: SupplierProfileStyles.tintedPanel(color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: SupplierProfileStyles.chipText.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _softChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: SupplierProfileStyles.tintedPanel(color),
      child: Text(
        label,
        style: SupplierProfileStyles.chipText.copyWith(color: color),
      ),
    );
  }

  void _jumpToHistory() {
    _logic.setTab(0);
    _tabCtrl.animateTo(0);
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _fillEditControllers(SupplierProfileModel profile) {
    _businessNameCtrl.text = profile.businessName;
    _contactPersonCtrl.text = profile.contactPersonName ?? '';
    _mobileCtrl.text = profile.mobile;
    _whatsappCtrl.text = profile.whatsapp ?? '';
    _emailCtrl.text = profile.email ?? '';
    _alternateCtrl.text = profile.alternateContact ?? '';
    _panCtrl.text = profile.panNumber ?? '';
    _gstCtrl.text = profile.gstNumber ?? '';
    _address1Ctrl.text = profile.addressLine1 ?? '';
    _address2Ctrl.text = profile.addressLine2 ?? '';
    _stateCtrl.text = profile.state ?? '';
    _pincodeCtrl.text = profile.pincode ?? '';
    _countryCtrl.text = profile.country;
    _openingBalanceCtrl.text = profile.openingBalance.toStringAsFixed(2);
    _notesCtrl.text = profile.notes ?? '';
    _editType = profile.supplierType.label;
  }

  void _showEditDialog(SupplierProfileModel profile) {
    _fillEditControllers(profile);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool saving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: SupplierProfileColors.bodyPanelBg,
              surfaceTintColor: Colors.transparent,
              title: Text(
                SupplierProfileStrings.editTitle,
                style:
                    SupplierProfileStyles.sectionTitle.copyWith(fontSize: 18),
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _dialogField(
                            controller: _businessNameCtrl,
                            label: 'Business Name',
                            width: 414,
                          ),
                          SizedBox(
                            width: 414,
                            child: DropdownButtonFormField<String>(
                              initialValue: _editType,
                              decoration: _dialogDecoration('Supplier Type'),
                              items: SupplierType.labels
                                  .map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setDialogState(() => _editType = value);
                              },
                            ),
                          ),
                          _dialogField(
                            controller: _contactPersonCtrl,
                            label: 'Contact Person',
                            width: 414,
                          ),
                          _dialogField(
                            controller: _mobileCtrl,
                            label: 'Mobile',
                            width: 414,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9+\-\s]'),
                              ),
                            ],
                          ),
                          _dialogField(
                            controller: _whatsappCtrl,
                            label: 'WhatsApp',
                            width: 414,
                            keyboardType: TextInputType.phone,
                          ),
                          _dialogField(
                            controller: _emailCtrl,
                            label: 'Email',
                            width: 414,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          _dialogField(
                            controller: _alternateCtrl,
                            label: 'Alternate Contact',
                            width: 414,
                            keyboardType: TextInputType.phone,
                          ),
                          _dialogField(
                            controller: _openingBalanceCtrl,
                            label: 'Opening Balance',
                            width: 414,
                            keyboardType: TextInputType.number,
                          ),
                          _dialogField(
                            controller: _gstCtrl,
                            label: 'GST Number',
                            width: 414,
                            textCapitalization: TextCapitalization.characters,
                          ),
                          _dialogField(
                            controller: _panCtrl,
                            label: 'PAN Number',
                            width: 414,
                            textCapitalization: TextCapitalization.characters,
                          ),
                          _dialogField(
                            controller: _address1Ctrl,
                            label: 'Address Line 1',
                            width: 414,
                          ),
                          _dialogField(
                            controller: _address2Ctrl,
                            label: 'Address Line 2',
                            width: 414,
                          ),
                          _dialogField(
                            controller: _stateCtrl,
                            label: 'State',
                            width: 270,
                          ),
                          _dialogField(
                            controller: _pincodeCtrl,
                            label: 'Pincode',
                            width: 270,
                            keyboardType: TextInputType.number,
                          ),
                          _dialogField(
                            controller: _countryCtrl,
                            label: 'Country',
                            width: 270,
                          ),
                          _dialogField(
                            controller: _notesCtrl,
                            label: 'Notes',
                            width: 840,
                            maxLines: 3,
                          ),
                        ],
                      ),
                      if (_logic.editError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _logic.editError!,
                          style: SupplierProfileStyles.historyMeta.copyWith(
                            color: SupplierProfileColors.danger,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      saving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text(SupplierProfileStrings.editCancel),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: SupplierProfileColors.brandGold,
                    foregroundColor: Colors.black,
                  ),
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(SupplierProfileIcons.save, size: 18),
                  label: Text(
                    saving ? 'Saving...' : SupplierProfileStrings.editSave,
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                          final dialogNavigator = Navigator.of(dialogContext);
                          setDialogState(() => saving = true);
                          final ok = await _logic.saveEdit(
                            businessName: _businessNameCtrl.text,
                            mobile: _mobileCtrl.text,
                            supplierType: _editType,
                            contactPersonName: _contactPersonCtrl.text,
                            whatsapp: _whatsappCtrl.text,
                            email: _emailCtrl.text,
                            alternateContact: _alternateCtrl.text,
                            panNumber: _panCtrl.text,
                            gstNumber: _gstCtrl.text,
                            addressLine1: _address1Ctrl.text,
                            addressLine2: _address2Ctrl.text,
                            state: _stateCtrl.text,
                            pincode: _pincodeCtrl.text,
                            country: _countryCtrl.text,
                            notes: _notesCtrl.text,
                            openingBalance: double.tryParse(
                                  _openingBalanceCtrl.text.trim(),
                                ) ??
                                0.0,
                          );
                          if (!mounted) return;
                          if (ok) {
                            dialogNavigator.pop();
                            _showFeedback(SupplierProfileStrings.editSuccess);
                          } else {
                            setDialogState(() => saving = false);
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required double width,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        decoration: _dialogDecoration(label),
      ),
    );
  }

  InputDecoration _dialogDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: SupplierProfileColors.bodyBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SupplierProfileColors.bodyBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SupplierProfileColors.bodyBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: SupplierProfileColors.brandGold,
          width: 1.5,
        ),
      ),
    );
  }

  void _showDeactivateDialog(SupplierProfileModel profile) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: SupplierProfileColors.bodyPanelBg,
        surfaceTintColor: Colors.transparent,
        icon: const Icon(
          SupplierProfileIcons.deactivate,
          color: SupplierProfileColors.danger,
          size: 34,
        ),
        title: const Text(SupplierProfileStrings.deleteTitle),
        content: Text(
          SupplierProfileStrings.deleteMsg,
          style: SupplierProfileStyles.historyMeta,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(SupplierProfileStrings.deleteCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SupplierProfileColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final ok = await _logic.deactivateSupplier();
              if (!mounted || !ok) return;
              _showFeedback('${profile.businessName} deactivated');
            },
            child: const Text(SupplierProfileStrings.deleteConfirm),
          ),
        ],
      ),
    );
  }

  void _showFeedback(String message) {
    AppFeedback.show(
      context,
      type: AppFeedbackType.info,
      message: message,
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: SupplierProfileColors.brandGold),
    );
  }

  Widget _buildError() {
    return Center(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        decoration: SupplierProfileStyles.cardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              SupplierProfileIcons.empty,
              color: SupplierProfileColors.bodyTextMuted,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              _logic.error ?? 'Supplier profile not found',
              textAlign: TextAlign.center,
              style: SupplierProfileStyles.sectionTitle,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _logic.refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
