part of 'due_collection_entry_screen.dart';

class _PaymentSetupDialog extends StatefulWidget {
  final DueCollectionEntryController ctrl;

  const _PaymentSetupDialog({required this.ctrl});

  @override
  State<_PaymentSetupDialog> createState() => _PaymentSetupDialogState();
}

class _PaymentSetupDialogState extends State<_PaymentSetupDialog> {
  late final TextEditingController _accountNameCtrl;
  late final TextEditingController _bankNameCtrl;
  late final TextEditingController _accountNumberCtrl;
  late final TextEditingController _holderCtrl;
  late final TextEditingController _ifscCtrl;
  late final TextEditingController _branchCtrl;
  late final TextEditingController _upiCtrl;

  String? _error;
  bool _isSaving = false;
  late bool _isPrimary;

  bool get _upiOnly =>
      widget.ctrl.needsUpiSetup && widget.ctrl.selectedBankAccount != null;
  bool get _upiRequired =>
      widget.ctrl.paymentMode == DueCollectionPaymentMode.upi;

  @override
  void initState() {
    super.initState();
    final selected = widget.ctrl.selectedBankAccount;
    _accountNameCtrl = TextEditingController(text: selected?.accountName ?? '');
    _bankNameCtrl = TextEditingController(text: selected?.bankName ?? '');
    _accountNumberCtrl =
        TextEditingController(text: selected?.accountNumber ?? '');
    _holderCtrl = TextEditingController();
    _ifscCtrl = TextEditingController();
    _branchCtrl = TextEditingController();
    _upiCtrl = TextEditingController(text: selected?.upiId ?? '');
    _isPrimary = widget.ctrl.bankAccounts.isEmpty;
  }

