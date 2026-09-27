part of '../girvi_account_detail_screen.dart';

extension _GirviAccountDocumentsPanel on _GirviAccountDetailScreenState {
  Widget _buildAccountDocuments(
    GirviLoanWithCustomer account,
    bool actionEnabled,
  ) {
    final balanceCleared =
        GirviAccountLifecycleSummary.isSettlementComplete(account);
    final balanceColor =
        balanceCleared ? GirviColors.success : GirviColors.danger;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _AccountIconBox(
                icon: Icons.folder_copy_rounded,
                color: GirviColors.brandGold,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Actions',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: GirviColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Invoice preview and settlement workflow',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: GirviColors.textBody,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: balanceColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: balanceColor.withValues(alpha: 0.16)),
            ),
            child: Row(
              children: [
                Icon(
                  balanceCleared
                      ? Icons.verified_rounded
                      : Icons.pending_actions_rounded,
                  color: balanceColor,
                  size: 18,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    balanceCleared
                        ? 'No payable balance on this account'
                        : 'Net payable ${_money(account.totalPayable)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: GirviColors.textDark,
                      fontSize: 12.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _AccountDocumentButton(
            icon: Icons.visibility_rounded,
            title: 'View Girvi Invoice',
            subtitle: _openingGirviInvoice
                ? 'Opening...'
                : 'Invoice, interest and release pages',
            color: GirviColors.brandGold,
            onTap: _openingGirviInvoice ? null : _previewGirviInvoice,
          ),
          if (actionEnabled) ...[
            const SizedBox(height: 14),
            _AccountPrimaryCommandButton(
              icon: account.loan.girviStatus == GirviStatus.readyForDelivery
                  ? GirviIcons.markDone
                  : GirviIcons.cash,
              label: _settlementActionLabel(account),
              onTap: _openInterestEntry,
            ),
          ],
        ],
      ),
    );
  }
}
