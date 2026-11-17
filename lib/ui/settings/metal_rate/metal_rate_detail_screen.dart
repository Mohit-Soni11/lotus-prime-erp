// =============================================================================
// FILE        : lib/ui/settings/metal_rate/metal_rate_detail_screen.dart
// MODULE      : Metal Rate Setting
// LAYER       : UI / Presentation
// DESCRIPTION : Daily rate master shell with focused widget parts.
// =============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../logic/setting/metal_rate/metal_rate_controller.dart';
import '../../../models/setting/metal_rate/metal_rate_model.dart';
import '../../../models/setting/metal_rate/metal_rate_history_view.dart';
import '../../../models/setting/metal_rate/metal_rate_revision_change.dart';
import '../../../models/setting/metal_rate/metal_rate_price_unit.dart';
import '../../../theme/settings/metal_rate/metal_rate_theme.dart';
import 'metal_rate_app_bar.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

part 'widgets/metal_rate_counter_section.dart';
part 'widgets/metal_rate_counter_cells.dart';
part 'widgets/metal_rate_detail_shared.dart';
part 'widgets/metal_rate_header_reference.dart';
part 'widgets/metal_rate_history_card.dart';
part 'widgets/metal_rate_history_chart.dart';
part 'widgets/metal_rate_history_entries.dart';
part 'widgets/metal_rate_old_metal_card.dart';
part 'widgets/metal_rate_reference_section.dart';

class MetalRateDetailScreen extends StatefulWidget {
  final MetalRateMetal metal;
  final MetalRateController controller;

  const MetalRateDetailScreen({
    super.key,
    required this.metal,
    required this.controller,
  });

  @override
  State<MetalRateDetailScreen> createState() => _MetalRateDetailScreenState();
}

class _MetalRateDetailScreenState extends State<MetalRateDetailScreen> {
  bool _isEditing = false;

  Future<void> _save(MetalRateProfile profile) async {
    await widget.controller.saveProfile(profile);
    if (!mounted) return;
    if (widget.controller.state == MetalRateLoadState.error) {
      AppFeedback.show(context,
          type: AppFeedbackType.error,
          message: widget.controller.errorMessage ?? 'Unable to save rates.');
      return;
    }
    setState(() => _isEditing = false);
    AppFeedback.show(
      context,
      type: AppFeedbackType.success,
      message: '${profile.metal.label} rates saved and applied to billing.',
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Reset ${widget.metal.label} rates?'),
        content: const Text(
            'This will clear the configured rates for this metal and add a revision to rate history.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Reset rates')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.controller.resetProfile(widget.metal);
    if (!mounted) return;
    if (widget.controller.state == MetalRateLoadState.error) {
      AppFeedback.show(context,
          type: AppFeedbackType.error,
          message: widget.controller.errorMessage ?? 'Unable to reset rates.');
      return;
    }
    setState(() => _isEditing = false);
    AppFeedback.show(
      context,
      type: AppFeedbackType.warning,
      message: '${widget.metal.label} default rates restored.',
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _cancel() async {
    await widget.controller.refresh();
    if (!mounted) return;
    if (widget.controller.state == MetalRateLoadState.error) {
      AppFeedback.show(context,
          type: AppFeedbackType.error,
          message: widget.controller.errorMessage ??
              'Unable to reload saved rates.');
      return;
    }
    setState(() => _isEditing = false);
  }

  Future<void> _goBack() async {
    if (_isEditing) await _cancel();
    if (mounted && !_isEditing) {
      Navigator.of(context, rootNavigator: true).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final profile = widget.controller.profileFor(widget.metal);
        final history = widget.controller.historyFor(widget.metal);
        final accent = _metalAccent(widget.metal);
        final isSaving = widget.controller.state == MetalRateLoadState.saving;

        return Scaffold(
          backgroundColor: MetalRateDetailStyles.canvas,
          appBar: MetalRateAppBar(
            screenTitle: '${widget.metal.label} Rate Master',
            onBack: _goBack,
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: MetalRateStyles.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderCard(
                    profile: profile,
                    accent: accent,
                    isEditing: _isEditing,
                    isSaving: isSaving,
                    onEdit: () => setState(() => _isEditing = true),
                    onSave: () => _save(profile),
                    onCancel: _cancel,
                    onReset: _reset,
                  ),
                  const SizedBox(height: 14),
                  _MarketReferenceSection(
                    profile: profile,
                    accent: accent,
                    controller: widget.controller,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 14),
                  _CounterRateSection(
                    profile: profile,
                    accent: accent,
                    controller: widget.controller,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 14),
                  _OldMetalPurchaseCard(
                    profile: profile,
                    controller: widget.controller,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 14),
                  _HistoryCard(
                    history: history,
                    accent: accent,
                    priceUnit: MetalRatePriceUnit.forMetal(widget.metal),
                    purityLabels: [
                      for (final plan in profile.purityPlans) plan.label,
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
