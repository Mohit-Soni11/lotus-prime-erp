import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/stock_activity_controller.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_activity/stock_activity_models.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

part 'app_bar/stock_activity_app_bar.dart';
part 'body/stock_activity_body.dart';
part 'widgets/stock_activity_breakdown_panel.dart';
part 'widgets/stock_activity_shared_widgets.dart';
part 'widgets/stock_activity_widgets.dart';

class StockActivityScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const StockActivityScreen({super.key, this.onBack});

  @override
  State<StockActivityScreen> createState() => _StockActivityScreenState();
}

class _StockActivityScreenState extends State<StockActivityScreen> {
  late final StockActivityController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StockActivityController(AppDatabase());
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
      appBar: _StockActivityAppBar(
        onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
        onRefresh: _controller.load,
      ),
      body: _StockActivityBody(controller: _controller),
    );
  }
}
