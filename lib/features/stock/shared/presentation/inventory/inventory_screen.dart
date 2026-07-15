// =============================================================================
// FILE        : inventory_screen.dart
// MODULE      : Stock & Inventory
// LAYER       : UI / Screen
// DESCRIPTION : Production Inventory Ledger screen.
//               Design matches Customer List header exactly:
//               - Dark shell AppBar with Gold Gradient module icon
//               - Pill-shaped Animated System Online Radar
//               - Cream body background (0xFFF9F6F0)
//               - Staggered entry animations
//               - Icons properly extracted to InvIcons
// =============================================================================

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/inventory_controller.dart';
//import 'package:lotus_erp/features/stock/shared/domain/models/inventory/inventory_stats_model.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';
import 'package:lotus_erp/features/stock/shared/presentation/add_stock/stock_metal_ui.dart';
import 'package:lotus_erp/features/stock/shared/presentation/inventory/metal_hub/inventory_metal_summary_grid.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

part 'app_bar/inventory_app_bar.dart';
part 'metal_grade/inventory_grade_detail_screen.dart';
part 'metal_grade/batch_detail/inventory_batch_models.dart';
part 'metal_grade/batch_detail/inventory_batch_list_widgets.dart';
part 'metal_grade/batch_detail/inventory_batch_dossier_screen.dart';
part 'metal_grade/batch_detail/inventory_batch_pdf_service.dart';
part 'metal_grade/batch_detail/inventory_batch_status_pdf_service.dart';
part 'metal_grade/batch_detail/inventory_batch_helpers.dart';
part 'metal_grade/inventory_grade_summary_card.dart';
part 'metal_grade/inventory_metal_grade_screen.dart';
part 'movements/inventory_movement_widgets.dart';
part 'screen_body/inventory_body.dart';
part 'sections/inventory_detail_sections.dart';
part 'stock_list/gold_inventory_group_widgets.dart';
part 'stock_list/inventory_stock_item_widgets.dart';
part 'widgets/inventory_summary_widgets.dart';

// =============================================================================
// MASTER SCREEN
// =============================================================================

class InventoryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const InventoryScreen({super.key, this.onBack});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with TickerProviderStateMixin {
  late final InventoryController _ctrl;
  final AppDatabase _db = AppDatabase();

  // â”€â”€ Section entry animations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const int _sectionCount = 6;
  late final List<AnimationController> _sectionAnim;
  late final List<Animation<double>> _sectionFade;
  late final List<Animation<Offset>> _sectionSlide;

  // â”€â”€ Currency formatter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final _rupee = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 0,
  );
  final _wt = NumberFormat('##0.00', 'en_IN');
  StockCategory? _selectedMetal;

  @override
  void initState() {
    super.initState();
    _ctrl = InventoryController(_db);
    _ctrl.addListener(_rebuild);

    // Staggered entry animations
    _sectionAnim = List.generate(
      _sectionCount,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _sectionFade = _sectionAnim
        .map((ac) => CurvedAnimation(parent: ac, curve: Curves.easeInOut))
        .toList();
    _sectionSlide = _sectionAnim
        .map(
          (ac) => Tween<Offset>(
            begin: const Offset(0, 0.10),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: ac, curve: Curves.easeOutCubic)),
        )
        .toList();

    for (int i = 0; i < _sectionCount; i++) {
      Future.delayed(Duration(milliseconds: 60 + i * 90), () {
        if (mounted) _sectionAnim[i].forward();
      });
    }

    _ctrl.loadStats();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl
      ..removeListener(_rebuild)
      ..dispose();
    for (final a in _sectionAnim) {
      a.dispose();
    }
    super.dispose();
  }

  Widget _animated(int index, Widget child) {
    return FadeTransition(
      opacity: _sectionFade[index],
      child: SlideTransition(position: _sectionSlide[index], child: child),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // BUILD
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InvColors.bodyBg,
      appBar: _InventoryAppBar(
        onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
      ),
      body: _ctrl.isLoading && _ctrl.stats.openingCount == 0
          ? _buildLoadingState()
          : _buildBody(),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // PAGE HEADER
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  void _openMetalLedger(StockCategory metal) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, __) =>
            _InventoryMetalGradeScreen(metal: metal),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.025, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _selectInventoryCategory(String category) {
    setState(() {
      _ctrl.setCategory(category);
    });
  }
}
