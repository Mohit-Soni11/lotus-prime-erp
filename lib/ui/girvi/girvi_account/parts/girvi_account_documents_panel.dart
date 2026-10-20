part of '../girvi_account_detail_screen.dart';

extension _GirviAccountDocumentsPanel on _GirviAccountDetailScreenState {
  Widget _buildAccountDocuments(
    GirviLoanWithCustomer account,
    bool actionEnabled,
  ) {
    final documentBusy = _openingGirviInvoice || _printingGirviInvoice;

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
                      'Invoice and settlement',
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
          Row(
            children: [
              Expanded(
                child: _AccountDocumentButton(
                  icon: Icons.visibility_rounded,
                  label: _openingGirviInvoice ? 'Opening...' : 'Preview PDF',
                  color: GirviColors.brandGold,
                  onTap: documentBusy ? null : _previewGirviInvoice,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AccountDocumentButton(
                  icon: Icons.print_rounded,
                  label: _printingGirviInvoice ? 'Preparing...' : 'Print PDF',
                  color: GirviColors.info,
                  onTap: documentBusy ? null : _printGirviInvoice,
                ),
              ),
            ],
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
