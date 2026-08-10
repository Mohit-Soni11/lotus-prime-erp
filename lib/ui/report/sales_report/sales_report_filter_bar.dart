import 'package:flutter/material.dart';

import '../../../logic/report/sales_report/sales_report_controller.dart';
import '../../../models/reports/sales_report/sales_report_models.dart';
import '../../../theme/reports/sales_report/sales_report_theme.dart';
import 'sales_report_formatters.dart';

class SalesReportFilterBar extends StatelessWidget {
  final SalesReportController controller;

  const SalesReportFilterBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final filter = controller.filter;
    final snapshot = controller.snapshot;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _PresetSelector(
            value: filter.preset,
            onChanged: controller.applyPreset,
          ),
          _DateRangeButton(
            label:
                '${salesReportDate(filter.startDate)} - ${salesReportDate(filter.endDate)}',
            onTap: () => controller.selectCustomRange(context),
          ),
          _TaxSelector(
            value: filter.taxMode,
            onChanged: controller.setTaxMode,
          ),
          _PaymentSelector(
            value: filter.paymentFilter,
            onChanged: controller.setPaymentFilter,
          ),
          _MetalSelector(
            value: filter.metalType,
            metals: snapshot?.availableMetals ?? const ['ALL'],
            onChanged: controller.setMetalType,
          ),
          SizedBox(
            width: 300,
            child: TextField(
              controller: controller.searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => controller.applySearch(),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Invoice, customer, mobile, HUID, SKU',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                suffixIcon: filter.query.isEmpty
                    ? IconButton(
                        tooltip: 'Search',
                        onPressed: controller.applySearch,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      )
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: controller.clearSearch,
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetSelector extends StatelessWidget {
  final SalesReportDatePreset value;
  final ValueChanged<SalesReportDatePreset> onChanged;

  const _PresetSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SalesReportDatePreset>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: SalesReportDatePreset.today, label: Text('Today')),
        ButtonSegment(
          value: SalesReportDatePreset.yesterday,
          label: Text('Yesterday'),
        ),
        ButtonSegment(
          value: SalesReportDatePreset.thisMonth,
          label: Text('This Month'),
        ),
        ButtonSegment(
          value: SalesReportDatePreset.lastMonth,
          label: Text('Last Month'),
        ),
      ],
      selected: value == SalesReportDatePreset.custom ? const {} : {value},
      onSelectionChanged: (selected) {
        if (selected.isEmpty) return;
        onChanged(selected.first);
      },
    );
  }
}

class _DateRangeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DateRangeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Choose custom report period',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: SalesReportColors.brandGold.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: SalesReportColors.brandGold.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                SalesReportIcons.calendar,
                size: 16,
                color: SalesReportColors.brandGold,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: SalesReportStyles.body.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: SalesReportColors.brandGold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaxSelector extends StatelessWidget {
  final SalesReportTaxMode value;
  final ValueChanged<SalesReportTaxMode> onChanged;

  const _TaxSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<SalesReportTaxMode>(
      value: value,
      underline: const SizedBox.shrink(),
      items: const [
        DropdownMenuItem(value: SalesReportTaxMode.all, child: Text('All Tax')),
        DropdownMenuItem(value: SalesReportTaxMode.gst, child: Text('GST')),
        DropdownMenuItem(
          value: SalesReportTaxMode.nonGst,
          child: Text('Non-GST'),
        ),
      ],
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}

class _PaymentSelector extends StatelessWidget {
  final SalesReportPaymentFilter value;
  final ValueChanged<SalesReportPaymentFilter> onChanged;

  const _PaymentSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<SalesReportPaymentFilter>(
      value: value,
      underline: const SizedBox.shrink(),
      items: const [
        DropdownMenuItem(
          value: SalesReportPaymentFilter.all,
          child: Text('All Payments'),
        ),
        DropdownMenuItem(
            value: SalesReportPaymentFilter.paid, child: Text('Paid')),
        DropdownMenuItem(
            value: SalesReportPaymentFilter.due, child: Text('Due')),
        DropdownMenuItem(
          value: SalesReportPaymentFilter.partial,
          child: Text('Partial'),
        ),
      ],
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}

class _MetalSelector extends StatelessWidget {
  final String value;
  final List<String> metals;
  final ValueChanged<String> onChanged;

  const _MetalSelector({
    required this.value,
    required this.metals,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = metals
            .any((metal) => metal.toUpperCase() == value.toUpperCase())
        ? metals
            .firstWhere((metal) => metal.toUpperCase() == value.toUpperCase())
        : 'ALL';

    return DropdownButton<String>(
      value: normalized,
      underline: const SizedBox.shrink(),
      items: [
        for (final metal in metals)
          DropdownMenuItem(
            value: metal,
            child: Text(metal == 'ALL' ? 'All Metals' : metal),
          ),
      ],
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}
