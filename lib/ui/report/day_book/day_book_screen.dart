// =============================================================================
// FILE        : day_book_screen.dart
// MODULE      : Reports & Analytics â†’ Day Book
// LAYER       : UI â€” Master Screen Assembly
// DESCRIPTION : Top-level shell connecting all Day Book components.
//               Follows exact same pattern as CashBookScreen.
//
//               LAYOUT:
//               â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
//               â”‚  DARK APP BAR (module title, date nav, export buttons)   â”‚
//               â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
//               â”‚  SCROLLABLE BODY (Cream bg)                              â”‚
//               â”‚  â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ â”‚
//               â”‚  Opening Balance Card (dark)                             â”‚
//               â”‚  Anomaly Alert Banner (if any)                           â”‚
//               â”‚  Cash Inward Section  (expandable)                       â”‚
//               â”‚    â””â”€ GST Bills Sub-section   (teal)                     â”‚
//               â”‚    â””â”€ Non-GST Bills Sub-section (blue)                   â”‚
//               â”‚    â””â”€ Other inflows...                                   â”‚
//               â”‚  Cash Outward Section (expandable, red)                  â”‚
//               â”‚  Payment Mode Breakup (expandable)                       â”‚
//               â”‚  Metal Inward  Section (expandable, amber)               â”‚
//               â”‚  Metal Outward Section (expandable, purple)              â”‚
//               â”‚  Net Flow + Closing Balance Card                         â”‚
//               â”‚  Predicted Closing Card (today only)                     â”‚
//               â”‚  EOD Settlement Button (today only)                      â”‚
//               â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
//
//               âœ… Dark AppBar + Cream body
//               âœ… ListenableBuilder â€” zero setState in UI layer
//               âœ… GST and Non-GST bills shown separately
//               âœ… Anomaly detection alerts
//               âœ… EOD denomination dialog + day lock
//               âœ… Export PDF / Excel / WhatsApp
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import '../../../logic/report/day_book/day_book_controller.dart';
import 'day_book_app_bar.dart';
import 'day_book_sections.dart';
import 'day_book_eod_dialog.dart';

class DayBookScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const DayBookScreen({super.key, this.onBack});

  @override
  State<DayBookScreen> createState() => _DayBookScreenState();
}

