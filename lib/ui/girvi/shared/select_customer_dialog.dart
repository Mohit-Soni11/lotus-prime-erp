// =============================================================================
// FILE        : select_customer_dialog.dart
// MODULE      : Girvi / Pawn
// LAYER       : UI / Shared Dialog
// DESCRIPTION : Bottom-sheet dialog to search and select a customer.
//               Queries the Customers table, supports live search.
// =============================================================================

import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/logging/app_logger.dart';
import 'package:lotus_erp/database/db/app_database.dart';
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
  static const Duration _customerLoadTimeout = Duration(seconds: 8);

  final _searchCtrl = TextEditingController();
  final Set<Timer> _loadTimeoutTimers = <Timer>{};
  List<Customer> _all = [];
  List<Customer> _filtered = [];
  bool _loading = true;
  String? _loadError;

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
    for (final timer in _loadTimeoutTimers) {
      timer.cancel();
    }
    _loadTimeoutTimers.clear();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    if (mounted && !_loading) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }

    try {
      final list = await _fetchCustomers();
      if (!mounted) return;
      setState(() {
        _all = list;
        _filtered = _filterCustomers(list);
        _loading = false;
        _loadError = null;
      });
    } on TimeoutException catch (error, stackTrace) {
      AppLogger.debug(
        'SelectCustomerDialog customer load timed out',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _all = [];
        _filtered = [];
        _loading = false;
        _loadError =
            'Customer list is taking longer than expected. Check the database connection and retry.';
      });
    } catch (error, stackTrace) {
      AppLogger.debug(
        'SelectCustomerDialog customer load failed',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _all = [];
        _filtered = [];
        _loading = false;
        _loadError = 'Customer list could not be loaded. Please try again.';
      });
    }
  }

  Future<List<Customer>> _fetchCustomers() {
    final query = (widget.db.select(widget.db.customers)
          ..orderBy([(c) => drift.OrderingTerm.asc(c.name)]))
        .get();
    final completer = Completer<List<Customer>>();
    var completed = false;

    late final Timer timeoutTimer;
    void completeOnce(void Function() complete) {
      if (completed) return;
      completed = true;
      timeoutTimer.cancel();
      _loadTimeoutTimers.remove(timeoutTimer);
      complete();
    }

    timeoutTimer = Timer(_customerLoadTimeout, () {
      completeOnce(
        () => completer.completeError(
          TimeoutException(
            'Customer list load timed out.',
            _customerLoadTimeout,
          ),
        ),
      );
    });
    _loadTimeoutTimers.add(timeoutTimer);

    query.then(
      (customers) => completeOnce(() => completer.complete(customers)),
      onError: (Object error, StackTrace stackTrace) => completeOnce(
        () => completer.completeError(error, stackTrace),
      ),
    );
    return completer.future;
  }

  List<Customer> _filterCustomers(List<Customer> customers) {
    final q = _searchCtrl.text.toLowerCase().trim();
    return q.isEmpty
        ? customers
        : customers
            .where((c) =>
                c.name.toLowerCase().contains(q) ||
                c.mobile.contains(q) ||
                (c.city?.toLowerCase().contains(q) ?? false))
            .toList();
  }

  void _onSearch() {
    if (!mounted) return;
    setState(() {
      _filtered = _filterCustomers(_all);
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

    try {
      setState(() {
        _loading = true;
        _loadError = null;
      });
      final customers = await _fetchCustomers();
      if (!mounted) return;

      final newlyCreated = customers
          .where((customer) => customer.id > lastCustomerId)
          .toList()
        ..sort((a, b) => b.id.compareTo(a.id));

      setState(() {
        _all = customers;
        _filtered = _filterCustomers(customers);
        _loading = false;
      });

      if (newlyCreated.isNotEmpty) {
        widget.onSelected(newlyCreated.first);
      }
    } on TimeoutException catch (error, stackTrace) {
      AppLogger.debug(
        'SelectCustomerDialog customer refresh timed out',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError =
            'Customer list is taking longer than expected. Check the database connection and retry.';
      });
    } catch (error, stackTrace) {
      AppLogger.debug(
        'SelectCustomerDialog customer refresh failed',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Customer list could not be refreshed. Please try again.';
      });
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
                      fontSize: 12.5,
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
                  ? const Center(child: _CustomerLoadingCard())
                  : _loadError != null
                      ? Center(
                          child: _CustomerLoadErrorCard(
                            message: _loadError!,
                            onRetry: _loadCustomers,
                          ),
                        )
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
                                final initial = c.name.trim().isEmpty
                                    ? '?'
                                    : c.name.trim()[0].toUpperCase();
                                return ListTile(
                                  onTap: () => widget.onSelected(c),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 4),
                                  leading: CircleAvatar(
                                    backgroundColor: GirviColors.brandGoldLight,
                                    child: Text(initial,
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
                                  subtitle: Text(c.mobile,
                                      style: GirviStyles.caption),
                                  trailing: c.city != null
                                      ? Text(c.city!,
                                          style: GirviStyles.caption
                                              .copyWith(fontSize: 12.5))
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

class _CustomerLoadingCard extends StatelessWidget {
  const _CustomerLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: GirviColors.bodyBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GirviColors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                color: GirviColors.brandGold,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading Customers',
              style: GoogleFonts.manrope(
                color: GirviColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Please wait while the customer register is being prepared.',
              textAlign: TextAlign.center,
              style: GirviStyles.caption.copyWith(fontSize: 12.5),
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
              style: GirviStyles.caption.copyWith(fontSize: 12.5),
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
                    fontSize: 12.5,
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

class _CustomerLoadErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CustomerLoadErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: GirviColors.bodyBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GirviColors.danger.withValues(alpha: 0.22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: GirviColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: GirviColors.danger.withValues(alpha: 0.18),
                ),
              ),
              child: const Icon(
                Icons.sync_problem_rounded,
                color: GirviColors.danger,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Customer List Unavailable',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: GirviColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GirviStyles.caption.copyWith(fontSize: 12.5),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 42,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('Retry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: GirviColors.textDark,
                  side: BorderSide(
                    color: GirviColors.danger.withValues(alpha: 0.28),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 12.5,
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
