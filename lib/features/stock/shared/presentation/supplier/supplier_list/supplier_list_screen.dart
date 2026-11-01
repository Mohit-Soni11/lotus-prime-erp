import 'package:flutter/material.dart';
import 'package:lotus_erp/features/stock/shared/application/supplier_list_logic.dart';
import 'package:lotus_erp/theme/stock/supplier/supplier_list/supplier_list_theme.dart';
import 'package:lotus_erp/ui/shared/system_status_badge.dart';

import 'supplier_list_app_bar.dart';
import 'supplier_list_card.dart';
import 'supplier_list_toolbar.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({
    super.key,
    this.onBack,
    this.onAddSupplier,
    this.onSupplierTap,
  });

  final VoidCallback? onBack;
  final VoidCallback? onAddSupplier;
  final ValueChanged<int>? onSupplierTap;

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen>
    with WidgetsBindingObserver {
  late final SupplierListLogic _logic;
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _logic = SupplierListLogic();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _logic.refresh(showLoading: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logic.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: SupplierListColors.bodyBg,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(SupplierListStyles.appBarHeight),
          child: ListenableBuilder(
            listenable: _logic,
            builder: (context, _) => SupplierListAppBar(
              onBack: widget.onBack ?? () => Navigator.maybePop(context),
              status: _logic.errorMessage != null
                  ? SystemStatus.unavailable
                  : _logic.state == SupplierListState.loading
                      ? SystemStatus.loading
                      : SystemStatus.online,
            ),
          ),
        ),
        body: ListenableBuilder(
          listenable: _logic,
          builder: (context, _) => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _header()),
              SliverToBoxAdapter(child: _totalCard()),
              SliverToBoxAdapter(
                child: SupplierListToolbar(logic: _logic, controller: _search),
              ),
              if (_logic.state != SupplierListState.loading)
                SliverToBoxAdapter(child: _resultHeader()),
              _body(),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: widget.onAddSupplier,
          backgroundColor: SupplierListColors.brandGold,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Add Supplier',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      );

  Widget _header() => const Padding(
        padding: EdgeInsets.fromLTRB(22, 20, 22, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Supplier List',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black)),
          SizedBox(height: 5),
          Text('Supplier accounts and contact details in one place.',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black)),
        ]),
      );

  Widget _totalCard() => Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
        child: Container(
          height: 132,
          padding: const EdgeInsets.all(18),
          decoration: SupplierListStyles.statsCardDecoration,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: SupplierListColors.brandGold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: SupplierListColors.brandGold, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Total Suppliers',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black)),
            ]),
            const Spacer(),
            Text(
              _logic.state == SupplierListState.loading
                  ? '—'
                  : '${_logic.totalSuppliers}',
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.black),
            ),
          ]),
        ),
      );

  Widget _resultHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 10),
        child: Text(
          '${_logic.suppliers.length} ${_logic.suppliers.length == 1 ? 'supplier' : 'suppliers'} shown',
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black),
        ),
      );

  Widget _body() {
    switch (_logic.state) {
      case SupplierListState.loading:
        return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        );
      case SupplierListState.error:
        return SliverFillRemaining(
          child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_logic.errorMessage ?? 'Suppliers could not be loaded.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: _logic.refresh, child: const Text('Retry')),
          ])),
        );
      case SupplierListState.empty:
        return SliverFillRemaining(
          child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.storefront_rounded,
                size: 48, color: SupplierListColors.brandGold),
            const SizedBox(height: 12),
            Text(
                _logic.isSearching
                    ? 'No matching suppliers'
                    : 'No suppliers yet',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black)),
            if (!_logic.isSearching) ...[
              const SizedBox(height: 12),
              FilledButton(
                  onPressed: widget.onAddSupplier,
                  child: const Text('Add Supplier')),
            ],
          ])),
        );
      case SupplierListState.loaded:
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 100),
          sliver: SliverList.builder(
            itemCount: _logic.suppliers.length,
            itemBuilder: (context, index) {
              final supplier = _logic.suppliers[index];
              return SupplierListCard(
                key: ValueKey(supplier.id),
                supplier: supplier,
                onTap: () => widget.onSupplierTap?.call(supplier.id),
              );
            },
          ),
        );
    }
  }
}
