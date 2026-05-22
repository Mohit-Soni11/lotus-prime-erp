// =============================================================================
// FILE        : lib/ui/settings/metal_rate/metal_rate_detail_screen.dart
// MODULE      : Metal Rate Setting
// LAYER       : UI / Presentation
// DESCRIPTION : Daily rate master shell with focused widget parts.
// =============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../logic/setting/metal_rate/metal_rate_controller.dart';
import '../../../models/setting/metal_rate/metal_rate_model.dart';
import '../../../theme/settings/metal_rate/metal_rate_theme.dart';
import 'metal_rate_app_bar.dart';

part 'widgets/metal_rate_counter_section.dart';
part 'widgets/metal_rate_detail_shared.dart';
part 'widgets/metal_rate_header_reference.dart';
part 'widgets/metal_rate_history_card.dart';

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
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${profile.metal.label} rates saved and applied to billing.',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: MetalRateColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _reset() async {
    await widget.controller.resetProfile(widget.metal);
    if (!mounted) return;
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.metal.label} default rates restored.',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: MetalRateColors.warning,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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
          backgroundColor: MetalRateColors.bodyBg,
          appBar: MetalRateAppBar(
            screenTitle: '${widget.metal.label} Rate Master',
            onBack: () => Navigator.maybePop(context),
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
                  _HistoryCard(history: history, accent: accent),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
