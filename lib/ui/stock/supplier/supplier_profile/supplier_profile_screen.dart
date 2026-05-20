import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../database/db/app_database.dart';
import '../../../../models/stock/supplier_model/supplier_model.dart';
import '../../../../repositories/supplier/supplier_repository.dart';
import '../../../../theme/stock/supplier/supplier_list/supplier_list_theme.dart';

class SupplierProfileScreen extends StatefulWidget {
  final int supplierId;

  const SupplierProfileScreen({super.key, required this.supplierId});

  @override
  State<SupplierProfileScreen> createState() => _SupplierProfileScreenState();
}

class _SupplierProfileScreenState extends State<SupplierProfileScreen> {
  late final SupplierRepository _repo;
  late Future<_SupplierProfileData> _future;

  @override
  void initState() {
    super.initState();
    _repo = SupplierRepository(AppDatabase());
    _future = _load();
  }

  Future<_SupplierProfileData> _load() async {
    final supplier = await _repo.getById(widget.supplierId);
    final ledger = await _repo.getLedgerSnapshot(widget.supplierId);
    return _SupplierProfileData(supplier: supplier, ledger: ledger);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SupplierListColors.bodyBg,
      appBar: AppBar(
        backgroundColor: SupplierListColors.bodyBg,
        foregroundColor: SupplierListColors.bodyTextMain,
        elevation: 0,
        title: const Text('Supplier Profile'),
      ),
      body: FutureBuilder<_SupplierProfileData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: SupplierListColors.brandGold,
              ),
            );
          }

          final data = snapshot.data;
          if (data == null || data.supplier == null) {
            return const Center(child: Text('Supplier profile not found'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _load());
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              children: [
                _SupplierHeaderCard(supplier: data.supplier!),
                const SizedBox(height: 14),
                _LedgerSummaryCard(ledger: data.ledger),
                const SizedBox(height: 14),
                Text(
                  'Purchase History',
                  style: SupplierListStyles.statsValue.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 10),
                if (data.ledger.history.isEmpty)
                  _emptyHistory()
                else
                  for (final item in data.ledger.history) ...[
                    _PurchaseHistoryCard(item: item),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _emptyHistory() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: SupplierListStyles.cardDecoration,
      child: const Text('No purchase voucher linked with this supplier yet.'),
    );
  }
}

class _SupplierHeaderCard extends StatelessWidget {
  final SupplierModel supplier;

  const _SupplierHeaderCard({required this.supplier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: SupplierListStyles.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SupplierListColors.brandGold,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              supplier.avatarInitial,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(supplier.businessName,
                    style: SupplierListStyles.supplierName),
                const SizedBox(height: 5),
                Text(
                  [
                    supplier.mobile,
                    if ((supplier.contactPersonName ?? '').isNotEmpty)
                      supplier.contactPersonName!,
                    if ((supplier.gstNumber ?? '').isNotEmpty)
                      'GST ${supplier.gstNumber}',
                  ].join('  |  '),
                  style: SupplierListStyles.supplierDetail,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerSummaryCard extends StatelessWidget {
  final SupplierLedgerSnapshot ledger;

  const _LedgerSummaryCard({required this.ledger});

  @override
  Widget build(BuildContext context) {
    final dueColor = ledger.hasOutstandingDue
        ? const Color(0xFFD65A3F)
        : SupplierListColors.success;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: SupplierListStyles.cardDecoration,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _metric('Opening', _money(ledger.openingBalance),
              SupplierListColors.bodyTextMuted),
          _metric('Voucher Due', _money(ledger.voucherDueTotal),
              const Color(0xFFD65A3F)),
          _metric('Adjusted', _money(ledger.oldDueAdjustedTotal),
              SupplierListColors.success),
          _metric('Current Baki', _money(ledger.outstandingDue), dueColor),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: SupplierListStyles.supplierDetail.copyWith(color: color)),
          const SizedBox(height: 6),
          Text(value,
              style: SupplierListStyles.statsValue.copyWith(
                  fontSize: 18, color: SupplierListColors.bodyTextMain)),
        ],
      ),
    );
  }
}

class _PurchaseHistoryCard extends StatelessWidget {
  final SupplierPurchaseHistoryItem item;

  const _PurchaseHistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd MMM yyyy').format(item.createdAt);
    final photoPath = item.billPhotoPath;
    final hasPhoto = photoPath != null &&
        photoPath.isNotEmpty &&
        File(photoPath).existsSync();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: SupplierListStyles.cardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: SupplierListColors.bodyBorder,
              borderRadius: BorderRadius.circular(12),
            ),
            child: hasPhoto
                ? Image.file(File(photoPath), fit: BoxFit.cover)
                : const Icon(Icons.receipt_long_rounded,
                    color: SupplierListColors.bodyTextMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.voucherNo, style: SupplierListStyles.supplierName),
                const SizedBox(height: 4),
                Text(
                  [
                    date,
                    '${item.stockEntryCount} stock item(s)',
                    if ((item.supplierInvoiceNo ?? '').isNotEmpty)
                      'Supplier bill ${item.supplierInvoiceNo}',
                  ].join('  |  '),
                  style: SupplierListStyles.supplierDetail,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip('Bill ${_money(item.grandTotal)}',
                        SupplierListColors.brandGold),
                    _chip('Paid ${_money(item.totalPaid)}',
                        SupplierListColors.success),
                    _chip(
                        'Baki ${_money(item.balanceDue)}',
                        item.balanceDue > 0
                            ? const Color(0xFFD65A3F)
                            : SupplierListColors.success),
                    if (item.oldDueAdjustedAmount > 0)
                      _chip(
                          'Old due adjusted ${_money(item.oldDueAdjustedAmount)}',
                          SupplierListColors.success),
                    if (item.metalLineCount > 0)
                      _chip('${item.metalLineCount} metal box(es)',
                          const Color(0xFF64748B)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        text,
        style: SupplierListStyles.supplierDetail.copyWith(color: color),
      ),
    );
  }
}

class _SupplierProfileData {
  final SupplierModel? supplier;
  final SupplierLedgerSnapshot ledger;

  const _SupplierProfileData({required this.supplier, required this.ledger});
}

String _money(double value) => 'Rs ${value.toStringAsFixed(2)}';
