import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/stock_lifecycle_controller.dart';
import 'package:lotus_erp/features/stock/shared/application/stock_sale_restore_controller.dart';
import 'package:lotus_erp/features/stock/shared/application/stock_search_controller.dart';
import 'package:lotus_erp/features/stock/shared/application/stock_unit_history_controller.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_search/stock_search_models.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_search/stock_unit_history_models.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

part 'app_bar/stock_search_app_bar.dart';
part 'body/stock_search_body.dart';
part 'pdf/stock_card_pdf_service.dart';
part 'widgets/stock_search_widgets.dart';

class StockSearchScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const StockSearchScreen({super.key, this.onBack});

  @override
  State<StockSearchScreen> createState() => _StockSearchScreenState();
}

class _StockSearchScreenState extends State<StockSearchScreen> {
  late final StockSearchController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StockSearchController(AppDatabase());
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
      appBar: _StockSearchAppBar(
        onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
        onRefresh: _controller.load,
      ),
      body: _StockSearchBody(controller: _controller),
    );
  }
}
