import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lotus_erp/features/stock/shared/application/stock_transfer_controller.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_transfer/stock_transfer_models.dart';
import 'package:lotus_erp/features/stock/shared/presentation/stock_transfer/widgets/stock_transfer_shared_widgets.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

class StockTransferDraftPanel extends StatefulWidget {
  final StockTransferController controller;
  final Future<void> Function(StockTransferForm form) onSubmit;

  const StockTransferDraftPanel({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  @override
  State<StockTransferDraftPanel> createState() =>
      _StockTransferDraftPanelState();
}

class _StockTransferDraftPanelState extends State<StockTransferDraftPanel> {
  late final TextEditingController _fromLocation;
  late final TextEditingController _toLocation;
  late final TextEditingController _carrierName;
  late final TextEditingController _authorizedBy;
  late final TextEditingController _notes;
  String _transferType = 'Branch Transfer';
  DateTime? _expectedDate;

  @override
  void initState() {
    super.initState();
    _fromLocation = TextEditingController(text: 'Main Showroom');
    _toLocation = TextEditingController(text: 'Vault');
    _carrierName = TextEditingController();
    _authorizedBy = TextEditingController();
    _notes = TextEditingController();
  }

  @override
  void dispose() {
    _fromLocation.dispose();
    _toLocation.dispose();
    _carrierName.dispose();
    _authorizedBy.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickExpectedDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _expectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null) return;
    setState(() => _expectedDate = date);
  }

  StockTransferForm _form() {
    return StockTransferForm(
      fromLocation: _fromLocation.text,
      toLocation: _toLocation.text,
      transferType: _transferType,
      carrierName: _carrierName.text,
      authorizedBy: _authorizedBy.text,
      expectedDate: _expectedDate,
      notes: _notes.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final canSubmit =
        controller.selectedUnits.isNotEmpty && !controller.isSaving;

    return TransferPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TransferSectionHeader(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Transfer Slip',
            subtitle: 'Prepare, lock and audit selected stock units.',
            trailing: TransferPrimaryButton(
              icon: Icons.clear_all_rounded,
              label: 'Clear',
              onTap: controller.selectedUnits.isEmpty
                  ? null
                  : controller.clearSelection,
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.05,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              TransferMetricTile(
                label: 'Selected',
                value: '${controller.selectedPieces} pcs',
                icon: Icons.fact_check_outlined,
                accent: InvColors.brandGold,
              ),
              TransferMetricTile(
                label: 'Net Weight',
                value: transferWeight(controller.selectedNetWeight),
                icon: Icons.scale_rounded,
                accent: InvColors.openingAccent,
              ),
              TransferMetricTile(
                label: 'Gross Weight',
                value: transferWeight(controller.selectedGrossWeight),
                icon: Icons.monitor_weight_outlined,
                accent: InvColors.success,
              ),
              TransferMetricTile(
                label: 'Fine Weight',
                value: transferWeight(controller.selectedFineWeight),
                icon: Icons.auto_graph_rounded,
                accent: InvColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (controller.selectedUnits.isEmpty)
            _SelectedEmptyState()
          else
            _SelectedUnitList(controller: controller),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in const [
                'Branch Transfer',
                'Vault Movement',
                'Counter Movement',
                'Exhibition Transfer',
                'Karigar Issue',
              ])
                TransferChip(
                  label: type,
                  selected: _transferType == type,
                  onTap: () => setState(() => _transferType = type),
                ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumn = constraints.maxWidth > 620;
              final fields = [
                TransferTextField(
                  controller: _fromLocation,
                  label: 'From Location',
                  icon: Icons.storefront_rounded,
                ),
                TransferTextField(
                  controller: _toLocation,
                  label: 'To Location',
                  icon: Icons.location_on_outlined,
                ),
                TransferTextField(
                  controller: _carrierName,
                  label: 'Carrier / Staff',
                  icon: Icons.badge_outlined,
                  hintText: 'Optional',
                ),
                TransferTextField(
                  controller: _authorizedBy,
                  label: 'Authorized By',
                  icon: Icons.verified_user_outlined,
                ),
              ];
              if (!twoColumn) {
                return Column(
                  children: [
                    for (final field in fields) ...[
                      field,
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              }
              return GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3.6,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: fields,
              );
            },
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _pickExpectedDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: InvColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available_rounded,
                      color: InvColors.textMuted, size: 19),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _expectedDate == null
                          ? 'Expected receive date'
                          : DateFormat('dd MMM yyyy').format(_expectedDate!),
                      style: InvStyles.cardSubValue,
                    ),
                  ),
                  const Icon(Icons.calendar_month_rounded,
                      color: InvColors.brandGold, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          TransferTextField(
            controller: _notes,
            label: 'Transfer Note',
            icon: Icons.notes_rounded,
            hintText: 'Gate pass, packet seal, handover note',
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          TransferPrimaryButton(
            icon: controller.isSaving
                ? Icons.hourglass_top_rounded
                : Icons.lock_clock_rounded,
            label: controller.isSaving ? 'Saving Transfer' : 'Create Transfer',
            onTap: canSubmit ? () => widget.onSubmit(_form()) : null,
          ),
        ],
      ),
    );
  }
}

class _SelectedUnitList extends StatelessWidget {
  final StockTransferController controller;

  const _SelectedUnitList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: InvColors.cardBorder),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: controller.selectedUnits.length,
        separatorBuilder: (_, __) => const Divider(
          color: InvColors.divider,
          height: 1,
        ),
        itemBuilder: (context, index) {
          final unit = controller.selectedUnits[index];
          return ListTile(
            dense: true,
            title: Text(
              unit.displayName,
              style: InvStyles.itemName.copyWith(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${unit.unitCode} | ${transferWeight(unit.netWeight)}',
              style: InvStyles.itemSku,
            ),
            trailing: IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () => controller.removeUnit(unit.id),
            ),
          );
        },
      ),
    );
  }
}

class _SelectedEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: InvColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.playlist_add_check_rounded,
            size: 34,
            color: InvColors.textHint,
          ),
          const SizedBox(height: 8),
          Text('No units selected', style: InvStyles.sectionTitle),
          const SizedBox(height: 3),
          Text(
            'Select available stock from the left panel to prepare a transfer.',
            style: InvStyles.cardNote,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
