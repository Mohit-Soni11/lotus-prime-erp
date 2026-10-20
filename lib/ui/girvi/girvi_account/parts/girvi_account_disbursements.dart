part of '../girvi_account_detail_screen.dart';

extension _GirviAccountDisbursements on _GirviAccountDetailScreenState {
  Widget _buildDisbursementPanel(List<GirviDisbursement> entries) {
    final total = entries.fold<double>(0, (sum, entry) => sum + entry.amount);

    return _AccountSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _AccountSectionHeader(
            icon: Icons.account_balance_wallet_rounded,
            color: GirviColors.info,
            title: 'Loan Disbursement',
            subtitle: 'How the pledge amount was paid out',
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < entries.length; index++) ...[
            if (index > 0) const SizedBox(height: 8),
            _AccountDisbursementRow(
              entry: entries[index],
              amount: _money(entries[index].amount),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total Disbursed',
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _money(total),
                    style: GoogleFonts.manrope(
                      color: GirviColors.success,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
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

class _AccountDisbursementRow extends StatelessWidget {
  const _AccountDisbursementRow({required this.entry, required this.amount});

  final GirviDisbursement entry;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final reference = entry.referenceNo?.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Row(
        children: [
          const _AccountIconBox(
            icon: Icons.payments_rounded,
            color: GirviColors.info,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (reference != null && reference.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Reference $reference',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: GirviColors.textBody,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                amount,
                style: GoogleFonts.manrope(
                  color: GirviColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
