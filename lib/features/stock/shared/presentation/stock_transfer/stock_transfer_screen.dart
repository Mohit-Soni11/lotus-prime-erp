import 'package:flutter/material.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/stock_transfer_controller.dart';
import 'package:lotus_erp/features/stock/shared/data/repositories/stock_transfer_repository.dart';
import 'package:lotus_erp/features/stock/shared/presentation/stock_transfer/app_bar/stock_transfer_app_bar.dart';
import 'package:lotus_erp/features/stock/shared/presentation/stock_transfer/body/stock_transfer_body.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

class StockTransferScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const StockTransferScreen({super.key, this.onBack});

  @override
  State<StockTransferScreen> createState() => _StockTransferScreenState();
}

class _StockTransferScreenState extends State<StockTransferScreen> {
  late final StockTransferController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StockTransferController(
      StockTransferRepository(AppDatabase()),
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
      appBar: StockTransferAppBar(
        onBack: _handleBack,
        onRefresh: _controller.load,
      ),
      body: StockTransferBody(controller: _controller),
    );
  }
}
