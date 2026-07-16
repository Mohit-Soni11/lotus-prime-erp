import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/stock_summary_controller.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_summary/stock_summary_models.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

part 'app_bar/stock_summary_app_bar.dart';
part 'body/stock_summary_body.dart';
part 'widgets/stock_summary_widgets.dart';

class StockSummaryScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const StockSummaryScreen({super.key, this.onBack});

  @override
  State<StockSummaryScreen> createState() => _StockSummaryScreenState();
}

class _StockSummaryScreenState extends State<StockSummaryScreen> {
  late final StockSummaryController _controller;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InvColors.bodyBg,
      appBar: _StockSummaryAppBar(
        onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
        onRefresh: _controller.load,
      ),
      body: _StockSummaryBody(controller: _controller),
    );
  }
}
