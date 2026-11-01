part of 'cash_book_transaction_list.dart';

class _LoadingShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: const Color(0xFFE8E3D8),
        highlightColor: const Color(0xFFF5F0E8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Empty State â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddEntry;
  final VoidCallback onClear;
  final bool filtered;
  const _EmptyState({
    required this.onAddEntry,
    required this.onClear,
    required this.filtered,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: CashBookColors.summaryChipBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: CashBookColors.bodyBorder),
            ),
            child: const Icon(CashBookIcons.moduleIcon,
                size: 32, color: CashBookColors.textMuted),
          ),
          const SizedBox(height: 16),
          Text(
              filtered
                  ? 'No matching transactions'
                  : CashBookStrings.noTransactions,
              style: CashBookStyles.labelPrimary),
          const SizedBox(height: 6),
          Text(
              filtered
                  ? 'Try another search or filter.'
                  : CashBookStrings.noTransactionsHint,
              style: CashBookStyles.labelSecondary,
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: filtered ? onClear : onAddEntry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: CashBookColors.brandGold,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                    filtered
                        ? Icons.filter_alt_off_rounded
                        : CashBookIcons.addEntry,
                    size: 16,
                    color: const Color(0xFF111827)),
                const SizedBox(width: 8),
                Text(filtered ? 'Clear Filters' : 'Add First Entry',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    )),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
