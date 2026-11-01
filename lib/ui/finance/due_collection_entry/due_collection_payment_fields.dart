part of 'due_collection_entry_screen.dart';

class _BankAccountDropdown extends StatelessWidget {
  final DueCollectionEntryController ctrl;

  const _BankAccountDropdown({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (ctrl.bankAccounts.isEmpty) {
      return const _MessageBox(
          message:
              'No active bank account found. Click Save to set bank/UPI details first.',
          isError: true);
    }
    final accounts = ctrl.bankAccounts;
    final selected = ctrl.selectedBankAccount ?? accounts.first;
    final selectedIndex = accounts.indexWhere((a) => a.id == selected.id);
    return PopupMenuButton<int>(
      tooltip: 'Select payment account',
      color: DueCollectionEntryColors.bodyPanel,
      elevation: 10,
      offset: const Offset(0, 8),
      constraints: const BoxConstraints(minWidth: 320, maxWidth: 430),
      onSelected: ctrl.setBankAccount,
      itemBuilder: (context) => List.generate(accounts.length, (index) {
        final account = accounts[index];
        return PopupMenuItem<int>(
          value: account.id,
          padding: EdgeInsets.zero,
          child: _PaymentAccountOption(
            account: account,
            role: _accountRole(account, index),
            selected: account.id == selected.id,
          ),
        );
      }),
      child: _SelectedPaymentAccountCard(
        account: selected,
        role: _accountRole(selected, selectedIndex < 0 ? 0 : selectedIndex),
      ),
    );
  }

  String _accountRole(DueCollectionBankAccountModel account, int index) {
    if (account.isPrimary || index == 0) return 'Primary Bank';
    if (index == 1) return 'Secondary Bank';
    return 'Additional Bank ${index + 1}';
  }
}

class _SelectedPaymentAccountCard extends StatelessWidget {
  final DueCollectionBankAccountModel account;
  final String role;

  const _SelectedPaymentAccountCard({
    required this.account,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: DueCollectionEntryStyles.flatPanel(
        color: DueCollectionEntryColors.panelSoft,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DueCollectionEntryColors.brandGoldLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(DueCollectionEntryIcons.bank,
                size: 18, color: DueCollectionEntryColors.brandGold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(role,
                          style: DueCollectionEntryStyles.label.copyWith(
                              color: DueCollectionEntryColors.brandGold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (account.hasUpi) ...[
                      const SizedBox(width: 6),
                      const _MiniAccountBadge(label: 'UPI'),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _accountTitle(account),
                  style: DueCollectionEntryStyles.rowTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _accountMeta(account),
                  style: DueCollectionEntryStyles.rowSub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down_rounded,
              size: 20, color: DueCollectionEntryColors.textMuted),
        ],
      ),
    );
  }
}

class _PaymentAccountOption extends StatelessWidget {
  final DueCollectionBankAccountModel account;
  final String role;
  final bool selected;

  const _PaymentAccountOption({
    required this.account,
    required this.role,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: selected
          ? DueCollectionEntryColors.brandGoldLight
          : DueCollectionEntryColors.bodyPanel,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: selected
                ? DueCollectionEntryColors.brandGold
                : DueCollectionEntryColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role,
                    style: DueCollectionEntryStyles.label.copyWith(
                        color: selected
                            ? DueCollectionEntryColors.brandGold
                            : DueCollectionEntryColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  _accountTitle(account),
                  style: DueCollectionEntryStyles.rowTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _accountMeta(account),
                  style: DueCollectionEntryStyles.rowSub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (account.hasUpi) const _MiniAccountBadge(label: 'UPI'),
        ],
      ),
    );
  }
}

class _MiniAccountBadge extends StatelessWidget {
  final String label;

  const _MiniAccountBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: DueCollectionEntryColors.successBg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: DueCollectionEntryColors.success.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: DueCollectionEntryStyles.rowSub.copyWith(
          color: DueCollectionEntryColors.success,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _accountTitle(DueCollectionBankAccountModel account) {
  if (account.bankName.trim().isEmpty) return account.accountName;
  return '${account.accountName} - ${account.bankName}';
}

String _accountMeta(DueCollectionBankAccountModel account) {
  final parts = <String>[];
  final number = _maskAccountNumber(account.accountNumber);
  if (number.isNotEmpty) parts.add(number);
  final upi = account.upiId?.trim() ?? '';
  if (upi.isNotEmpty) parts.add(upi);
  return parts.isEmpty ? 'Account detail saved' : parts.join('  |  ');
}

String _maskAccountNumber(String value) {
  final text = value.trim();
  if (text.isEmpty) return '';
  if (text.startsWith('UPI:')) return text.substring(4);
  if (text.length <= 4) return text;
  return 'xxxx ${text.substring(text.length - 4)}';
}
