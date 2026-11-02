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
  final VoidCallback onClear;
  final bool filtered;
  const _EmptyState({
    required this.onClear,
    required this.filtered,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
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
                    ? 'No matching transactions this month'
                    : 'No cash transactions this month',
                style: CashBookStyles.labelPrimary),
            const SizedBox(height: 6),
            Text(
                filtered
                    ? 'Choose All to see every cash movement this month.'
                    : 'Cash receipts and payments will appear here automatically.',
                style: CashBookStyles.labelSecondary,
                textAlign: TextAlign.center),
            if (filtered) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onClear,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: CashBookColors.brandGold,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.filter_alt_off_rounded,
                        size: 16, color: Color(0xFF111827)),
                    SizedBox(width: 8),
                    Text('Clear Filters',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        )),
                  ]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
