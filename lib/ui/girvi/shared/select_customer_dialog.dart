// =============================================================================
// FILE        : select_customer_dialog.dart
// MODULE      : Girvi / Pawn
// LAYER       : UI / Shared Dialog
// DESCRIPTION : Bottom-sheet dialog to search and select a customer.
//               Queries the Customers table, supports live search.
// =============================================================================

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<void> _openQuickAddCustomer() async {
    final created = await showDialog<Customer>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _QuickAddCustomerDialog(
        db: widget.db,
        initialName: _suggestedName,
        initialMobile: _suggestedMobile,
      ),
    );
    if (created == null || !mounted) return;
    widget.onSelected(created);
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
                  onPressed: _openQuickAddCustomer,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                  label: const Text('Add New'),
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
                            onAdd: _openQuickAddCustomer,
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

class _QuickAddCustomerDialog extends StatefulWidget {
  final AppDatabase db;
  final String initialName;
  final String initialMobile;

  const _QuickAddCustomerDialog({
    required this.db,
    required this.initialName,
    required this.initialMobile,
  });

  @override
  State<_QuickAddCustomerDialog> createState() =>
      _QuickAddCustomerDialogState();
}

class _QuickAddCustomerDialogState extends State<_QuickAddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _cityCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _mobileCtrl = TextEditingController(text: widget.initialMobile);
    _cityCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final name = _nameCtrl.text.trim();
    final mobile = _mobileCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final city = _cityCtrl.text.trim();

    try {
      final existing = await (widget.db.select(widget.db.customers)
            ..where((t) => t.mobile.equals(mobile))
            ..limit(1))
          .getSingleOrNull();
      if (existing != null) {
        if (!mounted) return;
        Navigator.of(context).pop(existing);
        return;
      }

      final parts = name.split(RegExp(r'\s+'));
      final firstName = parts.first;
      final lastName = parts.length > 1 ? parts.skip(1).join(' ') : '';

      final id = await widget.db.into(widget.db.customers).insert(
            CustomersCompanion.insert(
              name: name,
              mobile: mobile,
              city: drift.Value(city.isEmpty ? null : city),
              type: const drift.Value('Regular'),
              entityType: const drift.Value('Individual'),
              firstName: drift.Value(firstName),
              lastName: drift.Value(lastName.isEmpty ? null : lastName),
              whatsapp: drift.Value(mobile),
              customerTier: const drift.Value('Regular'),
              notes: const drift.Value('Created from New Girvi loan entry.'),
            ),
          );

      final created = await (widget.db.select(widget.db.customers)
            ..where((t) => t.id.equals(id))
            ..limit(1))
          .getSingle();

      if (!mounted) return;
      Navigator.of(context).pop(created);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Customer profile could not be created. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 430,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: GirviColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GirviColors.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: GirviColors.shadowMedium,
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: GirviColors.brandGoldLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: GirviColors.brandGold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Customer',
                          style: GoogleFonts.manrope(
                            color: GirviColors.textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Create the customer profile before the Girvi loan.',
                          style: GirviStyles.caption.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: GirviColors.textMuted,
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _QuickAddField(
                controller: _nameCtrl,
                label: 'Customer Name',
                hint: 'Enter customer full name',
                icon: GirviIcons.customer,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 2) return 'Enter customer name';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _QuickAddField(
                controller: _mobileCtrl,
                label: 'Mobile Number',
                hint: 'Enter 10 digit mobile number',
                icon: Icons.call_rounded,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  final mobile =
                      (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                  if (mobile.length != 10) {
                    return 'Enter valid 10 digit mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _QuickAddField(
                controller: _cityCtrl,
                label: 'City / Area',
                hint: 'Optional city or area',
                icon: Icons.location_on_outlined,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: GoogleFonts.inter(
                    color: GirviColors.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: GirviColors.shellBg,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline_rounded,
                          size: 18),
                  label: Text(_saving ? 'Creating Profile' : 'Create Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GirviColors.brandGold,
                    foregroundColor: GirviColors.shellBg,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAddField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _QuickAddField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GirviStyles.fieldInput,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: GirviColors.brandGold, size: 18),
        filled: true,
        fillColor: GirviColors.inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: GirviColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: GirviColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: GirviColors.brandGold, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: GirviColors.danger),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      ),
    );
  }
}
