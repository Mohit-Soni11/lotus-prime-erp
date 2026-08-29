import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/data/customer_metal_purchase_ledger_drift_repository.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_voucher_detail.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/repositories/customer_metal_purchase_ledger_repository.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/utils/customer_metal_purchase_formatters.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_empty_state.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_ledger_app_bar.dart';
import 'package:lotus_erp/theme/purchase/purchase_entry/purchase_entry_theme.dart';

class CustomerMetalPurchaseVoucherDetailScreen extends StatefulWidget {
  final int voucherId;
  final VoidCallback? onBack;
  final CustomerMetalPurchaseLedgerRepository? repository;

  const CustomerMetalPurchaseVoucherDetailScreen({
    super.key,
    required this.voucherId,
    this.onBack,
    this.repository,
  });

  @override
  State<CustomerMetalPurchaseVoucherDetailScreen> createState() =>
      _CustomerMetalPurchaseVoucherDetailScreenState();
}

class _CustomerMetalPurchaseVoucherDetailScreenState
    extends State<CustomerMetalPurchaseVoucherDetailScreen> {
  late final AppDatabase? _ownedDatabase;
  late final CustomerMetalPurchaseLedgerRepository _repository;
  late final Future<CustomerMetalPurchaseVoucherDetail?> _voucherFuture;

  @override
  void initState() {
    super.initState();
    _ownedDatabase = widget.repository == null ? AppDatabase() : null;
    _repository = widget.repository ??
        DriftCustomerMetalPurchaseLedgerRepository(_ownedDatabase!);
    _voucherFuture = _repository.fetchVoucherDetail(widget.voucherId);
  }

  @override
  void dispose() {
    _ownedDatabase?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PurchaseEntryColors.bodyBg,
      appBar: CustomerMetalPurchaseLedgerAppBar(
        title: 'Customer Purchase Voucher',
        onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<CustomerMetalPurchaseVoucherDetail?>(
          future: _voucherFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(
                  color: PurchaseEntryColors.brandGold,
                ),
              );
            }

            if (snapshot.hasError) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: CustomerMetalPurchaseEmptyState(
                  message: 'Unable to load this customer purchase voucher.',
                ),
              );
            }

            final voucher = snapshot.data;
            if (voucher == null) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: CustomerMetalPurchaseEmptyState(
                  message: 'Customer purchase voucher was not found.',
                ),
              );
            }

            return _VoucherDetailView(voucher: voucher);
          },
        ),
      ),
    );
  }
}

class _VoucherDetailView extends StatelessWidget {
  final CustomerMetalPurchaseVoucherDetail voucher;