  @override
  void dispose() {
    _accountNameCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _holderCtrl.dispose();
    _ifscCtrl.dispose();
    _branchCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (_upiOnly) {
      if (_upiCtrl.text.trim().isEmpty) {
        setState(() => _error = 'Enter UPI ID for selected account.');
        return;
      }
      setState(() => _isSaving = true);
      final success =
          await widget.ctrl.updateSelectedAccountUpi(_upiCtrl.text.trim());
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context, true);
      } else {
        setState(() => _error = 'Could not save UPI ID.');
      }
      return;
    }

    if (_accountNameCtrl.text.trim().isEmpty ||
        _bankNameCtrl.text.trim().isEmpty ||
        _accountNumberCtrl.text.trim().isEmpty) {
      setState(() =>
          _error = 'Account name, bank name and account number are required.');
      return;
    }
    if (_upiRequired && _upiCtrl.text.trim().isEmpty) {
      setState(() => _error = 'UPI ID is required for UPI payment.');
      return;
    }

    setState(() => _isSaving = true);
    final id = await widget.ctrl.createPaymentAccount(
      accountName: _accountNameCtrl.text.trim(),
      bankName: _bankNameCtrl.text.trim(),
      accountNumber: _accountNumberCtrl.text.trim(),
      holderName: _holderCtrl.text.trim(),
      ifscCode: _ifscCtrl.text.trim(),
      branchName: _branchCtrl.text.trim(),
      upiId: _upiCtrl.text.trim(),
      isPrimary: _isPrimary,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (id != null) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error = 'Could not save bank account.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeLabel = widget.ctrl.paymentMode.label;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        decoration: BoxDecoration(
          color: DueCollectionEntryColors.bodyPanel,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 32,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 15),
              decoration: const BoxDecoration(
                color: DueCollectionEntryColors.shellPanel,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: DueCollectionEntryColors.brandGoldLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(DueCollectionEntryIcons.bank,
                        size: 20, color: DueCollectionEntryColors.brandGold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Set $modeLabel Details',
                            style: DueCollectionEntryStyles.appBarTitle),
                        const SizedBox(height: 3),
                        Text(
                          _upiOnly
                              ? 'Add UPI ID to the selected account before saving.'
                              : 'Create/select a real account so payment records stay traceable.',
                          style: DueCollectionEntryStyles.appBarSub,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: DueCollectionEntryColors.shellMuted),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_upiOnly) ...[
                      _SetupField(
                        label: 'Selected Account',
                        controller: _accountNameCtrl,
                        icon: DueCollectionEntryIcons.bank,
                        readOnly: true,
                      ),
                      const SizedBox(height: 12),
                      _SetupField(
                        label: 'UPI ID',
                        controller: _upiCtrl,
                        icon: DueCollectionEntryIcons.upi,
                        hint: 'example@upi',
                      ),
                    ] else ...[
                      _SetupTargetSelector(
                        isPrimary: _isPrimary,
                        onChanged: (value) =>
                            setState(() => _isPrimary = value),
                      ),
                      const SizedBox(height: 14),
                      _SetupField(
                        label: 'Account Name',
                        controller: _accountNameCtrl,
                        icon: DueCollectionEntryIcons.bank,
                        hint: 'HDFC Current / PhonePe UPI',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SetupField(
                              label: 'Bank Name',
                              controller: _bankNameCtrl,
                              icon: DueCollectionEntryIcons.bank,
                              hint: 'HDFC Bank',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SetupField(
                              label: 'Account Number',
                              controller: _accountNumberCtrl,
                              icon: DueCollectionEntryIcons.bill,
                              hint: 'Account no',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SetupField(
                              label: 'Holder Name',
                              controller: _holderCtrl,
                              icon: DueCollectionEntryIcons.customer,
                              hint: 'Optional',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SetupField(
                              label: 'IFSC',
                              controller: _ifscCtrl,
                              icon: DueCollectionEntryIcons.receipt,
                              hint: 'Optional',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SetupField(
                              label: 'Branch',
                              controller: _branchCtrl,
                              icon: DueCollectionEntryIcons.location,
                              hint: 'Optional',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SetupField(
                              label: _upiRequired ? 'UPI ID' : 'UPI ID',
                              controller: _upiCtrl,
                              icon: DueCollectionEntryIcons.upi,
                              hint: _upiRequired ? 'Required' : 'Optional',
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      _MessageBox(message: _error!, isError: true),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: DueCollectionEntryColors.bodyBorder),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(DueCollectionEntryIcons.save, size: 17),
                      label: Text(_isSaving ? 'Saving...' : 'Save Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DueCollectionEntryColors.brandGold,
                        foregroundColor: const Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final bool readOnly;

  const _SetupField({
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      style: DueCollectionEntryStyles.rowTitle,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: DueCollectionEntryColors.brandGold),
        filled: true,
        fillColor: DueCollectionEntryColors.panelSoft,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: DueCollectionEntryColors.bodyBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: DueCollectionEntryColors.brandGold, width: 1.4),
        ),
      ),
    );
  }
}

class _SetupTargetSelector extends StatelessWidget {
  final bool isPrimary;
  final ValueChanged<bool> onChanged;

  const _SetupTargetSelector({
    required this.isPrimary,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SetupTargetCard(
            selected: isPrimary,
            icon: DueCollectionEntryIcons.verified,
            title: 'Primary Account',
            subtitle: 'Update Shop Profile primary bank',
            onTap: () => onChanged(true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SetupTargetCard(
            selected: !isPrimary,
            icon: DueCollectionEntryIcons.bank,
            title: 'Additional Account',
            subtitle: 'Create another banking account',
            onTap: () => onChanged(false),
          ),
        ),
      ],
    );
  }
}

class _SetupTargetCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SetupTargetCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? DueCollectionEntryColors.brandGold
        : DueCollectionEntryColors.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? DueCollectionEntryColors.brandGoldLight
              : DueCollectionEntryColors.panelSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? DueCollectionEntryColors.brandGold
                : DueCollectionEntryColors.bodyBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DueCollectionEntryStyles.rowTitle
                        .copyWith(color: DueCollectionEntryColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: DueCollectionEntryStyles.rowSub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
