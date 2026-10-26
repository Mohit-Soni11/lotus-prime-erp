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
            child: Row(
              children: [
                _sectionHeader(
                  icon: CustomerProfileIcons.duesSection,
                  title: CustomerProfileStrings.secDues,
                  color: CustomerProfileColors.duesSectionAccent,
                ),
                const Spacer(),
                // Total due badge
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
                        "Total Due: \u20B9${_fmt(p.totalDueAmount)}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: CustomerProfileColors.dueTotalText,
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
            itemBuilder: (_, i) => _buildDueRow(p.dues[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildDueRow(CustomerDueModel due) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showBillActions(
          CustomerBillModel(
            id: due.billId,
            billNo: due.billNo,
            totalAmount: due.totalAmount,
            paidAmount: due.paidAmount,
            status: due.paidAmount > 0 ? 'PARTIAL' : 'UNPAID',
            billDate: due.billDate,
            sourceAdvanceOrderId: due.sourceAdvanceOrderId,
            sourceAdvanceOrderNo: due.sourceAdvanceOrderNo,
          ),
        ),
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
                        fontSize: 11,
                        color: CustomerProfileColors.bodyTextMuted,
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
                      color: CustomerProfileColors.duesAmount,
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
                        fontSize: 9,
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
