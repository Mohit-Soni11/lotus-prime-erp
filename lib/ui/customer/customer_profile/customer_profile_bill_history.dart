part of 'customer_profile_screen.dart';

extension _ProfileBillHistory on _CustomerProfileScreenState {
  Widget _buildHistoryTabs(CustomerProfileModel p) {
    return Container(
      key: _historyKey,
      decoration: CustomerProfileStyles.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: Text('Transaction History',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: CustomerProfileColors.bodyTextMain)),
          ),
          Container(
            color: CustomerProfileColors.bodyPanelBg,
            child: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: CustomerProfileColors.bodyTextMain,
              unselectedLabelColor: CustomerProfileColors.bodyTextMain,
              indicatorColor: CustomerProfileColors.brandGold,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CustomerProfileIcons.invoice, size: 15),
                      const SizedBox(width: 5),
                      Text("Sales Bills (${p.totalBills})"),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 15),
                      const SizedBox(width: 5),
                      Text("Girvi Tickets (${p.totalLoans})"),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CustomerProfileIcons.advanceOrder, size: 15),
                      const SizedBox(width: 5),
                      Text("Advance Orders (${p.advanceOrders.length})"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 480,
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildBillsList(p),
                _buildGirviList(p),
                _buildAdvanceList(p),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillsList(CustomerProfileModel p) {
    if (p.bills.isEmpty) {
      return _emptyState(
        icon: CustomerProfileIcons.emptyBills,
        title: CustomerProfileStrings.noBills,
        sub: CustomerProfileStrings.noBillsSub,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: p.bills.length,
      itemBuilder: (_, i) => _buildBillRow(p.bills[i]),
    );
  }

  Widget _buildBillRow(CustomerBillModel bill) {
    final bool paid = bill.isPaid;
    final bool partial = bill.isPartial;
    final Color statusBg = paid
        ? CustomerProfileColors.paidBg
        : partial
            ? CustomerProfileColors.dueBg
            : CustomerProfileColors.unpaidBg;
    final Color statusText = paid
        ? CustomerProfileColors.paidText
        : partial
            ? CustomerProfileColors.dueText
            : CustomerProfileColors.unpaidText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showBillActions(bill),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: CustomerProfileColors.bodyBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CustomerProfileColors.bodyBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  CustomerProfileIcons.invoice,
                  color: statusText,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bill.billNo, style: CustomerProfileStyles.billNo),
                    const SizedBox(height: 2),
                    Text(
                      bill.formattedDate,
                      style: CustomerProfileStyles.billDate,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Paid ${bill.formattedPaidAmount} | Due ${bill.formattedDueAmount}",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: CustomerProfileColors.bodyTextMain,
                      ),
                    ),
                    if (bill.isFromAdvanceOrder) ...[
                      const SizedBox(height: 5),
                      _advanceSourceChip(bill.advanceSourceLabel),
                    ],
                    if (bill.hasLinkedDocuments) ...[
                      const SizedBox(height: 6),
                      _billLinkedDocumentStrip(bill),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      bill.formattedAmount,
                      style: CustomerProfileStyles.billAmount,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 6,
                      runSpacing: 6,
                      children: _billStatusChips(
                        bill,
                        paymentBg: statusBg,
                        paymentText: statusText,
                      ),
                    ),
                  ],
                ),
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

  List<Widget> _billStatusChips(
    CustomerBillModel bill, {
    required Color paymentBg,
    required Color paymentText,
  }) {
    final chips = <Widget>[
      CustomerProfileBillStatusChip(
        label: bill.paymentLabel,
        backgroundColor: paymentBg,
        textColor: paymentText,
      ),
    ];

    if (bill.lifecycleLabel.isNotEmpty) {
      chips.add(
        CustomerProfileBillStatusChip(
          label: bill.lifecycleLabel,
          backgroundColor: _billLifecycleBg(bill),
          textColor: _billLifecycleText(bill),
        ),
      );
    }
    if (bill.returnProgressLabel.isNotEmpty) {
      chips.add(
        CustomerProfileBillStatusChip(
          label: bill.returnProgressLabel,
          backgroundColor: CustomerProfileColors.brandGoldLight,
          textColor: CustomerProfileColors.bodyTextMain,
        ),
      );
    }
    if (bill.returnedAmount > 0.009) {
      chips.add(
        CustomerProfileBillStatusChip(
          label: 'RETURN ${bill.formattedReturnedAmount}',
          backgroundColor: CustomerProfileColors.advanceBg,
          textColor: CustomerProfileColors.advanceAccent,
        ),
      );
    }
    return chips;
  }

  Color _billLifecycleBg(CustomerBillModel bill) {
    if (bill.isCancelled) return CustomerProfileColors.deleteBg;
    if (bill.hasReturnActivity) return CustomerProfileColors.dueBg;
    return CustomerProfileColors.editBg;
  }

  Color _billLifecycleText(CustomerBillModel bill) {
    if (bill.isCancelled) return CustomerProfileColors.deleteText;
    if (bill.hasReturnActivity) return CustomerProfileColors.dueText;
    return CustomerProfileColors.editText;
  }

  Widget _billLinkedDocumentStrip(CustomerBillModel bill) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.account_tree_rounded,
          size: 13,
          color: CustomerProfileColors.historyText,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            bill.linkedDocumentSummary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: CustomerProfileColors.bodyTextMain,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}
