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
import '../../customer/add_customer/add_customer_screen.dart';

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

  String get _query => _searchCtrl.text.trim();

  String get _digitsFromQuery => _query.replaceAll(RegExp(r'[^0-9]'), '');

  String get _suggestedName {
    final text = _query.replaceAll(RegExp(r'[0-9]'), '').trim();
    return text.length >= 2 ? text : '';
  }

  String get _suggestedMobile {
    final digits = _digitsFromQuery;
    if (digits.length >= 10) return digits.substring(digits.length - 10);
    return digits;
  }

  Future<void> _openAddCustomerScreen() async {
    final lastCustomerId = _all.fold<int>(
        0, (maxId, customer) => customer.id > maxId ? customer.id : maxId);
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (addCustomerContext) => AddCustomerScreen(
          initialName: _suggestedName,
          initialMobile: _suggestedMobile,
          onBack: () => Navigator.of(addCustomerContext).pop(false),
          onSaved: () => Navigator.of(addCustomerContext).pop(true),
        ),
      ),
    );
    if (created != true || !mounted) return;

    final customers = await (widget.db.select(widget.db.customers)
          ..orderBy([(c) => drift.OrderingTerm.asc(c.name)]))
        .get();
    if (!mounted) return;

    final newlyCreated = customers
        .where((customer) => customer.id > lastCustomerId)
        .toList()
      ..sort((a, b) => b.id.compareTo(a.id));

    setState(() {
      _all = customers;
      _filtered = customers;
      _loading = false;
    });

    if (newlyCreated.isNotEmpty) {
      widget.onSelected(newlyCreated.first);
    }
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
                TextButton.icon(
                  onPressed: _openAddCustomerScreen,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                  label: const Text('Add New Customer'),
                  style: TextButton.styleFrom(
                    foregroundColor: GirviColors.brandGold,
                    textStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                          child: _NoCustomerFoundCard(
                            query: _query,
                            onAdd: _openAddCustomerScreen,
                          ),
                        )
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

class _NoCustomerFoundCard extends StatelessWidget {
  final String query;
  final VoidCallback onAdd;

  const _NoCustomerFoundCard({
    required this.query,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: GirviColors.bodyBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GirviColors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: GirviColors.brandGoldLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: GirviColors.brandGold.withValues(alpha: 0.25),
                ),
              ),
              child: const Icon(
                Icons.person_search_rounded,
                color: GirviColors.brandGold,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Customer Not Found',
              style: GoogleFonts.manrope(
                color: GirviColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasQuery
                  ? 'No registered profile matched "$query". Create the customer profile before starting this Girvi loan.'
                  : 'Search by name or mobile, or create a new customer profile.',
              textAlign: TextAlign.center,
              style: GirviStyles.caption.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 42,
              child: ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
                label: const Text('Add New Customer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GirviColors.brandGold,
                  foregroundColor: GirviColors.shellBg,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
