import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/features/stock/silver/application/silver_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_silver/silver_stock_theme.dart';

class SilverIntakeWorkflowCard extends StatelessWidget {
  final SilverStockController ctrl;

  const SilverIntakeWorkflowCard({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ctrl,
        ctrl.payment,
        ctrl.supplierInvoiceNumberCtrl,
        ctrl.supplierNameCtrl,
        ctrl.supplierMobileCtrl,
      ]),
      builder: (context, _) {
        final steps = _workflowSteps();

        return Container(
          decoration: BoxDecoration(
            color: SilverStockColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: SilverStockColors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: SilverStockColors.shadowLight,
                blurRadius: 16,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 1180) {
                  return SizedBox(
                    height: 92,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(10),
                      scrollDirection: Axis.horizontal,
                      itemCount: steps.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) => SizedBox(
                        width: 274,
                        child: _WorkflowStepTile(
                          step: steps[index],
                        ),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      for (var index = 0; index < steps.length; index++) ...[
                        Expanded(child: _WorkflowStepTile(step: steps[index])),
                        if (index != steps.length - 1)
                          const SizedBox(width: 10),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  List<_WorkflowStep> _workflowSteps() {
    final supplierName = ctrl.supplierDisplayName.trim();
    final supplierMobile = ctrl.supplierMobileCtrl.text.trim();
    final supplierInvoice = ctrl.supplierInvoiceNumberCtrl.text.trim();
    final hasSupplier = supplierName.isNotEmpty || supplierMobile.isNotEmpty;
    final hasInvoice = supplierInvoice.isNotEmpty;
    final hasItems = ctrl.enteredRowCount > 0;
    final hasErrors = ctrl.rowsWithErrorsCount > 0;
    final gradeTone = _gradeTone();

    return [
      _WorkflowStep(
        number: 1,
        title: 'Intake Source',
        subtitle:
            ctrl.gstEnabled ? 'GST supplier purchase' : 'Supplier purchase',
        icon: ctrl.gstEnabled
            ? Icons.account_balance_rounded
            : Icons.store_rounded,
        tone: ctrl.gstEnabled
            ? SilverStockColors.success
            : SilverStockColors.paymentPrimary,
        state: _WorkflowStepState.complete,
      ),
      _WorkflowStep(
        number: 2,
        title: 'Metal & Tracking',
        subtitle: _metalTrackingSummary(),
        icon: _gradeIcon(),
        tone: gradeTone,
        state: ctrl.purityDisplay.trim().isEmpty
            ? _WorkflowStepState.active
            : _WorkflowStepState.complete,
      ),
      _WorkflowStep(
        number: 3,
        title: 'Supplier & Invoice',
        subtitle: _supplierInvoiceSummary(
          supplierName: supplierName,
          supplierMobile: supplierMobile,
          supplierInvoice: supplierInvoice,
        ),
        icon: SilverStockIcons.supplierProfile,
        tone: SilverStockColors.accentCompliance,
        state: !hasSupplier || !hasInvoice
            ? _WorkflowStepState.active
            : _WorkflowStepState.complete,
      ),
      _WorkflowStep(
        number: 4,
        title: 'Item Entry',
        subtitle:
            '${ctrl.enteredRowCount} item${ctrl.enteredRowCount == 1 ? '' : 's'} • ${ctrl.totalNetWeight.toStringAsFixed(3)} g',
        icon: SilverStockIcons.inventoryMgmt,
        tone: SilverStockColors.accentInventory,
        state:
            hasItems ? _WorkflowStepState.complete : _WorkflowStepState.active,
      ),
      _WorkflowStep(
        number: 5,
        title: 'Settlement & Review',
        subtitle: _settlementSummary(),
        icon: SilverStockIcons.invoiceSummary,
        tone: hasErrors ? SilverStockColors.danger : SilverStockColors.success,
        state: hasItems
            ? hasErrors
                ? _WorkflowStepState.warning
                : _WorkflowStepState.active
            : _WorkflowStepState.pending,
      ),
    ];
  }

  String _metalTrackingSummary() {
    final grade = ctrl.purityDisplay.trim();
    final gradeText =
        grade.isEmpty ? 'Silver grade pending' : 'Silver • $grade';
    final hasHuid = ctrl.enteredSilverRows.any((row) => row.huid.isNotEmpty);
    return '$gradeText • ${hasHuid ? 'HUID linked' : 'HUID optional'}';
  }

  String _supplierInvoiceSummary({
    required String supplierName,
    required String supplierMobile,
    required String supplierInvoice,
  }) {
    if (supplierName.isEmpty &&
        supplierMobile.isEmpty &&
        supplierInvoice.isEmpty) {
      return ctrl.batchCode;
    }

    return [
      if (supplierName.isNotEmpty) supplierName,
      if (supplierMobile.isNotEmpty) supplierMobile,
      if (supplierInvoice.isNotEmpty) supplierInvoice,
    ].join(' • ');
  }

  String _settlementSummary() {
    if (ctrl.rowsWithErrorsCount > 0) {
      return '${ctrl.rowsWithErrorsCount} row${ctrl.rowsWithErrorsCount == 1 ? '' : 's'} need attention';
    }
    if (ctrl.enteredRowCount == 0) {
      return 'Review after item entry';
    }
    return 'Ready for valuation and save';
  }

  IconData _gradeIcon() {
    final purity = ctrl.purityDisplay.trim().toUpperCase();
    if (purity.contains('999') || purity.contains('99.9')) {
      return Icons.workspace_premium_rounded;
    }
    if (purity.contains('925') || purity.contains('92.5')) {
      return Icons.verified_rounded;
    }
    if (purity.contains('800') || purity.contains('80')) {
      return Icons.temple_hindu_rounded;
    }
    if (purity.contains('700') || purity.contains('70')) {
      return Icons.soup_kitchen_rounded;
    }
    if (purity.isNotEmpty) {
      return Icons.business_center_rounded;
    }
    return Icons.toll_rounded;
  }

  Color _gradeTone() {
    final purity = ctrl.purityDisplay.trim().toUpperCase();
    if (purity.contains('925') || purity.contains('92.5')) {
      return const Color(0xFF0F8A72);
    }
    if (purity.contains('800') || purity.contains('80')) {
      return const Color(0xFF8B5CF6);
    }
    if (purity.contains('700') || purity.contains('70')) {
      return const Color(0xFF2563EB);
    }
    if (purity.isNotEmpty &&
        !(purity.contains('999') || purity.contains('99.9'))) {
      return SilverStockColors.textMuted;
    }
    return SilverStockColors.brandSilver;
  }
}

enum _WorkflowStepState {
  complete,
  active,
  pending,
  warning;

  bool get isComplete => this == complete;
  bool get isActive => this == active || this == warning;
}

class _WorkflowStep {
  final int number;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tone;
  final _WorkflowStepState state;

  const _WorkflowStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.state,
  });
}

class _WorkflowStepTile extends StatelessWidget {
  final _WorkflowStep step;

  const _WorkflowStepTile({required this.step});

  @override
  Widget build(BuildContext context) {
    final active = step.state.isActive;
    final complete = step.state.isComplete;
    final pending = step.state == _WorkflowStepState.pending;
    final tone = pending ? SilverStockColors.textMuted : step.tone;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: active || complete
            ? tone.withValues(alpha: active ? 0.08 : 0.05)
            : SilverStockColors.cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: active || complete
              ? tone.withValues(alpha: active ? 0.58 : 0.28)
              : SilverStockColors.cardBorder,
          width: active ? 1.4 : 1,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: tone.withValues(alpha: 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ]
            : const [],
      ),
      child: Row(
        children: [
          _StepBadge(step: step, tone: tone),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(step.icon, size: 14, color: tone),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        step.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: SilverStockColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  step.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: SilverStockColors.textBody,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  final _WorkflowStep step;
  final Color tone;

  const _StepBadge({required this.step, required this.tone});

  @override
  Widget build(BuildContext context) {
    final active = step.state.isActive;
    final complete = step.state.isComplete;
    final pending = step.state == _WorkflowStepState.pending;

    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active || complete
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tone.withValues(alpha: 0.78), tone],
              )
            : null,
        color: pending ? SilverStockColors.inputBgLocked : null,
        boxShadow: active
            ? [
                BoxShadow(
                  color: tone.withValues(alpha: 0.22),
                  blurRadius: 9,
                  offset: const Offset(0, 3),
                ),
              ]
            : const [],
      ),
      child: complete
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 17)
          : Text(
              '${step.number}',
              style: GoogleFonts.manrope(
                color: active ? Colors.white : SilverStockColors.textBody,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}
