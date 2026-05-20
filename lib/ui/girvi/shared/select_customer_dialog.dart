// =============================================================================
// FILE        : select_customer_dialog.dart
// MODULE      : Girvi / Pawn
// LAYER       : UI / Shared Dialog
// DESCRIPTION : Bottom-sheet dialog to search and select a customer.
//               Queries the Customers table, supports live search.
// =============================================================================

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../database/db/app_database.dart';
import '../../../theme/girvi/girvi_theme.dart';

class SelectCustomerDialog extends StatefulWidget {
  final AppDatabase db;
  final void Function(Customer) onSelected;

  const SelectCustomerDialog({
    super.key,
    required this.db,
    required this.onSelected,
  });

  @override
  State<SelectCustomerDialog> createState() => _SelectCustomerDialogState();
}

class _SelectCustomerDialogState extends State<SelectCustomerDialog> {
  final _searchCtrl = TextEditingController();
  List<Customer> _all = [];
  List<Customer> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    final list = await (widget.db.select(widget.db.customers)
          ..orderBy([(c) => drift.OrderingTerm.asc(c.name)]))
        .get();
    if (mounted) {
      setState(() {
        _all = list;
        _filtered = list;
        _loading = false;
      });
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all
              .where((c) =>
                  c.name.toLowerCase().contains(q) ||
                  c.mobile.contains(q) ||
                  (c.city?.toLowerCase().contains(q) ?? false))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: GirviColors.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: GirviColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(children: [
                const Icon(GirviIcons.customer,
                    color: GirviColors.accentCustomer),
                const SizedBox(width: 10),
                Text('Select Customer',
                    style: GoogleFonts.manrope(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: GirviColors.textDark)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded,
                      color: GirviColors.textMuted),
                ),
              ]),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                decoration: GirviStyles.inputNormal,
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  style: GirviStyles.fieldInput,
                  decoration: InputDecoration(
                    hintText: 'Search by name or mobile...',
                    hintStyle: GirviStyles.fieldHint,
                    prefixIcon: const Icon(GirviIcons.search,
                        color: GirviColors.brandGold, size: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: GirviColors.divider),
            // List
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: GirviColors.brandGold))
                  : _filtered.isEmpty
                      ? Center(
                          child: Text('No customers found',
                              style:
                                  GirviStyles.caption.copyWith(fontSize: 14)))
                      : ListView.separated(
                          controller: scrollCtrl,
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const Divider(
                              height: 1, color: GirviColors.divider),
                          itemBuilder: (_, i) {
                            final c = _filtered[i];
                            return ListTile(
                              onTap: () => widget.onSelected(c),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: GirviColors.brandGoldLight,
                                child: Text(c.name[0].toUpperCase(),
                                    style: GoogleFonts.manrope(
                                      color: GirviColors.brandDeep,
                                      fontWeight: FontWeight.w800,
                                    )),
                              ),
                              title: Text(c.name,
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: GirviColors.textDark)),
                              subtitle:
                                  Text(c.mobile, style: GirviStyles.caption),
                              trailing: c.city != null
                                  ? Text(c.city!,
                                      style: GirviStyles.caption
                                          .copyWith(fontSize: 11))
                                  : null,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
