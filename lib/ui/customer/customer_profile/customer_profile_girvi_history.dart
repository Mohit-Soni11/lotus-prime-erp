part of 'customer_profile_screen.dart';

extension _ProfileGirviHistory on _CustomerProfileScreenState {
  Widget _buildGirviList(CustomerProfileModel p) {
    if (p.loans.isEmpty) {
      return _emptyState(
        icon: Icons.lock_outline_rounded,
        title: "No Girvi tickets yet",
        sub: "Pledge records will appear here after the first Girvi entry.",
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: p.loans.length,
      itemBuilder: (_, i) => _buildGirviRow(p.loans[i]),
    );
  }

  Widget _buildGirviRow(CustomerLoanModel loan) {
    final bool active = loan.isActive;
    final status = loan.lifecycleStatus;
    final Color statusColor = _girviStatusColor(status.dbValue);
    final Color statusBg = _girviStatusBackground(status.dbValue);
    final Color statusBorder = _girviStatusBorder(status.dbValue);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showGirviActions(loan),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CustomerProfileColors.bodyBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? statusBorder : CustomerProfileColors.bodyBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      active ? Icons.lock_rounded : Icons.lock_open_rounded,
                      color: statusColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loan.loanNo,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: CustomerProfileColors.bodyTextMain,
                            )),
                        Text(loan.itemDesc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: CustomerProfileColors.bodyTextMuted,
                            )),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      loan.statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.more_horiz_rounded,
                    size: 20,
                    color: CustomerProfileColors.bodyTextMuted,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: CustomerProfileColors.divider),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _girviDetail(
                      "Girvi Principal",
                      "\u20B9${loan.loanAmount.toStringAsFixed(0)}",
                      const Color(0xFF7C3AED),
                    ),
                  ),
                  Expanded(
                    child: _girviDetail(
                      "Weight",
                      "${loan.grossWeight.toStringAsFixed(2)} g",
                      CustomerProfileColors.brandGold,
                    ),
                  ),
                  Expanded(
                    child: _girviDetail(
                      "Interest Rate",
                      "${loan.interestRate.toStringAsFixed(0)}%",
                      const Color(0xFFEA580C),
                    ),
                  ),
                ],
              ),
              if (active) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _girviDetail(
                        "Accrued Interest",
                        "\u20B9${loan.accruedInterest.toStringAsFixed(0)}",
                        const Color(0xFFEF4444),
                      ),
                    ),
                    Expanded(
                      child: _girviDetail(
                        "Days Active",
                        "${loan.daysActive} days",
                        const Color(0xFF0891B2),
                      ),
                    ),
                    Expanded(
                      child: _girviDetail(
                        "Started On",
                        loan.formattedDate,
                        CustomerProfileColors.bodyTextMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _girviStatusColor(String status) {
    switch (status) {
      case 'OVERDUE':
        return const Color(0xFFDC2626);
      case 'PARTIAL_RELEASE':
        return const Color(0xFFD97706);
      case 'READY_FOR_DELIVERY':
        return const Color(0xFF2563EB);
      case 'RELEASED':
      case 'AUCTIONED':
        return const Color(0xFF059669);
      case 'ACTIVE':
      default:
        return const Color(0xFF047857);
    }
  }

  Color _girviStatusBackground(String status) {
    switch (status) {
      case 'OVERDUE':
        return const Color(0xFFFEE2E2);
      case 'PARTIAL_RELEASE':
        return const Color(0xFFFFF7ED);
      case 'READY_FOR_DELIVERY':
        return const Color(0xFFEFF6FF);
      case 'RELEASED':
      case 'AUCTIONED':
        return const Color(0xFFD1FAE5);
      case 'ACTIVE':
      default:
        return const Color(0xFFD1FAE5);
    }
  }

  Color _girviStatusBorder(String status) {
    switch (status) {
      case 'OVERDUE':
        return const Color(0xFFFCA5A5);
      case 'PARTIAL_RELEASE':
        return const Color(0xFFFCD34D);
      case 'READY_FOR_DELIVERY':
        return const Color(0xFF93C5FD);
      case 'RELEASED':
      case 'AUCTIONED':
        return const Color(0xFFA7F3D0);
      case 'ACTIVE':
      default:
        return const Color(0xFFA7F3D0);
    }
  }
}
