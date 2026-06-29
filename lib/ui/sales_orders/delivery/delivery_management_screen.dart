// =============================================================================
// FILE        : delivery_management_screen.dart
// MODULE      : Sales → Delivery Management
// LAYER       : UI
// DESCRIPTION : MASTER SCREEN — main entry point for Delivery Management.
//               Responsive layout:
//                 Desktop (>900px): Left list (60%) + Right detail panel (40%)
//                 Mobile  (<900px): List only, detail opens as bottom sheet / push
//               Structure: AppBar → StatsHeader → TabBar → Body
// =============================================================================

import 'package:flutter/material.dart';
import '../../../logic/sales_orders/delivery/delivery_management_controller.dart';
import '../../../theme/sales/delivery/delivery_theme.dart';
import 'delivery_app_bar.dart';
import 'delivery_stats_header.dart';
import 'delivery_tab_bar.dart';
import 'delivery_order_list.dart';
import 'delivery_detail_panel.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

class DeliveryManagementScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const DeliveryManagementScreen({super.key, this.onBack});

  @override
  State<DeliveryManagementScreen> createState() =>
      _DeliveryManagementScreenState();
}

class _DeliveryManagementScreenState extends State<DeliveryManagementScreen> {
  late final DeliveryManagementController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = DeliveryManagementController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: DeliveryColors.bodyBg,
        appBar: DeliveryAppBar(
          onBack: widget.onBack ?? () => Navigator.of(context).pop(),
          // Removed onRefresh from here as we updated the AppBar
        ),
        body: SafeArea(
          child: Column(
            children: [
              // ── Stats Header ────────────────────────────────────────────
              ListenableBuilder(
                listenable: _ctrl,
                builder: (_, __) => DeliveryStatsHeader(ctrl: _ctrl),
              ),

              // ── Tab Bar ─────────────────────────────────────────────────
              ListenableBuilder(
                listenable: _ctrl,
                builder: (_, __) => DeliveryTabBar(ctrl: _ctrl),
              ),

              // ── Body ─────────────────────────────────────────────────────
              Expanded(
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    final isDesktop = constraints.maxWidth >= 900;

                    if (isDesktop) {
                      return _DesktopLayout(ctrl: _ctrl);
                    } else {
                      return _MobileLayout(ctrl: _ctrl);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Desktop Layout: 60% list + 40% detail panel ───────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final DeliveryManagementController ctrl;
  const _DesktopLayout({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left — Order List (60%)
        Expanded(
          flex: 60,
          child: DeliveryOrderList(ctrl: ctrl),
        ),

        // Right — Detail Panel (40%)
        Expanded(
          flex: 40,
          child: DeliveryDetailPanel(
            ctrl: ctrl,
            onDelivered: () {
              AppFeedback.show(
                context,
                type: AppFeedbackType.success,
                message: DeliveryStrings.feedbackDelivered,
                duration: const Duration(seconds: 2),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Mobile Layout: list only, detail opens as modal bottom sheet ─────────────
class _MobileLayout extends StatelessWidget {
  final DeliveryManagementController ctrl;
  const _MobileLayout({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (_, __) {
        // When an order is selected on mobile → show bottom sheet
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (ctrl.selectedOrder != null) {
            _showDetailSheet(context);
          }
        });
        return DeliveryOrderList(ctrl: ctrl);
      },
    );
  }

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: DeliveryColors.bodyPanelBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: DeliveryDetailPanel(
            ctrl: ctrl,
            onDelivered: () {
              Navigator.of(context).pop();
              AppFeedback.show(
                context,
                type: AppFeedbackType.success,
                message: DeliveryStrings.feedbackDelivered,
              );
            },
          ),
        ),
      ),
    ).then((_) => ctrl.clearSelection());
  }
}