  const _VoucherDetailView({required this.voucher});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 980;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _VoucherHeader(voucher: voucher),
                  const SizedBox(height: 14),
                  _MetricGrid(voucher: voucher, isCompact: isCompact),
                  const SizedBox(height: 14),
                  if (isCompact)
                    Column(
                      children: [
                        _SellerPanel(voucher: voucher),
                        const SizedBox(height: 14),
                        _PaymentPanel(voucher: voucher),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _SellerPanel(voucher: voucher)),
                        const SizedBox(width: 14),
                        Expanded(child: _PaymentPanel(voucher: voucher)),
                      ],
                    ),
                  const SizedBox(height: 14),
                  _ItemLinesTable(lines: voucher.lines),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VoucherHeader extends StatelessWidget {
  final CustomerMetalPurchaseVoucherDetail voucher;

  const _VoucherHeader({required this.voucher});

  @override
  Widget build(BuildContext context) {
    final statusColor = voucher.hasPendingPayout
        ? PurchaseEntryColors.warning
        : PurchaseEntryColors.success;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Wrap(
        spacing: 18,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.22),
              ),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: PurchaseEntryColors.purchaseAccent,
              size: 26,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 260, maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voucher.voucherNo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _titleStyle(24),
                ),
                const SizedBox(height: 6),
                Text(
                  '${CustomerMetalPurchaseFormatters.date(voucher.createdAt)} | Sequence ${voucher.sequenceNo}',
                  style: _mutedStyle(),
                ),
              ],
            ),
          ),
          _StatusPill(
            label: voucher.resolvedPaymentStatus,
            color: statusColor,
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final CustomerMetalPurchaseVoucherDetail voucher;
  final bool isCompact;

  const _MetricGrid({
    required this.voucher,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final columns = isCompact ? 2 : 4;
    final metrics = [
      _MetricData(
        'Grand Total',
        CustomerMetalPurchaseFormatters.amount(voucher.grandTotal),
        Icons.payments_rounded,
      ),
      _MetricData(
        'Paid',
        CustomerMetalPurchaseFormatters.amount(voucher.totalPaid),
        Icons.account_balance_wallet_rounded,
      ),
      _MetricData(
        'Pending',
        CustomerMetalPurchaseFormatters.amount(voucher.balanceDue),
        Icons.pending_actions_rounded,
      ),
      _MetricData(
        'Fine Weight',
        CustomerMetalPurchaseFormatters.weight(voucher.fineWeight),
        Icons.scale_rounded,
      ),
    ];

    return GridView.builder(
      itemCount: metrics.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisExtent: 116,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        return _MetricTile(data: metrics[index]);
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final _MetricData data;

  const _MetricTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(data.icon, size: 18, color: PurchaseEntryColors.shellMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _labelStyle(),
                ),
              ),
            ],
          ),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _titleStyle(20),
          ),
        ],
      ),
    );
  }
}

class _SellerPanel extends StatelessWidget {
  final CustomerMetalPurchaseVoucherDetail voucher;

  const _SellerPanel({required this.voucher});

  @override
  Widget build(BuildContext context) {
    return _InfoPanel(
      title: 'Seller Details',
      icon: Icons.person_search_rounded,
      action: voucher.hasSellerPhoto
          ? IconButton(
              tooltip: 'View seller photo',
              onPressed: () => _showSellerPhoto(context, voucher),
              icon: const Icon(Icons.image_search_rounded),
            )
          : null,
      children: [
        _InfoRow(label: 'Seller', value: voucher.partyName),
        _InfoRow(label: 'Mobile', value: _optional(voucher.mobile)),
        _InfoRow(label: 'City', value: _optional(voucher.city)),
        _InfoRow(label: 'PAN', value: _optional(voucher.panNumber)),
      ],
    );
  }

