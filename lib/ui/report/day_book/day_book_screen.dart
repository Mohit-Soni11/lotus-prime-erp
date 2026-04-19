// =============================================================================
// FILE        : day_book_screen.dart
// MODULE      : Reports & Analytics → Day Book
// LAYER       : UI — Master Screen Assembly
// DESCRIPTION : Top-level shell connecting all Day Book components.
//               Follows exact same pattern as CashBookScreen.
//
//               LAYOUT:
//               ┌──────────────────────────────────────────────────────────┐
//               │  DARK APP BAR (module title, date nav, export buttons)   │
//               ├──────────────────────────────────────────────────────────┤
//               │  SCROLLABLE BODY (Cream bg)                              │
//               │  ─────────────────────────────────────────────────────── │
//               │  Opening Balance Card (dark)                             │
//               │  Anomaly Alert Banner (if any)                           │
//               │  Cash Inward Section  (expandable)                       │
//               │    └─ GST Bills Sub-section   (teal)                     │
//               │    └─ Non-GST Bills Sub-section (blue)                   │
//               │    └─ Other inflows...                                   │
//               │  Cash Outward Section (expandable, red)                  │
//               │  Payment Mode Breakup (expandable)                       │
//               │  Metal Inward  Section (expandable, amber)               │
//               │  Metal Outward Section (expandable, purple)              │
//               │  Net Flow + Closing Balance Card                         │
//               │  Predicted Closing Card (today only)                     │
//               │  EOD Settlement Button (today only)                      │
//               └──────────────────────────────────────────────────────────┘
//
//               ✅ Dark AppBar + Cream body
//               ✅ ListenableBuilder — zero setState in UI layer
//               ✅ GST and Non-GST bills shown separately
//               ✅ Anomaly detection alerts
//               ✅ EOD denomination dialog + day lock
//               ✅ Export PDF / Excel / WhatsApp
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

  // ── EOD Dialog ─────────────────────────────────────────────────────────────
  void _showEodDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => DayBookEodDialog(ctrl: _ctrl),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: DayBookColors.bodyBg,

        // ── Dark App Bar ──────────────────────────────────────────────
        appBar: DayBookAppBar(
          onBack: widget.onBack ?? () => Navigator.of(context).pop(),
          ctrl: _ctrl,
        ),

        // ── Body ──────────────────────────────────────────────────────
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
                    // ── 1. Opening Balance Card ─────────────────────
                    DayBookOpeningCard(summary: summary),
                    const SizedBox(height: 12),

                    // ── 2. Anomaly Alerts ───────────────────────────
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

                    // ── 3. Cash Inward (GST + Non-GST + others) ─────
                    CashInwardSection(ctrl: _ctrl),
                    const SizedBox(height: 10),

                    // ── 4. Cash Outward ─────────────────────────────
                    CashOutwardSection(ctrl: _ctrl),
                    const SizedBox(height: 10),

                    // ── 5. Payment Mode Breakup ─────────────────────
                    PaymentModeSection(ctrl: _ctrl),
                    const SizedBox(height: 10),

                    // ── 6. Metal Inward ─────────────────────────────
                    MetalInwardSection(ctrl: _ctrl),
                    const SizedBox(height: 10),

                    // ── 7. Metal Outward ────────────────────────────
                    MetalOutwardSection(ctrl: _ctrl),
                    const SizedBox(height: 10),

                    // ── 8. Net Flow + Closing Balances ──────────────
                    NetFlowCard(summary: summary),
                    const SizedBox(height: 10),

                    // ── 9. Predictive Closing (today only) ──────────
                    if (_ctrl.isToday && summary.prediction != null) ...[
                      PredictedClosingCard(prediction: summary.prediction!),
                      const SizedBox(height: 10),
                    ],

                    // ── 10. GST Summary Card ─────────────────────────
                    if (summary.totalGstCollected > 0) ...[
                      _GstSummaryCard(summary: summary),
                      const SizedBox(height: 10),
                    ],

                    // ── 11. EOD Button (today only, not locked) ──────
                    if (_ctrl.isToday && !summary.isDayLocked) ...[
                      _EodButton(onTap: _showEodDialog),
                      const SizedBox(height: 16),
                    ],

                    // ── 12. Day Locked Banner ────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// GST Summary Card (quick glance at day's GST)
// ─────────────────────────────────────────────────────────────────────────────
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
              style: DayBookStyles.labelMuted
                  .copyWith(color: DayBookColors.gstText.withOpacity(0.6))),
        ]),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('₹${summary.totalGstCollected.toStringAsFixed(2)}',
              style: DayBookStyles.amountMedium
                  .copyWith(color: DayBookColors.gstAccent)),
          Text('CGST + SGST', style: DayBookStyles.labelMuted),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EOD Button
// ─────────────────────────────────────────────────────────────────────────────
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
              color: DayBookColors.brandGold.withOpacity(0.2),
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
                border:
                    Border.all(color: DayBookColors.brandGold.withOpacity(0.4)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Day Locked Banner
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// Error State
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(DayBookIcons.moduleIcon,
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