class _DayBookScreenState extends State<DayBookScreen> {
  late final DayBookController _ctrl;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _ctrl = DayBookController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // â”€â”€ EOD Dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showEodDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => DayBookEodDialog(ctrl: _ctrl),
    );
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: DayBookColors.bodyBg,

        // â”€â”€ Dark App Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        appBar: DayBookAppBar(
          onBack: widget.onBack ?? () => Navigator.of(context).pop(),
          ctrl: _ctrl,
        ),

        // â”€â”€ Body â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        body: ListenableBuilder(
          listenable: _ctrl,
          builder: (_, __) {
            // Loading state
            if (_ctrl.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: DayBookColors.brandGold,
                  strokeWidth: 2.5,
                ),
              );
            }

            // Error state
            if (_ctrl.errorMessage != null) {
              return _ErrorState(
                message: _ctrl.errorMessage!,
                onRetry: _ctrl.loadData,
              );
            }

            // Empty state (no data)
            if (_ctrl.summary == null) {
              return const _EmptyState();
            }

            final summary = _ctrl.summary!;

            return SafeArea(
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // â”€â”€ 1. Opening Balance Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    DayBookOpeningCard(summary: summary),
                    const SizedBox(height: 12),

                    // â”€â”€ 2. Anomaly Alerts â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    if (summary.anomalies.isNotEmpty) ...[
                      ...summary.anomalies.asMap().entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: AnomalyBanner(
                                alert: e.value,
                                onDismiss: () => _ctrl.dismissAnomaly(e.key),
                              ),
                            ),
                          ),
                      const SizedBox(height: 4),
                    ],

                    // â”€â”€ 3. Cash Inward (GST + Non-GST + others) â”€â”€â”€â”€â”€
                    CashInwardSection(ctrl: _ctrl),
                    const SizedBox(height: 10),

                    // â”€â”€ 4. Cash Outward â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    CashOutwardSection(ctrl: _ctrl),
                    const SizedBox(height: 10),

                    // â”€â”€ 5. Payment Mode Breakup â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    PaymentModeSection(ctrl: _ctrl),
                    const SizedBox(height: 10),

                    // â”€â”€ 6. Metal Inward â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    MetalInwardSection(ctrl: _ctrl),
                    const SizedBox(height: 10),

                    // â”€â”€ 7. Metal Outward â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    MetalOutwardSection(ctrl: _ctrl),
                    const SizedBox(height: 10),

                    // â”€â”€ 8. Net Flow + Closing Balances â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    NetFlowCard(summary: summary),
                    const SizedBox(height: 10),

                    // â”€â”€ 9. Predictive Closing (today only) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    if (_ctrl.isToday && summary.prediction != null) ...[
                      PredictedClosingCard(prediction: summary.prediction!),
                      const SizedBox(height: 10),
                    ],

                    // â”€â”€ 10. GST Summary Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    if (summary.totalGstCollected > 0) ...[
                      _GstSummaryCard(summary: summary),
                      const SizedBox(height: 10),
                    ],

                    // â”€â”€ 11. EOD Button (today only, not locked) â”€â”€â”€â”€â”€â”€
                    if (_ctrl.isToday && !summary.isDayLocked) ...[
                      _EodButton(onTap: _showEodDialog),
                      const SizedBox(height: 16),
                    ],

                    // â”€â”€ 12. Day Locked Banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    if (summary.isDayLocked) ...[
                      _DayLockedBanner(),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// GST Summary Card (quick glance at day's GST)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _GstSummaryCard extends StatelessWidget {
  final summary;
  const _GstSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DayBookColors.gstBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DayBookColors.gstBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        const Icon(DayBookIcons.gstCollected,
            color: DayBookColors.gstAccent, size: 18),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(DayBookStrings.gstCollectedLbl,
              style: DayBookStyles.labelBold
                  .copyWith(color: DayBookColors.gstText)),
          Text('Today\'s total GST liability',
              style: DayBookStyles.labelMuted.copyWith(
                  color: DayBookColors.gstText.withValues(alpha: 0.6))),
        ]),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('â‚¹${summary.totalGstCollected.toStringAsFixed(2)}',
              style: DayBookStyles.amountMedium
                  .copyWith(color: DayBookColors.gstAccent)),
          Text('CGST + SGST', style: DayBookStyles.labelMuted),
        ]),
      ]),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// EOD Button
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _EodButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EodButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1F2937), Color(0xFF111827)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: DayBookColors.brandGold.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: DayBookColors.brandGoldLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: DayBookColors.brandGold.withValues(alpha: 0.4)),
              ),
              child: const Icon(DayBookIcons.eodSettle,
                  color: DayBookColors.brandGold, size: 16),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(DayBookStrings.eodTitle,
                  style: DayBookStyles.appBarTitle.copyWith(fontSize: 14)),
              Text('Count cash & close today\'s ledger',
                  style: DayBookStyles.appBarSub),
            ]),
            const SizedBox(width: 16),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: DayBookColors.brandGold, size: 14),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Day Locked Banner
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _DayLockedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DayBookColors.cashInBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DayBookColors.cashInBorder),
      ),
      child: Row(children: [
        const Icon(DayBookIcons.lockDay,
            color: DayBookColors.cashInAccent, size: 18),
        const SizedBox(width: 10),
        Text(DayBookStrings.dayLocked,
            style: DayBookStyles.labelBold
                .copyWith(color: DayBookColors.cashInText)),
        const Spacer(),
        const Icon(Icons.verified_rounded,
            color: DayBookColors.cashInAccent, size: 16),
      ]),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Error State
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: DayBookColors.cashOutAccent, size: 48),
          const SizedBox(height: 16),
          Text('Something went wrong', style: DayBookStyles.sectionTitle),
          const SizedBox(height: 8),
          Text(message,
              style: DayBookStyles.labelSecondary, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DayBookColors.brandGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Empty State
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(DayBookIcons.moduleIcon,
              color: DayBookColors.textMuted, size: 56),
          const SizedBox(height: 16),
          Text('No transactions recorded',
              style: DayBookStyles.sectionTitle
                  .copyWith(color: DayBookColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Start making sales to see Day Book data',
              style: DayBookStyles.labelSecondary),
        ],
      ),
    );
  }
}
