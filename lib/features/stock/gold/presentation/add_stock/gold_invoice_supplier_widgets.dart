part of 'gold_invoice_card.dart';

class _Header extends StatelessWidget {
  final Color accent;
  final bool gstEnabled;
  final bool hasSupplier;

  const _Header({
    required this.accent,
    required this.gstEnabled,
    required this.hasSupplier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AddStockColors.cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AddStockColors.brandGoldLight,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AddStockColors.brandGoldBorder),
            ),
            child: const Icon(
              Icons.person_pin_circle_outlined,
              size: 17,
              color: AddStockColors.brandGold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '2. Supplier & Invoice',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.1,
                    color: AddStockColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasSupplier
                      ? 'Supplier linked with this stock batch'
                      : 'Select supplier and attach purchase reference',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AddStockColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StatusPill(
            label: gstEnabled ? 'GST Purchase' : 'Non-GST',
            color: gstEnabled
                ? AddStockColors.brandGold
                : AddStockColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _SupplierLookupSection extends StatelessWidget {
  final GoldStockController ctrl;
  final LayerLink mobileSuggestionLink;
  final LayerLink nameSuggestionLink;
  final bool notFound;
  final VoidCallback onCreateSupplier;
  final VoidCallback onOpenSupplierProfile;

  const _SupplierLookupSection({
    required this.ctrl,
    required this.mobileSuggestionLink,
    required this.nameSuggestionLink,
    required this.notFound,
    required this.onCreateSupplier,
    required this.onOpenSupplierProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AddStockColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AddStockColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 560;

              final mobileField = CompositedTransformTarget(
                link: mobileSuggestionLink,
                child: _SupplierTextField(
                  label: 'Mobile Number',
                  hint: 'Search by mobile number',
                  controller: ctrl.supplierMobileCtrl,
                  icon: Icons.phone_iphone_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
              );

              final nameField = CompositedTransformTarget(
                link: nameSuggestionLink,
                child: _SupplierTextField(
                  label: 'Supplier Name',
                  hint: 'Search by supplier name',
                  controller: ctrl.supplierNameCtrl,
                  icon: AddStockIcons.supplier,
                ),
              );

              if (stacked) {
                return Column(
                  children: [
                    mobileField,
                    const SizedBox(height: 12),
                    nameField,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: mobileField),
                  const SizedBox(width: 12),
                  Expanded(child: nameField),
                ],
              );
            },
          ),
          if (notFound) ...[
            const SizedBox(height: 12),
            _SupplierStateBanner(
              type: _SupplierStateType.notFound,
              title: 'Supplier not found',
              message:
                  'Create a supplier profile once, then this batch will link to supplier ledger automatically.',
              actionLabel: 'Create Supplier',
              onAction: onCreateSupplier,
            ),
          ] else if (ctrl.hasLinkedSupplier) ...[
            const SizedBox(height: 12),
            _SupplierStateBanner(
              type: _SupplierStateType.linked,
              title: 'Supplier linked',
              message: ctrl.supplierDisplayName.trim().isEmpty
                  ? 'Selected supplier profile is linked to this batch.'
                  : ctrl.supplierDisplayName,
              actionLabel: 'Open Profile',
              onAction: onOpenSupplierProfile,
              secondaryActionLabel: 'Change',
              onSecondaryAction: () => ctrl.clearSessionSupplier(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SupplierTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _SupplierTextField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AddStockColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AddStockColors.textDark,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AddStockColors.textHint,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(9),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AddStockColors.brandGoldLight,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      icon,
                      size: 14,
                      color: AddStockColors.brandGold,
                    ),
                  ),
                ),
                filled: true,
                fillColor: AddStockColors.cardBg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide:
                      const BorderSide(color: AddStockColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide:
                      const BorderSide(color: AddStockColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(
                    color: AddStockColors.brandGold,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _SupplierStateType { linked, notFound }

class _SupplierStateBanner extends StatelessWidget {
  final _SupplierStateType type;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const _SupplierStateBanner({
    required this.type,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final linked = type == _SupplierStateType.linked;
    final color = linked ? AddStockColors.success : AddStockColors.warning;
    final bg = linked ? AddStockColors.successBg : AddStockColors.warningBg;
    final icon =
        linked ? Icons.check_circle_rounded : Icons.warning_amber_rounded;

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AddStockColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AddStockColors.textBody,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            alignment: WrapAlignment.end,
            children: [
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  actionLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (secondaryActionLabel != null && onSecondaryAction != null)
                TextButton(
                  onPressed: onSecondaryAction,
                  style: TextButton.styleFrom(
                    foregroundColor: AddStockColors.textMuted,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    secondaryActionLabel!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SupplierLookupDropdown extends StatelessWidget {
  final List<SupplierListItemModel> suppliers;
  final ValueChanged<SupplierListItemModel> onSelected;

  const _SupplierLookupDropdown({
    required this.suppliers,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: AddStockColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AddStockColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AddStockColors.shadowMedium,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        shrinkWrap: true,
        itemCount: suppliers.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AddStockColors.cardBorder),
        itemBuilder: (context, index) {
          final supplier = suppliers[index];
          final subtitle = [
            supplier.mobile,
            supplier.supplierType.label,
          ].where((value) => value.isNotEmpty).join(' • ');

          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: AddStockColors.brandGoldLight,
              child: Text(
                supplier.avatarInitial,
                style: GoogleFonts.inter(
                  color: AddStockColors.brandGold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            title: Text(
              supplier.businessName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: AddStockColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: AddStockColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: AddStockColors.textHint,
            ),
            onTap: () => onSelected(supplier),
          );
        },
      ),
    );
  }
}
