part of 'supplier_profile_screen.dart';

typedef _SupplierProfileSectionHeader = Widget Function(
  String title,
  String subtitle,
  IconData icon,
  Color color,
);

Widget _supplierProfileStatsOverview(SupplierProfileModel profile) {
  return Row(
    children: [
      Expanded(
        child: _StatBox(
          icon: SupplierProfileIcons.purchases,
          label: 'Purchases',
          value: profile.purchaseCount.toString(),
          color: SupplierProfileColors.info,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _StatBox(
          icon: SupplierProfileIcons.amount,
          label: 'Purchase Value',
          value: _money(profile.totalPurchaseValue),
          color: SupplierProfileColors.brandGold,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _StatBox(
          icon: SupplierProfileIcons.inventory,
          label: 'Stock Entries',
          value: profile.totalStockEntries.toString(),
          color: SupplierProfileColors.violet,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _StatBox(
          icon: SupplierProfileIcons.metal,
          label: 'Fine Given',
          value: '${_weight(profile.totalMetalFine)} g',
          color: SupplierProfileColors.metalText,
        ),
      ),
    ],
  );
}

Widget _supplierProfileContactCard(
  SupplierProfileModel profile, {
  required _SupplierProfileSectionHeader sectionHeader,
}) {
  return Container(
    decoration: SupplierProfileStyles.cardDecoration,
    padding: SupplierProfileStyles.cardPadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader(
          SupplierProfileStrings.secContact,
          'Active phone, WhatsApp and contact person',
          SupplierProfileIcons.contact,
          SupplierProfileColors.info,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumn = constraints.maxWidth > 760;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _InfoTile(
                  width: twoColumn ? (constraints.maxWidth - 12) / 2 : null,
                  icon: SupplierProfileIcons.phone,
                  label: SupplierProfileStrings.lblMobile,
                  value: profile.mobile,
                ),
                _InfoTile(
                  width: twoColumn ? (constraints.maxWidth - 12) / 2 : null,
                  icon: SupplierProfileIcons.whatsapp,
                  label: SupplierProfileStrings.lblWhatsapp,
                  value: _valueOrNa(profile.whatsapp),
                ),
                _InfoTile(
                  width: twoColumn ? (constraints.maxWidth - 12) / 2 : null,
                  icon: SupplierProfileIcons.email,
                  label: SupplierProfileStrings.lblEmail,
                  value: _valueOrNa(profile.email),
                ),
                _InfoTile(
                  width: twoColumn ? (constraints.maxWidth - 12) / 2 : null,
                  icon: SupplierProfileIcons.contact,
                  label: SupplierProfileStrings.lblContactPerson,
                  value: profile.primaryContactName,
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

Widget _supplierProfileLedgerCard(
  SupplierProfileModel profile, {
  required _SupplierProfileSectionHeader sectionHeader,
}) {
  final healthColor = _healthColor(profile.ledgerHealth);
  final totalExposure = profile.openingBalance +
      profile.voucherDueTotal +
      profile.oldDueAdjustedTotal;
  final paidRatio = totalExposure <= 0
      ? 1.0
      : ((totalExposure - profile.outstandingDue) / totalExposure)
          .clamp(0.0, 1.0)
          .toDouble();

  return Container(
    decoration: SupplierProfileStyles.cardDecoration,
    padding: SupplierProfileStyles.cardPadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader(
          SupplierProfileStrings.secLedger,
          'Opening balance, old due adjustment and current baki',
          SupplierProfileIcons.ledger,
          SupplierProfileColors.brandGold,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: SupplierProfileStrings.lblOpening,
                value: _money(profile.openingBalance),
                color: SupplierProfileColors.documentAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                label: SupplierProfileStrings.lblVoucherDue,
                value: _money(profile.voucherDueTotal),
                color: SupplierProfileColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                label: SupplierProfileStrings.lblAdjusted,
                value: _money(profile.oldDueAdjustedTotal),
                color: SupplierProfileColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                label: SupplierProfileStrings.lblCurrentDue,
                value: _money(profile.outstandingDue),
                color: healthColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: paidRatio,
            backgroundColor: SupplierProfileColors.bodyBorder,
            valueColor: AlwaysStoppedAnimation<Color>(
              profile.hasOutstandingDue
                  ? SupplierProfileColors.warning
                  : SupplierProfileColors.success,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          profile.hasOutstandingDue
              ? 'Pending amount remains linked to this supplier ledger.'
              : 'Supplier ledger is fully settled.',
          style: SupplierProfileStyles.historyMeta,
        ),
      ],
    ),
  );
}

Widget _supplierProfileDuesSection(
  SupplierProfileModel profile, {
  required _SupplierProfileSectionHeader sectionHeader,
}) {
  return Container(
    decoration:
        SupplierProfileStyles.tintedPanel(SupplierProfileColors.warning),
    padding: SupplierProfileStyles.cardPadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader(
          SupplierProfileStrings.secDues,
          'Pending purchase balances for this supplier',
          SupplierProfileIcons.due,
          SupplierProfileColors.warning,
        ),
        const SizedBox(height: 12),
        for (final item in profile.duePurchases.take(3)) ...[
          _supplierProfileDueRow(item),
          const SizedBox(height: 8),
        ],
        if (profile.duePurchases.length > 3)
          Text(
            '+${profile.duePurchases.length - 3} more pending voucher(s)',
            style: SupplierProfileStyles.historyMeta.copyWith(
              color: SupplierProfileColors.warning,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    ),
  );
}

Widget _supplierProfileDueRow(SupplierProfilePurchaseModel item) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: SupplierProfileColors.bodyPanelBg.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: SupplierProfileColors.warning.withValues(alpha: 0.25),
      ),
    ),
    child: Row(
      children: [
        const Icon(
          SupplierProfileIcons.purchases,
          color: SupplierProfileColors.warning,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${item.voucherNo} | ${item.formattedDate}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SupplierProfileStyles.historyTitle,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          _money(item.balanceDue),
          style: SupplierProfileStyles.infoValue.copyWith(
            color: SupplierProfileColors.warning,
          ),
        ),
      ],
    ),
  );
}

Widget _supplierProfileBusinessCard(
  SupplierProfileModel profile, {
  required _SupplierProfileSectionHeader sectionHeader,
}) {
  return Container(
    decoration: SupplierProfileStyles.cardDecoration,
    padding: SupplierProfileStyles.cardPadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader(
          SupplierProfileStrings.secBusiness,
          'Supplier type, GST, PAN, address and notes',
          SupplierProfileIcons.business,
          SupplierProfileColors.violet,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumn = constraints.maxWidth > 760;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _InfoTile(
                  width: twoColumn ? (constraints.maxWidth - 12) / 2 : null,
                  icon: SupplierProfileIcons.business,
                  label: SupplierProfileStrings.lblSupplierType,
                  value: profile.typeLabel,
                ),
                _InfoTile(
                  width: twoColumn ? (constraints.maxWidth - 12) / 2 : null,
                  icon: SupplierProfileIcons.clear,
                  label: SupplierProfileStrings.lblStatus,
                  value: profile.statusLabel,
                ),
                _InfoTile(
                  width: twoColumn ? (constraints.maxWidth - 12) / 2 : null,
                  icon: SupplierProfileIcons.gst,
                  label: SupplierProfileStrings.lblGst,
                  value: _valueOrNa(profile.gstNumber),
                ),
                _InfoTile(
                  width: twoColumn ? (constraints.maxWidth - 12) / 2 : null,
                  icon: SupplierProfileIcons.pan,
                  label: SupplierProfileStrings.lblPan,
                  value: _valueOrNa(profile.panNumber),
                ),
                _InfoTile(
                  width: constraints.maxWidth,
                  icon: SupplierProfileIcons.location,
                  label: SupplierProfileStrings.lblAddress,
                  value: profile.addressLine,
                ),
                _InfoTile(
                  width: constraints.maxWidth,
                  icon: SupplierProfileIcons.notes,
                  label: 'Notes',
                  value: _valueOrNa(profile.notes),
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double? width;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: const EdgeInsets.all(14),
      decoration: SupplierProfileStyles.softPanelDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration:
                SupplierProfileStyles.tintedPanel(SupplierProfileColors.info),
            child: Icon(icon, size: 18, color: SupplierProfileColors.info),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: SupplierProfileStyles.infoLabel),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: SupplierProfileStyles.infoValue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return width == null ? tile : SizedBox(width: width, child: tile);
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: SupplierProfileStyles.tintedPanel(color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SupplierProfileStyles.statLabel.copyWith(color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SupplierProfileStyles.statValue.copyWith(
              fontSize: 18,
              color: SupplierProfileColors.bodyTextMain,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(16),
      decoration: SupplierProfileStyles.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: SupplierProfileStyles.tintedPanel(color),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SupplierProfileStyles.statValue,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SupplierProfileStyles.statLabel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseHistoryCard extends StatelessWidget {
  final SupplierProfilePurchaseModel item;

  const _PurchaseHistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final dueColor = item.hasDue
        ? SupplierProfileColors.warning
        : SupplierProfileColors.success;
    final taxColor = item.isGstPurchase
        ? SupplierProfileColors.info
        : SupplierProfileColors.bodyTextMuted;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: SupplierProfileStyles.softPanelDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BillThumb(path: item.billPhotoPath),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.voucherNo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SupplierProfileStyles.historyTitle,
                      ),
                    ),
                    _MiniBadge(
                      item.isGstPurchase ? 'GST' : 'No ITC',
                      taxColor,
                    ),
                    const SizedBox(width: 8),
                    _MiniBadge(item.statusLabel, dueColor),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  [
                    item.formattedDate,
                    '${item.stockEntryCount} stock item(s)',
                    if ((item.supplierInvoiceNo ?? '').trim().isNotEmpty)
                      'Supplier bill ${item.supplierInvoiceNo}',
                  ].join(' | '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SupplierProfileStyles.historyMeta,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniBadge(
                      'Bill ${_money(item.grandTotal)}',
                      SupplierProfileColors.brandGold,
                    ),
                    _MiniBadge(
                      'Paid ${_money(item.totalPaid)}',
                      SupplierProfileColors.success,
                    ),
                    _MiniBadge(
                      'Baki ${_money(item.balanceDue)}',
                      dueColor,
                    ),
                    if (item.hasOldDueAdjustment)
                      _MiniBadge(
                        'Old due adjusted ${_money(item.oldDueAdjustedAmount)}',
                        SupplierProfileColors.success,
                      ),
                    if (item.hasMetalSettlement)
                      _MiniBadge(
                        '${_weight(item.metalPaidFine)} g fine',
                        SupplierProfileColors.metalText,
                      ),
                    if (item.hasMetalFineDue)
                      _MiniBadge(
                        'Fine due ${_weight(item.metalFineDue)} g',
                        dueColor,
                      ),
                    if (item.hasMetalFineCredit)
                      _MiniBadge(
                        'Fine credit ${_weight(item.metalFineCredit)} g',
                        SupplierProfileColors.success,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetalSettlementCard extends StatelessWidget {
  final SupplierProfilePurchaseModel item;

  const _MetalSettlementCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration:
          SupplierProfileStyles.tintedPanel(SupplierProfileColors.metalText),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: SupplierProfileStyles.tintedPanel(
                SupplierProfileColors.metalText),
            child: const Icon(
              SupplierProfileIcons.metal,
              color: SupplierProfileColors.metalText,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.voucherNo, style: SupplierProfileStyles.historyTitle),
                const SizedBox(height: 4),
                Text(
                  '${item.formattedDate} | ${item.metalLineCount} metal box(es)',
                  style: SupplierProfileStyles.historyMeta,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _SettlementMetric(
            label: 'Gross',
            value: '${_weight(item.metalPaidGrossWeight)} g',
          ),
          const SizedBox(width: 10),
          _SettlementMetric(
            label: 'Purity',
            value: '${_weight(item.metalPaidPurity)}%',
          ),
          const SizedBox(width: 10),
          _SettlementMetric(
            label: 'Fine',
            value: '${_weight(item.metalPaidFine)} g',
          ),
          const SizedBox(width: 10),
          _SettlementMetric(
            label: 'Value',
            value: _money(item.metalPaidValue),
          ),
          if (item.hasMetalFineDue) ...[
            const SizedBox(width: 10),
            _SettlementMetric(
              label: 'Fine Due',
              value: '${_weight(item.metalFineDue)} g',
            ),
          ],
          if (item.hasMetalFineCredit) ...[
            const SizedBox(width: 10),
            _SettlementMetric(
              label: 'Fine Credit',
              value: '${_weight(item.metalFineCredit)} g',
            ),
          ],
        ],
      ),
    );
  }
}

class _SettlementMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SettlementMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SupplierProfileStyles.statLabel.copyWith(
              color: SupplierProfileColors.metalText,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SupplierProfileStyles.infoValue,
          ),
        ],
      ),
    );
  }
}

class _BillDocumentCard extends StatelessWidget {
  final SupplierProfilePurchaseModel item;

  const _BillDocumentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final path = item.billPhotoPath;
    final exists = path != null && File(path).existsSync();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: SupplierProfileStyles.softPanelDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 124,
            height: 82,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: SupplierProfileColors.bodyBorder,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SupplierProfileColors.bodyBorder),
            ),
            child: exists
                ? Image.file(File(path), fit: BoxFit.cover)
                : const Icon(
                    SupplierProfileIcons.photo,
                    color: SupplierProfileColors.bodyTextMuted,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.voucherNo, style: SupplierProfileStyles.historyTitle),
                const SizedBox(height: 5),
                Text(
                  '${item.formattedDate} | Bill ${_money(item.grandTotal)}',
                  style: SupplierProfileStyles.historyMeta,
                ),
                const SizedBox(height: 10),
                _MiniBadge(
                  exists ? _fileName(path) : 'Photo path saved',
                  SupplierProfileColors.documentAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BillThumb extends StatelessWidget {
  final String? path;

  const _BillThumb({this.path});

  @override
  Widget build(BuildContext context) {
    final exists = path != null && File(path!).existsSync();
    return Container(
      width: 64,
      height: 64,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: SupplierProfileColors.bodyBorder,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SupplierProfileColors.bodyBorder),
      ),
      child: exists
          ? Image.file(File(path!), fit: BoxFit.cover)
          : const Icon(
              SupplierProfileIcons.purchases,
              color: SupplierProfileColors.bodyTextMuted,
            ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniBadge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: SupplierProfileStyles.tintedPanel(color),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: SupplierProfileStyles.chipText.copyWith(color: color),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: SupplierProfileStyles.softPanelDecoration,
      child: Column(
        children: [
          Icon(icon, size: 38, color: SupplierProfileColors.bodyTextMuted),
          const SizedBox(height: 12),
          Text(title, style: SupplierProfileStyles.sectionTitle),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: SupplierProfileStyles.historyMeta,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final Color border;
  final VoidCallback onTap;
  final bool filled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.border,
    required this.onTap,
    this.filled = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.025 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: SupplierProfileStyles.actionButtonHeight,
            decoration: BoxDecoration(
              color: widget.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.border,
                width: widget.filled ? 0 : 1.4,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: widget.border.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: widget.fg, size: 20),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SupplierProfileStyles.chipText.copyWith(
                    color: widget.fg,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _healthColor(SupplierLedgerHealth health) {
  switch (health) {
    case SupplierLedgerHealth.clear:
      return SupplierProfileColors.success;
    case SupplierLedgerHealth.due:
      return SupplierProfileColors.warning;
    case SupplierLedgerHealth.watch:
      return SupplierProfileColors.danger;
  }
}

Color _typeColor(SupplierType type) {
  switch (type) {
    case SupplierType.manufacturer:
      return SupplierProfileColors.brandGold;
    case SupplierType.wholesaler:
      return SupplierProfileColors.info;
    case SupplierType.retailer:
      return SupplierProfileColors.success;
    case SupplierType.individual:
      return SupplierProfileColors.violet;
  }
}

String _valueOrNa(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? SupplierProfileStrings.lblNa : trimmed;
}

String _money(double value) => 'Rs ${value.toStringAsFixed(2)}';

String _weight(double value) => value.toStringAsFixed(3);

String _fileName(String path) {
  final normalized = path.replaceAll('\\', '/');
  final index = normalized.lastIndexOf('/');
  return index == -1 ? normalized : normalized.substring(index + 1);
}
