import 'package:flutter/material.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/low_stock_alert_controller.dart';
import 'package:lotus_erp/features/stock/shared/data/repositories/low_stock_alert_repository.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/app_bar/low_stock_alert_app_bar.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/body/low_stock_alert_body.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

class LowStockAlertScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const LowStockAlertScreen({super.key, this.onBack});

  @override
  State<LowStockAlertScreen> createState() => _LowStockAlertScreenState();
}

class _LowStockAlertScreenState extends State<LowStockAlertScreen> {
  late final LowStockAlertController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LowStockAlertController(
      LowStockAlertRepository(AppDatabase()),
    );
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

  void _handleBack() {
    final fallback = widget.onBack ?? () => Navigator.of(context).maybePop();
    fallback();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InvColors.bodyBg,
      appBar: LowStockAlertAppBar(
        onBack: _handleBack,
        onRefresh: _controller.load,
      ),
      body: LowStockAlertBody(controller: _controller),
    );
  }
}