  void _showSellerPhoto(
    BuildContext context,
    CustomerMetalPurchaseVoucherDetail voucher,
  ) {
    final path = voucher.sellerPhotoPath?.trim();
    if (path == null || path.isEmpty || !File(path).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller photo file was not found.')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: PurchaseEntryColors.bodyPanel,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Seller Photo', style: _titleStyle(18)),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: PurchaseEntryColors.bodyBorder),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(path), fit: BoxFit.contain),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PaymentPanel extends StatelessWidget {
  final CustomerMetalPurchaseVoucherDetail voucher;

  const _PaymentPanel({required this.voucher});

  @override
  Widget build(BuildContext context) {
    return _InfoPanel(
      title: 'Payment Breakdown',
      icon: Icons.account_balance_rounded,
      children: [
        _InfoRow(
          label: 'Cash',
          value: CustomerMetalPurchaseFormatters.amount(voucher.cashPaid),
        ),
        _InfoRow(
          label: 'UPI',
          value: CustomerMetalPurchaseFormatters.amount(voucher.upiPaid),
        ),
        _InfoRow(
          label: 'Bank',
          value: CustomerMetalPurchaseFormatters.amount(voucher.bankPaid),
        ),
        _InfoRow(
          label: 'Card',
          value: CustomerMetalPurchaseFormatters.amount(voucher.cardPaid),
        ),
        _InfoRow(
          label: 'Promise Date',
          value: voucher.promiseDate == null
              ? 'Not Applicable'
              : CustomerMetalPurchaseFormatters.date(voucher.promiseDate!),
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? action;
  final List<Widget> children;

  const _InfoPanel({
    required this.title,
    required this.icon,
    required this.children,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: PurchaseEntryColors.purchaseAccent),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: _titleStyle(17))),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(label, style: _labelStyle()),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: _valueStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemLinesTable extends StatelessWidget {
  final List<CustomerMetalPurchaseVoucherLine> lines;

  const _ItemLinesTable({required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Icon(
                  Icons.view_list_rounded,
                  size: 19,
                  color: PurchaseEntryColors.purchaseAccent,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text('Item Lines', style: _titleStyle(17))),
                _StatusPill(
                  label: '${lines.length} item(s)',
                  color: PurchaseEntryColors.purchaseAccent,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: PurchaseEntryColors.bodyBorder),
          if (lines.isEmpty)
            const Padding(
              padding: EdgeInsets.all(18),
              child: CustomerMetalPurchaseEmptyState(
                message: 'No item lines are recorded for this voucher.',
              ),
            )
          else
            Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    PurchaseEntryColors.cardHoverBg,
                  ),
                  headingTextStyle: PurchaseEntryStyles.tableColumnHeader,
                  dataTextStyle: _tableTextStyle(),
                  columnSpacing: 28,
                  horizontalMargin: 18,
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('Metal')),
                    DataColumn(label: Text('Description')),
                    DataColumn(label: Text('Gross')),
                    DataColumn(label: Text('Less')),
                    DataColumn(label: Text('Net')),
                    DataColumn(label: Text('Purity')),
                    DataColumn(label: Text('Fine')),
                    DataColumn(label: Text('Rate')),
                    DataColumn(label: Text('Qty')),
                    DataColumn(label: Text('Amount')),
                  ],
                  rows: [
                    for (final line in lines)
                      DataRow(
                        cells: [
                          DataCell(Text('${line.lineNo}')),
                          DataCell(Text(line.metalType)),
                          DataCell(
                            SizedBox(
                              width: 220,
                              child: Text(
                                line.itemDescription,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              CustomerMetalPurchaseFormatters.weight(
                                line.grossWeight,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              CustomerMetalPurchaseFormatters.weight(
                                line.lessWeight,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              CustomerMetalPurchaseFormatters.weight(
                                line.netWeight,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              CustomerMetalPurchaseFormatters.purity(
                                line.purity,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              CustomerMetalPurchaseFormatters.weight(
                                line.fineWeight,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(CustomerMetalPurchaseFormatters.rate(
                                line.rate)),
                          ),
                          DataCell(Text('${line.quantity}')),
                          DataCell(
                            Text(
                              CustomerMetalPurchaseFormatters.amount(
                                line.lineAmount,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _MetricData {
  final String label;
  final String value;
  final IconData icon;

  const _MetricData(this.label, this.value, this.icon);
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: PurchaseEntryColors.bodyPanel,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: PurchaseEntryColors.bodyBorder),
    boxShadow: const [
      BoxShadow(
        color: PurchaseEntryColors.shadowLight,
        blurRadius: 14,
        offset: Offset(0, 6),
      ),
    ],
  );
}

String _optional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? 'Not Recorded' : normalized;
}

TextStyle _titleStyle(double size) {
  return GoogleFonts.inter(
    fontSize: size,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
    color: PurchaseEntryColors.textMain,
  );
}

TextStyle _labelStyle() {
  return GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
    color: PurchaseEntryColors.shellMuted,
  );
}

TextStyle _valueStyle() {
  return GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
    color: PurchaseEntryColors.textMain,
  );
}

TextStyle _mutedStyle() {
  return GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    color: PurchaseEntryColors.textMuted.withValues(alpha: 0.64),
  );
}

TextStyle _tableTextStyle() {
  return GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    color: PurchaseEntryColors.textMain,
  );
}
