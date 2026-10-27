part of 'customer_profile_screen.dart';

extension _ProfileDuesSection on _CustomerProfileScreenState {
  Widget _buildDuesSection(CustomerProfileModel p) {
    return Container(
      decoration: BoxDecoration(
        color: CustomerProfileColors.duesSectionBg,
        borderRadius: BorderRadius.circular(CustomerProfileStyles.cardRadius),
        border: Border.all(color: CustomerProfileColors.duesSectionBorder),
        boxShadow: const [
          BoxShadow(
            color: CustomerProfileColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _sectionHeader(
                  icon: CustomerProfileIcons.duesSection,
                  title: CustomerProfileStrings.secDues,
                  color: CustomerProfileColors.duesSectionAccent,
                ),
                Text('${p.dues.length} due invoices',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CustomerProfileColors.bodyTextMain)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CustomerProfileColors.dueTotalBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: CustomerProfileColors.dueBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CustomerProfileIcons.dueAmount,
                        size: 13,
                        color: CustomerProfileColors.dueTotalText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Total Due: ₹${_fmt(p.totalDueAmount)}",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: CustomerProfileColors.bodyTextMain,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(
              height: 1, color: CustomerProfileColors.duesSectionBorder),
          // Due rows
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: p.dues.length,
            itemBuilder: (_, i) => _buildDueRow(p.dues[i],
                p.bills.firstWhere((bill) => bill.id == p.dues[i].billId)),
          ),
        ],
      ),
    );
  }

  Widget _buildDueRow(CustomerDueModel due, CustomerBillModel bill) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showBillActions(bill),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: CustomerProfileColors.dueRowBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CustomerProfileColors.dueRowBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: CustomerProfileColors.dueBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CustomerProfileIcons.dueBill,
                  color: CustomerProfileColors.dueIcon,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      due.billNo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: CustomerProfileColors.duesBillNo,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${due.formattedDate} | Open invoice actions",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: CustomerProfileColors.bodyTextMain,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    due.formattedDue,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: CustomerProfileColors.bodyTextMain,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: CustomerProfileColors.dueBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "PENDING",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: CustomerProfileColors.dueText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.more_horiz_rounded,
                size: 18,
                color: CustomerProfileColors.bodyTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
