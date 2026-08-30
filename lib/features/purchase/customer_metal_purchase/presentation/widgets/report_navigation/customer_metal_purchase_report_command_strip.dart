import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_controller.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/exports/customer_metal_purchase_report_print_service.dart';
import 'package:lotus_erp/theme/purchase/purchase_entry/purchase_entry_theme.dart';

class CustomerMetalPurchaseReportCommandStrip extends StatelessWidget {
  final CustomerMetalPurchaseLedgerController controller;

  const CustomerMetalPurchaseReportCommandStrip({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final printButton = _ReportPrintButton(
          enabled: controller.filteredEntries.isNotEmpty,
          onPressed: () => _printReport(context),
        );

        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomerMetalPurchaseReportTabs(controller: controller),
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: printButton),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CustomerMetalPurchaseReportTabs(controller: controller),
            ),
            const SizedBox(width: 14),
            printButton,
          ],
        );
      },
    );
  }

  Future<void> _printReport(BuildContext context) async {
    try {
      await CustomerMetalPurchaseReportPrintService.printReport(
        periodLabel: controller.periodLabel,
        dashboard: controller.dashboardSummary,
        metalSummaries: controller.visibleMetalSummaries,
        entries: controller.filteredEntries,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report print failed: $error')),
      );
    }
  }
}

class CustomerMetalPurchaseReportTabs extends StatelessWidget {
  final CustomerMetalPurchaseLedgerController controller;

  const CustomerMetalPurchaseReportTabs({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tab in CustomerMetalPurchaseReportTab.values)
          _ReportTabButton(
            label: tab.label,
            selected: controller.selectedTab == tab,
            onTap: () => controller.selectTab(tab),
          ),
      ],
    );
  }
}

class _ReportTabButton extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ReportTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ReportTabButton> createState() => _ReportTabButtonState();
}

class _ReportTabButtonState extends State<_ReportTabButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected;
    const accent = PurchaseEntryColors.purchaseAccent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          splashColor: accent.withValues(alpha: 0.08),
          highlightColor: accent.withValues(alpha: 0.04),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minWidth: 82, minHeight: 42),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            decoration: BoxDecoration(
              color: active
                  ? accent.withValues(alpha: 0.12)
                  : _hovered
                      ? const Color(0xFFF8FAFC)
                      : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: active
                    ? accent
                    : _hovered
                        ? const Color(0xFFCBD5E1)
                        : PurchaseEntryColors.bodyBorder,
                width: active ? 1.25 : 1,
              ),
              boxShadow: [
                if (active || _hovered)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: active ? 0.07 : 0.04),
                    blurRadius: active ? 13 : 9,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: active ? accent : const Color(0xFF111827),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportPrintButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _ReportPrintButton({
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: PurchaseEntryColors.purchaseAccent.withValues(
                    alpha: 0.20,
                  ),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.print_rounded, size: 18),
        label: const Text('Print Report'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(160, 42),
          padding: const EdgeInsets.symmetric(horizontal: 17),
          backgroundColor: PurchaseEntryColors.purchaseAccent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE5E7EB),
          disabledForegroundColor: const Color(0xFF94A3B8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
