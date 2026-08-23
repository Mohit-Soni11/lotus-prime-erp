import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../logic/purchase/purchase_entry_controller.dart';
import '../../../models/customer/customer_list/customer_list_ui_model.dart';
import '../../../theme/purchase/purchase_entry/purchase_entry_theme.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';
import '../../customer/add_customer/add_customer_screen.dart';

class PurchaseCustomerPanel extends StatefulWidget {
  final PurchaseEntryController ctrl;

  const PurchaseCustomerPanel({super.key, required this.ctrl});

  @override
  State<PurchaseCustomerPanel> createState() => _PurchaseCustomerPanelState();
}

class _PurchaseCustomerPanelState extends State<PurchaseCustomerPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  final LayerLink _mobileSuggestionLink = LayerLink();
  final LayerLink _nameSuggestionLink = LayerLink();

  OverlayEntry? _suggestionOverlay;
  bool _isMobileActive = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _animCtrl.forward();
      }
    });

    widget.ctrl.nameCtrl.addListener(_onNameChanged);
    widget.ctrl.mobileCtrl.addListener(_onMobileChanged);
    widget.ctrl.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _removeSuggestionOverlay();
    widget.ctrl.nameCtrl.removeListener(_onNameChanged);
    widget.ctrl.mobileCtrl.removeListener(_onMobileChanged);
    widget.ctrl.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onNameChanged() {
    _isMobileActive = false;
    widget.ctrl.searchCustomers(widget.ctrl.nameCtrl.text);
  }

  void _onMobileChanged() {
    _isMobileActive = true;
    widget.ctrl.searchCustomers(widget.ctrl.mobileCtrl.text);
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});

    if (widget.ctrl.customerSuggestions.isEmpty) {
      _removeSuggestionOverlay();
      return;
    }

    _showSuggestionOverlay();
  }

  void _removeSuggestionOverlay() {
    _suggestionOverlay?.remove();
    _suggestionOverlay = null;
  }

  void _showSuggestionOverlay() {
    if (!mounted) {
      return;
    }
    _removeSuggestionOverlay();

    final activeLink =
        _isMobileActive ? _mobileSuggestionLink : _nameSuggestionLink;

    _suggestionOverlay = OverlayEntry(
      builder: (context) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final overlayWidth = screenWidth > 392
            ? 360.0
            : (screenWidth - 32.0).clamp(220.0, 360.0).toDouble();

        return Positioned(
          width: overlayWidth,
          child: CompositedTransformFollower(
            link: activeLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 54),
            child: Material(
              color: Colors.transparent,
              child: _PurchaseLookupDropdown(
                ctrl: widget.ctrl,
                onSelectCustomer: (customer) async {
                  FocusScope.of(context).unfocus();
                  await widget.ctrl.selectCustomer(customer);
                  _removeSuggestionOverlay();
                },
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_suggestionOverlay!);
  }

  Future<void> _openCreateFlow() async {
    _removeSuggestionOverlay();
    FocusScope.of(context).unfocus();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddCustomerScreen(
          onBack: () => Navigator.pop(context),
          onSaved: () => Navigator.pop(context),
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    final query = widget.ctrl.nameCtrl.text.trim().isNotEmpty
        ? widget.ctrl.nameCtrl.text
        : widget.ctrl.mobileCtrl.text;
    if (query.isNotEmpty) {
      await widget.ctrl.searchCustomers(query);
    }
  }

  Future<void> _quickCreateSeller() async {
    _removeSuggestionOverlay();
    FocusScope.of(context).unfocus();

    final ok = await widget.ctrl.quickCreateSeller();
    if (!mounted) {
      return;
    }
    AppFeedback.show(
      context,
      type: ok ? AppFeedbackType.success : AppFeedbackType.error,
      message: ok
          ? 'Seller added for this purchase.'
          : 'Enter seller name or a valid 10-digit mobile number.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: PurchaseEntryColors.bodyPanel,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:
                    PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.10),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              const BoxShadow(
                color: PurchaseEntryColors.shadowDark,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.5),
                      PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final singleColumn = constraints.maxWidth < 760;
                  final twoColumn = constraints.maxWidth < 1120;

                  final mobileField = CompositedTransformTarget(
                    link: _mobileSuggestionLink,
                    child: _buildInput(
                      label: 'MOBILE',
                      hint: '10-digit',
                      controller: widget.ctrl.mobileCtrl,
                      isNumber: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      icon: PurchaseEntryIcons.mobilePhone,
                    ),
                  );

                  final nameField = CompositedTransformTarget(
                    link: _nameSuggestionLink,
                    child: _buildInput(
                      label: 'SELLER NAME',
                      hint: 'Enter full name',
                      controller: widget.ctrl.nameCtrl,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r"[a-zA-Z ]"),
                        ),
                      ],
                      textCapitalization: TextCapitalization.words,
                      icon: PurchaseEntryIcons.customerName,
                    ),
                  );

                  final addressField = _buildInput(
                    label: 'ADDRESS',
                    hint: 'Full seller address',
                    controller: widget.ctrl.cityCtrl,
                    textCapitalization: TextCapitalization.words,
                    icon: PurchaseEntryIcons.cityLocation,
                  );

                  final identityField = _buildInput(
                    label: 'PAN / AADHAAR ID',
                    hint: 'PAN or Aadhaar number',
                    controller: widget.ctrl.panCtrl,
                    isCaps: true,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z0-9]")),
                    ],
                    icon: PurchaseEntryIcons.panCard,
                  );

                  if (singleColumn) {
                    return Column(
                      children: [
                        mobileField,
                        const SizedBox(height: 12),
                        nameField,
                        const SizedBox(height: 12),
                        addressField,
                        const SizedBox(height: 12),
                        identityField,
                        const SizedBox(height: 16),
                        _buildActionRow(),
                      ],
                    );
                  }

                  if (twoColumn) {
                    final halfWidth = (constraints.maxWidth - 12) / 2;
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(width: halfWidth, child: mobileField),
                            const SizedBox(width: 12),
                            SizedBox(width: halfWidth, child: nameField),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(width: halfWidth, child: addressField),
                            const SizedBox(width: 12),
                            SizedBox(width: halfWidth, child: identityField),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildActionRow(),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(flex: 2, child: mobileField),
                      const SizedBox(width: 12),
                      Expanded(flex: 3, child: nameField),
                      const SizedBox(width: 12),
                      Expanded(flex: 5, child: addressField),
                      const SizedBox(width: 12),
                      Expanded(flex: 3, child: identityField),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 142,
                        child: _ActionButton(
                          title: 'Create Seller',
                          icon: PurchaseEntryIcons.newSeller,
                          isPrimary: true,
                          onTap: _openCreateFlow,
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (widget.ctrl.hasSelectedCounterparty ||
                  widget.ctrl.counterpartNotFound) ...[
                const SizedBox(height: 16),
                _buildStatusCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final bool showCreateCta = widget.ctrl.counterpartNotFound;
    final badge = showCreateCta
        ? _PrimaryActionChip(
            title: 'Quick Add',
            icon: Icons.flash_on_rounded,
            onTap: _quickCreateSeller,
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: PurchaseEntryColors.purchaseAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.ctrl.hasSelectedCounterparty
                      ? 'Profile Linked'
                      : 'Lookup Ready',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: PurchaseEntryColors.purchaseAccentMid,
                  ),
                ),
              ],
            ),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackHeader = constraints.maxWidth < 760;

        final titleBlock = Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SELLER DETAILS',
                style: PurchaseEntryStyles.highVisHeader,
              ),
              const SizedBox(height: 2),
              Text(
                'Search or add a customer seller',
                style: PurchaseEntryStyles.subTitleMuted,
              ),
            ],
          ),
        );

        final leadingRow = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    PurchaseEntryColors.purchaseAccent,
                    PurchaseEntryColors.purchaseAccentMid,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: PurchaseEntryColors.purchaseAccent
                        .withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                PurchaseEntryIcons.profile,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            titleBlock,
          ],
        );

        if (stackHeader) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leadingRow,
              const SizedBox(height: 12),
              badge,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: leadingRow),
            const SizedBox(width: 12),
            badge,
          ],
        );
      },
    );
  }

  Widget _buildActionRow() {
    final actions = [
      Expanded(
        child: _ActionButton(
          title: 'Create Seller',
          icon: PurchaseEntryIcons.newSeller,
          isPrimary: true,
          onTap: _openCreateFlow,
        ),
      ),
    ];

    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 156,
        child: Row(children: actions),
      ),
    );
  }

  Widget _buildStatusCard() {
    if (widget.ctrl.counterpartNotFound) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PurchaseEntryColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: PurchaseEntryColors.warning.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: PurchaseEntryColors.warning,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No matching seller profile was found. Use Quick Add for instant save, or Create Seller for the full customer form.',
                style: PurchaseEntryStyles.subTitleMuted.copyWith(
                  color: PurchaseEntryColors.textMain,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final title = widget.ctrl.nameCtrl.text.trim().isEmpty
        ? 'Linked Record'
        : widget.ctrl.nameCtrl.text.trim();
    final detailParts = [
      widget.ctrl.mobileCtrl.text.trim(),
      widget.ctrl.cityCtrl.text.trim(),
    ].where((value) => value.isNotEmpty).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PurchaseEntryColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PurchaseEntryColors.success.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: PurchaseEntryColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: PurchaseEntryColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PurchaseEntryStyles.inputText.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.ctrl.selectedCounterpartyCaption ?? 'Linked record',
                  style: PurchaseEntryStyles.subTitleMuted.copyWith(
                    color: PurchaseEntryColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (detailParts.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    detailParts.join(' | '),
                    style: PurchaseEntryStyles.subTitleMuted.copyWith(
                      color: PurchaseEntryColors.textMain,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isNumber = false,
    bool isCaps = false,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: PurchaseEntryColors.purchaseAccent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PurchaseEntryColors.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 46,
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            textCapitalization:
                isCaps ? TextCapitalization.characters : textCapitalization,
            inputFormatters: inputFormatters,
            maxLength: maxLength,
            style: PurchaseEntryStyles.inputText,
            decoration: InputDecoration(
              counterText: '',
              hintText: hint,
              hintStyle: TextStyle(
                color: PurchaseEntryColors.textMuted.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: icon != null
                  ? Icon(icon, size: 18, color: PurchaseEntryColors.textMuted)
                  : null,
              filled: true,
              fillColor: PurchaseEntryColors.formInputBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              border: OutlineInputBorder(
                borderSide:
                    const BorderSide(color: PurchaseEntryColors.bodyBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide:
                    const BorderSide(color: PurchaseEntryColors.bodyBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: PurchaseEntryColors.purchaseAccent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PurchaseLookupDropdown extends StatelessWidget {
  final PurchaseEntryController ctrl;
  final Future<void> Function(CustomerListItemModel customer) onSelectCustomer;

  const _PurchaseLookupDropdown({
    required this.ctrl,
    required this.onSelectCustomer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: PurchaseEntryColors.bodyPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PurchaseEntryColors.bodyBorder),
        boxShadow: const [
          BoxShadow(
            color: PurchaseEntryColors.shadowDark,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        shrinkWrap: true,
        itemCount: ctrl.customerSuggestions.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          color: PurchaseEntryColors.bodyBorder,
        ),
        itemBuilder: (context, index) {
          final customer = ctrl.customerSuggestions[index];
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              backgroundColor:
                  PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.12),
              child: Text(
                customer.initials,
                style: const TextStyle(
                  color: PurchaseEntryColors.purchaseAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            title: Text(
              customer.name,
              style: const TextStyle(
                color: PurchaseEntryColors.textMain,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              [customer.mobile, customer.city]
                  .where((value) => value.isNotEmpty)
                  .join(' | '),
              style: PurchaseEntryStyles.subTitleMuted,
            ),
            onTap: () => onSelectCustomer(customer),
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final background = widget.isPrimary
        ? PurchaseEntryColors.purchaseAccent
        : PurchaseEntryColors.bodyBg;
    final foreground =
        widget.isPrimary ? Colors.white : PurchaseEntryColors.purchaseAccent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          decoration: BoxDecoration(
            color: _isHovered
                ? background.withValues(alpha: widget.isPrimary ? 0.92 : 1)
                : background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isPrimary
                  ? PurchaseEntryColors.purchaseAccent
                  : PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.25),
            ),
            boxShadow: _isHovered && widget.isPrimary
                ? [
                    BoxShadow(
                      color: PurchaseEntryColors.purchaseAccent
                          .withValues(alpha: 0.24),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: foreground, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionChip extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryActionChip({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              PurchaseEntryColors.purchaseAccent,
              PurchaseEntryColors.purchaseAccentMid,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
