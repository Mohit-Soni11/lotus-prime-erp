import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/stock_summary_controller.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/market_refill/market_refill_models.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_summary/stock_summary_models.dart';
import 'package:lotus_erp/features/stock/shared/presentation/add_stock/stock_metal_ui.dart';
import 'package:lotus_erp/features/stock/shared/presentation/inventory/metal_hub/inventory_metal_summary_card.dart';
import 'package:lotus_erp/features/stock/shared/presentation/market_refill_report/market_refill_report_screen.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

part 'app_bar/stock_summary_app_bar.dart';
part 'body/stock_summary_body.dart';
part 'widgets/stock_summary_market_refill_panel.dart';
part 'widgets/stock_summary_recent_movement_panel.dart';
part 'widgets/stock_summary_shared_widgets.dart';
part 'widgets/stock_summary_silver_item_type_panel.dart';
part 'widgets/stock_summary_widgets.dart';

class StockSummaryScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const StockSummaryScreen({super.key, this.onBack});

  @override
  State<StockSummaryScreen> createState() => _StockSummaryScreenState();
}

class _StockSummaryScreenState extends State<StockSummaryScreen> {
  late final StockSummaryController _controller;
  final _bodyKey = GlobalKey<_StockSummaryBodyState>();

  @override
  void initState() {
    super.initState();
    _controller = StockSummaryController(AppDatabase());
    _controller.addListener(_rebuild);
    _controller.load();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  bool _handleInternalBack() {
    return _bodyKey.currentState?.handleInternalBack() ?? false;
  }

  void _handleBack() {
    if (_handleInternalBack()) return;
    final fallbackBack =
        widget.onBack ?? () => Navigator.of(context).maybePop();
    fallbackBack();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: InvColors.bodyBg,
        appBar: _StockSummaryAppBar(
          onBack: _handleBack,
          onRefresh: _controller.load,
        ),
        body: _StockSummaryBody(key: _bodyKey, controller: _controller),
      ),
    );
  }
}
