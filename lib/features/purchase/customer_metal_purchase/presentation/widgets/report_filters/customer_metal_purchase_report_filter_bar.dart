import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_controller.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/report_filters/customer_metal_purchase_filter_controls.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/report_filters/customer_metal_purchase_month_selector.dart';
import 'package:lotus_erp/theme/purchase/purchase_entry/purchase_entry_theme.dart';

class CustomerMetalPurchaseReportFilterBar extends StatelessWidget {
  final CustomerMetalPurchaseLedgerController controller;

  const CustomerMetalPurchaseReportFilterBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return CustomerMetalPurchaseFilterSurface(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FilterHeader(controller: controller),
                const SizedBox(height: 12),
                CustomerMetalPurchaseSearchField(
                  controller: controller.searchCtrl,
                ),
                const SizedBox(height: 12),
                CustomerMetalPurchaseMonthSelector(controller: controller),
                const SizedBox(height: 12),
                CustomerMetalPurchaseStatusFilter(controller: controller),
                const SizedBox(height: 10),
                CustomerMetalPurchaseActiveMetalChip(
                  metal: controller.selectedMetal,
                  onClear: () => controller.selectMetal(null),
                ),
              ],
            );
          }

          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _FilterHeader(controller: controller)),
                  const SizedBox(width: 24),
                  SizedBox(
                    width: constraints.maxWidth >= 1180 ? 520 : 390,
                    child: CustomerMetalPurchaseSearchField(
                      controller: controller.searchCtrl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomerMetalPurchaseMonthSelector(controller: controller),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 47),
                      child: CustomerMetalPurchaseStatusFilter(
                        controller: controller,
                      ),
                    ),
                  ),
                ],
              ),
              if (controller.selectedMetal != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: CustomerMetalPurchaseActiveMetalChip(
                    metal: controller.selectedMetal,
                    onClear: () => controller.selectMetal(null),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _FilterHeader extends StatelessWidget {
  final CustomerMetalPurchaseLedgerController controller;

  const _FilterHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    final entryCount = controller.filteredEntries.length;
    final voucherCount = controller.dashboardSummary.voucherCount;
    final lineLabel = entryCount == 1 ? 'line' : 'lines';
    final voucherLabel = voucherCount == 1 ? 'voucher' : 'vouchers';
    final countLabel = entryCount == 0
        ? 'No purchase lines'
        : 'Records 1-$entryCount | $entryCount $lineLabel';

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.tune_rounded,
            color: PurchaseEntryColors.purchaseAccent,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report Controls',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  color: PurchaseEntryColors.textMain,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$countLabel | $voucherCount $voucherLabel | ${controller.periodDateRangeLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
