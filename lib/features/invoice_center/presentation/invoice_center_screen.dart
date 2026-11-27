import 'package:flutter/material.dart';
import 'package:lotus_erp/database/db/app_database.dart';

import '../application/invoice_center_controller.dart';
import '../application/invoice_center_document_service.dart';
import '../data/invoice_center_repository.dart';
import 'invoice_center_actions.dart';
import 'invoice_center_app_bar.dart';
import 'invoice_center_style.dart';
import 'widgets/invoice_center_filters.dart';
import 'widgets/invoice_center_footer.dart';
import 'widgets/invoice_center_overview.dart';
import 'widgets/invoice_center_table.dart';

class InvoiceCenterScreen extends StatefulWidget {
  const InvoiceCenterScreen({
    super.key,
    required this.onBack,
    this.controller,
    this.documentService,
  });

  final VoidCallback onBack;
  final InvoiceCenterController? controller;
  final InvoiceCenterDocumentService? documentService;

  @override
  State<InvoiceCenterScreen> createState() => _InvoiceCenterScreenState();
}

class _InvoiceCenterScreenState extends State<InvoiceCenterScreen>
    with WidgetsBindingObserver {
  late final InvoiceCenterController _controller;
  late final InvoiceCenterActions _actions;
  late final bool _ownsController;
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsController = widget.controller == null;
    _controller = widget.controller ??
        InvoiceCenterController(
          repository: DriftInvoiceCenterRepository(AppDatabase()),
          pageSize: 8,
        );
    _actions = InvoiceCenterActions(
      controller: _controller,
      documents: widget.documentService ?? const InvoiceCenterDocumentService(),
    );
    _search.text = _controller.search;
    _controller.load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _controller.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _search.dispose();
    _actions.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) widget.onBack();
        },
        child: Scaffold(
          backgroundColor: InvoiceCenterStyle.background,
          appBar: InvoiceCenterAppBar(onBack: widget.onBack),
          body: AnimatedBuilder(
            animation: Listenable.merge([_controller, _actions]),
            builder: (context, _) {
              final snapshot = _controller.snapshot;
              return Scrollbar(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InvoiceCenterOverview(
                        summary: snapshot?.summary,
                        selected: _controller.tab,
                        onSelect: _controller.selectTab,
                      ),
                      const SizedBox(height: 20),
                      InvoiceCenterTabs(
                        selected: _controller.tab,
                        onSelect: _controller.selectTab,
                      ),
                      const SizedBox(height: 18),
                      InvoiceCenterFilters(
                        searchController: _search,
                        month: _controller.month,
                        usesMonth: _controller.usesMonth,
                        metals: snapshot?.metals ?? const [],
                        selectedMetal: _controller.metal,
                        selectedStatus: _controller.status,
                        tab: _controller.tab,
                        onSearch: _controller.setSearch,
                        onMonthChange: _controller.changeMonth,
                        onMetalChange: _controller.setMetal,
                        onStatusChange: _controller.setStatus,
                        onMoreFilters: () =>
                            _actions.showAmountFilters(context),
                        onRefresh: _controller.load,
                        hasAmountFilter: _controller.minAmount != null ||
                            _controller.maxAmount != null,
                      ),
                      const SizedBox(height: 18),
                      if (_controller.isLoading)
                        const LinearProgressIndicator(
                          minHeight: 2,
                          color: InvoiceCenterStyle.gold,
                        ),
                      if (_controller.error != null) ...[
                        _errorPanel(_controller.error!),
                        const SizedBox(height: 16),
                      ],
                      InvoiceCenterTable(
                        rows: snapshot?.rows ?? const [],
                        page: _controller.page,
                        pageSize: _controller.pageSize,
                        onView: (row) => _actions.viewOriginal(context, row),
                        onPrint: (row) => _actions.printOriginal(context, row),
                        onMore: (row, action) =>
                            _actions.moreAction(context, row, action),
                      ),
                      const SizedBox(height: 16),
                      InvoiceCenterFooter(
                        page: _controller.page,
                        pageSize: _controller.pageSize,
                        totalRows: snapshot?.totalRows ?? 0,
                        onPage: _controller.setPage,
                        onExport: () => _actions.export(context),
                        exporting: _actions.exporting,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );

  Widget _errorPanel(String message) => Container(
        padding: const EdgeInsets.all(14),
        decoration: InvoiceCenterStyle.panel(),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
            TextButton(onPressed: _controller.load, child: const Text('Retry')),
          ],
        ),
      );
}
