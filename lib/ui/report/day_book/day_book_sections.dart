// =============================================================================
// FILE        : day_book_sections.dart
// MODULE      : Reports & Analytics → Day Book
// LAYER       : UI
// DESCRIPTION : All expandable body sections:
//               • Opening Balance Card
//               • Anomaly Alert Banner
//               • Cash Inward Section (GST + Non-GST + others)
//               • Cash Outward Section
//               • Payment Mode Breakup
//               • Metal Inward Section
//               • Metal Outward Section
//               • Net Flow / Predicted Closing
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import '../../../logic/report/day_book/day_book_controller.dart';
import '../../../models/reports/day_book/day_book_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
String _fmt(double v) {
  if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)}Cr';
  if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(2)}L';
  if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
  return '₹${v.toStringAsFixed(0)}';
}

String _fmtGrams(double v) => '${v.toStringAsFixed(3)} gms';

// ─────────────────────────────────────────────────────────────────────────────
// Opening Balance Card
// ─────────────────────────────────────────────────────────────────────────────
class DayBookOpeningCard extends StatelessWidget {
  final DayBookSummary summary;
  const DayBookOpeningCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DayBookStyles.openingBalCard,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Cash opening
          Expanded(
              child: _OpeningItem(
            icon: DayBookIcons.openingBal,
            label: DayBookStrings.openingCash,
            value: _fmt(summary.openingCash),
            color: DayBookColors.brandGold,
          )),
          _vDivider(),
          // Gold opening
          Expanded(
              child: _OpeningItem(
            icon: DayBookIcons.goldMetal,
            label: DayBookStrings.openingGold,
            value: _fmtGrams(summary.openingGold.totalGold),
            color: DayBookColors.metalInAccent,
          )),
          _vDivider(),
          // Silver opening
          Expanded(
              child: _OpeningItem(
            icon: DayBookIcons.silverMetal,
            label: DayBookStrings.openingSilver,
            value: _fmtGrams(summary.openingSilver),
            color: DayBookColors.shellMuted,
          )),
          const SizedBox(width: 12),
          // Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: DayBookColors.brandGoldLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              DayBookStrings.openingBal,
              style: TextStyle(
                color: DayBookColors.brandGold,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: DayBookColors.shellBorder,
      );
}

class _OpeningItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _OpeningItem(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: DayBookStyles.labelMuted),
            const SizedBox(height: 2),
            Text(value,
                style: DayBookStyles.appBarTitle.copyWith(
                  color: DayBookColors.shellTitle,
                  fontSize: 16,
                )),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Anomaly Alert Banner
// ─────────────────────────────────────────────────────────────────────────────
class AnomalyBanner extends StatelessWidget {
  final AnomalyAlert alert;
  final VoidCallback onDismiss;
  const AnomalyBanner(
      {super.key, required this.alert, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DayBookStyles.anomalyBanner,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(DayBookIcons.anomaly,
              color: DayBookColors.anomalyIcon, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DayBookStrings.anomalyTitle,
                    style: DayBookStyles.anomalyText),
                const SizedBox(height: 2),
                Text(alert.message,
                    style: DayBookStyles.labelMuted.copyWith(
                      color: DayBookColors.anomalyText.withOpacity(0.8),
                    )),
              ],
            ),
          ),
          TextButton(
            onPressed: onDismiss,
            child: const Text(DayBookStrings.anomalyDismiss,
                style: TextStyle(
                    color: DayBookColors.anomalyIcon,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic Expandable Section Wrapper
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData headerIcon;
  final String title;
  final String subtitle;
  final String totalValue;
  final Color accentColor;
  final Color headerBg;
  final Color headerTextColor;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  const _SectionCard({
    required this.headerIcon,
    required this.title,
    required this.subtitle,
    required this.totalValue,
    required this.accentColor,
    required this.headerBg,
    required this.headerTextColor,
    required this.isExpanded,
    required this.onToggle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          DayBookStyles.sectionCard(borderColor: accentColor.withOpacity(0.3)),
      child: Column(
        children: [
          // Header Row
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: DayBookStyles.sectionHeaderBg(color: headerBg),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(headerIcon, color: accentColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: DayBookStyles.sectionTitle.copyWith(
                              color: headerTextColor,
                            )),
                        Text(subtitle,
                            style: DayBookStyles.sectionSubtitle.copyWith(
                              color: headerTextColor.withOpacity(0.6),
                            )),
                      ],
                    ),
                  ),
                  Text(totalValue,
                      style: DayBookStyles.amountLarge.copyWith(
                        color: accentColor,
                      )),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? DayBookIcons.collapse : DayBookIcons.expand,
                    color: headerTextColor.withOpacity(0.6),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Column(children: [
                    const Divider(height: 1, color: DayBookColors.divider),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: children
                            .map((c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: c,
                                ))
                            .toList(),
                      ),
                    ),
                  ])
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-Row Item (each line inside expanded section)
// ─────────────────────────────────────────────────────────────────────────────
class _SubRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final String value;
  final Widget? badge;

  const _SubRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DayBookStyles.subRowDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(label, style: DayBookStyles.labelPrimary),
                  if (badge != null) ...[const SizedBox(width: 6), badge!],
                ]),
                Text(subtitle, style: DayBookStyles.labelSecondary),
              ],
            ),
          ),
          Text(value, style: DayBookStyles.amountSmall),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CASH INWARD SECTION (with GST / Non-GST split)
// ─────────────────────────────────────────────────────────────────────────────
class CashInwardSection extends StatelessWidget {
  final DayBookController ctrl;
  const CashInwardSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final cashIn = ctrl.summary!.cashIn;

    return _SectionCard(
      headerIcon: DayBookIcons.cashIn,
      title: DayBookStrings.cashInTitle,
      subtitle: DayBookStrings.cashInSubtitle,
      totalValue: _fmt(cashIn.total),
      accentColor: DayBookColors.cashInAccent,
      headerBg: DayBookColors.cashInBg,
      headerTextColor: DayBookColors.cashInText,
      isExpanded: ctrl.cashInExpanded,
      onToggle: ctrl.toggleCashIn,
      children: [
        // ── GST Bills Sub-section ──────────────────────────────────────
        _GstBillSubSection(
          summary: cashIn.gstSales,
          isExpanded: ctrl.gstSectionExpanded,
          onToggle: ctrl.toggleGstSection,
        ),

        // ── Non-GST Bills Sub-section ──────────────────────────────────
        _NonGstBillSubSection(
          summary: cashIn.nonGstSales,
          isExpanded: ctrl.nonGstSectionExpanded,
          onToggle: ctrl.toggleNonGstSection,
        ),

        // ── Other Cash In ──────────────────────────────────────────────
        if (cashIn.dueReceipts > 0)
          _SubRow(
            icon: DayBookIcons.dueReceipts,
            iconColor: DayBookColors.cashInAccent,
            label: DayBookStrings.dueReceipts,
            subtitle: DayBookStrings.dueReceiptsSub,
            value: _fmt(cashIn.dueReceipts),
          ),
        if (cashIn.bookingAdvances > 0)
          _SubRow(
            icon: DayBookIcons.bookingAdv,
            iconColor: DayBookColors.cashInAccent,
            label: DayBookStrings.bookingAdv,
            subtitle: DayBookStrings.bookingAdvSub,
            value: _fmt(cashIn.bookingAdvances),
          ),
        if (cashIn.vendorRefunds > 0)
          _SubRow(
            icon: DayBookIcons.vendorRefund,
            iconColor: DayBookColors.cashInAccent,
            label: DayBookStrings.vendorRefund,
            subtitle: DayBookStrings.vendorRefundSub,
            value: _fmt(cashIn.vendorRefunds),
          ),
        if (cashIn.girviReceipts > 0)
          _SubRow(
            icon: DayBookIcons.girviReceipt,
            iconColor: DayBookColors.cashInAccent,
            label: DayBookStrings.girviReceipt,
            subtitle: DayBookStrings.girviReceiptSub,
            value: _fmt(cashIn.girviReceipts),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GST Bill Sub-Section (nested inside Cash In)
// ─────────────────────────────────────────────────────────────────────────────
class _GstBillSubSection extends StatelessWidget {
  final GstBillSummary summary;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _GstBillSubSection({
    required this.summary,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DayBookColors.gstBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DayBookColors.gstBorder),
      ),
      child: Column(
        children: [
          // GST sub-header
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                const Icon(DayBookIcons.gstBill,
                    color: DayBookColors.gstAccent, size: 15),
                const SizedBox(width: 8),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(DayBookStrings.gstBillSection,
                          style: DayBookStyles.labelBold
                              .copyWith(color: DayBookColors.gstText)),
                      const SizedBox(width: 6),
                      // Bill count badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: DayBookColors.gstAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                            '${summary.billCount} ${DayBookStrings.billCountLbl}',
                            style: DayBookStyles.gstBadge),
                      ),
                    ]),
                    Text(DayBookStrings.gstBillSubtitle,
                        style: DayBookStyles.labelSecondary.copyWith(
                            color: DayBookColors.gstText.withOpacity(0.6))),
                  ],
                )),
                Text(_fmt(summary.totalGstAmount),
                    style: DayBookStyles.amountMedium
                        .copyWith(color: DayBookColors.gstAccent)),
                const SizedBox(width: 4),
                Icon(isExpanded ? DayBookIcons.collapse : DayBookIcons.expand,
                    color: DayBookColors.gstAccent, size: 16),
              ]),
            ),
          ),

          // Expanded GST breakdown
          if (isExpanded) ...[
            Divider(height: 1, color: DayBookColors.gstBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(children: [
                _GstRow(
                    label: DayBookStrings.taxableLbl,
                    value: _fmt(summary.taxableAmount),
                    isMuted: true),
                _GstRow(
                    label: '${DayBookStrings.cgstLbl}',
                    value: _fmt(summary.cgst),
                    isMuted: true),
                _GstRow(
                    label: '${DayBookStrings.sgstLbl}',
                    value: _fmt(summary.sgst),
                    isMuted: true),
                const Divider(height: 12, color: DayBookColors.gstBorder),
                _GstRow(
                  label: DayBookStrings.gstCollectedLbl,
                  value: _fmt(summary.gstCollected),
                  isMuted: false,
                  valueColor: DayBookColors.gstAccent,
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _GstRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMuted;
  final Color? valueColor;
  const _GstRow(
      {required this.label,
      required this.value,
      required this.isMuted,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Text(label,
            style: isMuted
                ? DayBookStyles.labelSecondary
                : DayBookStyles.labelBold
                    .copyWith(color: DayBookColors.gstText)),
        const Spacer(),
        Text(value,
            style: DayBookStyles.amountSmall.copyWith(
              color: valueColor ?? DayBookColors.textDark,
            )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Non-GST Bill Sub-Section
// ─────────────────────────────────────────────────────────────────────────────
class _NonGstBillSubSection extends StatelessWidget {
  final NonGstBillSummary summary;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _NonGstBillSubSection({
    required this.summary,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DayBookColors.nonGstBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DayBookColors.nonGstBorder),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                const Icon(DayBookIcons.nonGstBill,
                    color: DayBookColors.nonGstAccent, size: 15),
                const SizedBox(width: 8),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(DayBookStrings.nonGstBillSection,
                          style: DayBookStyles.labelBold
                              .copyWith(color: DayBookColors.nonGstText)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: DayBookColors.nonGstAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                            '${summary.billCount} ${DayBookStrings.billCountLbl}',
                            style: DayBookStyles.nonGstBadge),
                      ),
                    ]),
                    Text(DayBookStrings.nonGstBillSubtitle,
                        style: DayBookStyles.labelSecondary.copyWith(
                            color: DayBookColors.nonGstText.withOpacity(0.6))),
                  ],
                )),
                Text(_fmt(summary.totalAmount),
                    style: DayBookStyles.amountMedium
                        .copyWith(color: DayBookColors.nonGstAccent)),
                const SizedBox(width: 4),
                Icon(isExpanded ? DayBookIcons.collapse : DayBookIcons.expand,
                    color: DayBookColors.nonGstAccent, size: 16),
              ]),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Row(children: [
                Text('No GST charged on these bills',
                    style: DayBookStyles.labelMuted),
                const Spacer(),
                Text(_fmt(summary.totalAmount),
                    style: DayBookStyles.labelBold
                        .copyWith(color: DayBookColors.nonGstText)),
              ]),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CASH OUTWARD SECTION
// ─────────────────────────────────────────────────────────────────────────────
class CashOutwardSection extends StatelessWidget {
  final DayBookController ctrl;
  const CashOutwardSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final cashOut = ctrl.summary!.cashOut;

    return _SectionCard(
      headerIcon: DayBookIcons.cashOut,
      title: DayBookStrings.cashOutTitle,
      subtitle: DayBookStrings.cashOutSubtitle,
      totalValue: _fmt(cashOut.total),
      accentColor: DayBookColors.cashOutAccent,
      headerBg: DayBookColors.cashOutBg,
      headerTextColor: DayBookColors.cashOutText,
      isExpanded: ctrl.cashOutExpanded,
      onToggle: ctrl.toggleCashOut,
      children: [
        if (cashOut.expenses > 0)
          _SubRow(
              icon: DayBookIcons.expenses,
              iconColor: DayBookColors.cashOutAccent,
              label: DayBookStrings.expenses,
              subtitle: DayBookStrings.expensesSub,
              value: _fmt(cashOut.expenses)),
        if (cashOut.girviGiven > 0)
          _SubRow(
              icon: DayBookIcons.girviGiven,
              iconColor: DayBookColors.cashOutAccent,
              label: DayBookStrings.girviGiven,
              subtitle: DayBookStrings.girviGivenSub,
              value: _fmt(cashOut.girviGiven)),
        if (cashOut.karigarPayments > 0)
          _SubRow(
              icon: DayBookIcons.karigarPay,
              iconColor: DayBookColors.cashOutAccent,
              label: DayBookStrings.karigarPay,
              subtitle: DayBookStrings.karigarPaySub,
              value: _fmt(cashOut.karigarPayments)),
        if (cashOut.vendorPayments > 0)
          _SubRow(
              icon: DayBookIcons.vendorPay,
              iconColor: DayBookColors.cashOutAccent,
              label: DayBookStrings.vendorPay,
              subtitle: DayBookStrings.vendorPaySub,
              value: _fmt(cashOut.vendorPayments)),
        if (cashOut.salesReturns > 0)
          _SubRow(
              icon: DayBookIcons.salesReturn,
              iconColor: DayBookColors.cashOutAccent,
              label: DayBookStrings.salesReturn,
              subtitle: DayBookStrings.salesReturnSub,
              value: _fmt(cashOut.salesReturns)),
        if (cashOut.total == 0)
          const _EmptyRow(message: 'No outflows recorded today'),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAYMENT MODE BREAKUP SECTION
// ─────────────────────────────────────────────────────────────────────────────
class PaymentModeSection extends StatelessWidget {
  final DayBookController ctrl;
  const PaymentModeSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final pm = ctrl.summary!.totalPaymentBreakup;

    return _SectionCard(
      headerIcon: DayBookIcons.upiMode,
      title: DayBookStrings.paymentMode,
      subtitle: DayBookStrings.paymentModeSub,
      totalValue: _fmt(pm.total),
      accentColor: DayBookColors.info,
      headerBg: DayBookColors.nonGstBg,
      headerTextColor: DayBookColors.nonGstText,
      isExpanded: ctrl.paymentExpanded,
      onToggle: ctrl.togglePayment,
      children: [
        _PaymentModeBar(
            label: DayBookStrings.cashMode,
            icon: DayBookIcons.cashMode,
            value: pm.cash,
            color: DayBookColors.cashMode,
            total: pm.total),
        _PaymentModeBar(
            label: DayBookStrings.upiMode,
            icon: DayBookIcons.upiMode,
            value: pm.upi,
            color: DayBookColors.upiMode,
            total: pm.total),
        _PaymentModeBar(
            label: DayBookStrings.cardMode,
            icon: DayBookIcons.cardMode,
            value: pm.card,
            color: DayBookColors.cardMode,
            total: pm.total),
        _PaymentModeBar(
            label: DayBookStrings.bankMode,
            icon: DayBookIcons.bankMode,
            value: pm.bankTransfer,
            color: DayBookColors.bankMode,
            total: pm.total),
      ],
    );
  }
}

class _PaymentModeBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final double total;
  final Color color;

  const _PaymentModeBar(
      {required this.label,
      required this.icon,
      required this.value,
      required this.total,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (value / total * 100) : 0.0;
    return Container(
      decoration: DayBookStyles.subRowDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 10),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(label, style: DayBookStyles.labelPrimary),
              const Spacer(),
              Text(_fmt(value), style: DayBookStyles.amountSmall),
              const SizedBox(width: 6),
              Text('${pct.toStringAsFixed(1)}%',
                  style: DayBookStyles.labelMuted.copyWith(color: color)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? (value / total).clamp(0, 1) : 0,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 5,
              ),
            ),
          ],
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// METAL INWARD SECTION
// ─────────────────────────────────────────────────────────────────────────────
class MetalInwardSection extends StatelessWidget {
  final DayBookController ctrl;
  const MetalInwardSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final mi = ctrl.summary!.metalIn;
    final total = mi.total;

    return _SectionCard(
      headerIcon: DayBookIcons.metalIn,
      title: DayBookStrings.metalInTitle,
      subtitle: DayBookStrings.metalInSubtitle,
      totalValue: '${_fmtGrams(total.totalGold)} Au',
      accentColor: DayBookColors.metalInAccent,
      headerBg: DayBookColors.metalInBg,
      headerTextColor: DayBookColors.metalInText,
      isExpanded: ctrl.metalInExpanded,
      onToggle: ctrl.toggleMetalIn,
      children: [
        if (mi.urdScrapPurchase.totalGold > 0 ||
            mi.urdScrapPurchase.totalSilver > 0)
          _MetalRow(
              icon: DayBookIcons.urdPurchase,
              color: DayBookColors.metalInAccent,
              label: DayBookStrings.urdPurchase,
              subtitle: DayBookStrings.urdPurchaseSub,
              gold22: mi.urdScrapPurchase.gold22k,
              gold18: mi.urdScrapPurchase.gold18k,
              silver: mi.urdScrapPurchase.silver),
        if (mi.karigarFinishedGoods.totalGold > 0)
          _MetalRow(
              icon: DayBookIcons.karigarFinish,
              color: DayBookColors.metalInAccent,
              label: DayBookStrings.karigarFinish,
              subtitle: DayBookStrings.karigarFinishSub,
              gold22: mi.karigarFinishedGoods.gold22k,
              gold18: mi.karigarFinishedGoods.gold18k,
              silver: 0),
        if (mi.girviSecurityDeposit.totalGold > 0)
          _MetalRow(
              icon: DayBookIcons.girviSecurity,
              color: DayBookColors.metalInAccent,
              label: DayBookStrings.girviSecurity,
              subtitle: DayBookStrings.girviSecuritySub,
              gold22: mi.girviSecurityDeposit.gold22k,
              gold18: 0,
              silver: 0),
        if (mi.total.totalGold == 0 && mi.total.totalSilver == 0)
          const _EmptyRow(message: 'No metal received today'),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// METAL OUTWARD SECTION
// ─────────────────────────────────────────────────────────────────────────────
class MetalOutwardSection extends StatelessWidget {
  final DayBookController ctrl;
  const MetalOutwardSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final mo = ctrl.summary!.metalOut;
    final total = mo.total;

    return _SectionCard(
      headerIcon: DayBookIcons.metalOut,
      title: DayBookStrings.metalOutTitle,
      subtitle: DayBookStrings.metalOutSubtitle,
      totalValue: '${_fmtGrams(total.totalGold)} Au',
      accentColor: DayBookColors.metalOutAccent,
      headerBg: DayBookColors.metalOutBg,
      headerTextColor: DayBookColors.metalOutText,
      isExpanded: ctrl.metalOutExpanded,
      onToggle: ctrl.toggleMetalOut,
      children: [
        if (mo.retailDispatch.totalGold > 0 ||
            mo.retailDispatch.totalSilver > 0)
          _MetalRow(
              icon: DayBookIcons.retailDispatch,
              color: DayBookColors.metalOutAccent,
              label: DayBookStrings.retailDispatch,
              subtitle: DayBookStrings.retailDispatchSub,
              gold22: mo.retailDispatch.gold22k,
              gold18: mo.retailDispatch.gold18k,
              silver: mo.retailDispatch.silver),
        if (mo.karigarIssue.totalGold > 0)
          _MetalRow(
              icon: DayBookIcons.karigarIssue,
              color: DayBookColors.metalOutAccent,
              label: DayBookStrings.karigarIssue,
              subtitle: DayBookStrings.karigarIssueSub,
              gold22: mo.karigarIssue.gold22k,
              gold18: mo.karigarIssue.gold18k,
              silver: 0),
        if (mo.total.totalGold == 0 && mo.total.totalSilver == 0)
          const _EmptyRow(message: 'No metal dispatched today'),
      ],
    );
  }
}

class _MetalRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final double gold22;
  final double gold18;
  final double silver;

  const _MetalRow(
      {required this.icon,
      required this.color,
      required this.label,
      required this.subtitle,
      required this.gold22,
      required this.gold18,
      required this.silver});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DayBookStyles.subRowDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 10),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: DayBookStyles.labelPrimary),
            Text(subtitle, style: DayBookStyles.labelSecondary),
            const SizedBox(height: 4),
            Wrap(spacing: 8, children: [
              if (gold22 > 0) _MetalChip('22K: ${_fmtGrams(gold22)}', color),
              if (gold18 > 0) _MetalChip('18K: ${_fmtGrams(gold18)}', color),
              if (silver > 0)
                _MetalChip(
                    'Ag: ${_fmtGrams(silver)}', DayBookColors.metalOutText),
            ]),
          ],
        )),
        Text(_fmtGrams(gold22 + gold18),
            style: DayBookStyles.amountSmall.copyWith(color: color)),
      ]),
    );
  }
}

class _MetalChip extends StatelessWidget {
  final String text;
  final Color color;
  const _MetalChip(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(text,
          style: DayBookStyles.labelMuted.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          )),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Net Flow Summary Card
// ─────────────────────────────────────────────────────────────────────────────
class NetFlowCard extends StatelessWidget {
  final DayBookSummary summary;
  const NetFlowCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final isPositive = summary.netCash >= 0;

    return Container(
      decoration: DayBookStyles.netFlowCard(isPositive: isPositive),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(children: [
            Icon(
              isPositive ? DayBookIcons.trendUp : DayBookIcons.trendDown,
              color: isPositive
                  ? DayBookColors.cashInAccent
                  : DayBookColors.cashOutAccent,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(DayBookStrings.netCashFlow,
                style: DayBookStyles.sectionTitle.copyWith(
                  color: isPositive
                      ? DayBookColors.cashInText
                      : DayBookColors.cashOutText,
                )),
            const Spacer(),
            Text(_fmt(summary.netCash.abs()),
                style: DayBookStyles.amountLarge.copyWith(
                  color: isPositive
                      ? DayBookColors.cashInAccent
                      : DayBookColors.cashOutAccent,
                )),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1, color: DayBookColors.divider),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _ClosingItem(
              label: DayBookStrings.closingCash,
              value: _fmt(summary.closingCash),
              color: isPositive
                  ? DayBookColors.cashInAccent
                  : DayBookColors.cashOutAccent,
            )),
            Expanded(
                child: _ClosingItem(
              label: DayBookStrings.closingGold,
              value: _fmtGrams(summary.closingGold),
              color: DayBookColors.metalInAccent,
            )),
            Expanded(
                child: _ClosingItem(
              label: DayBookStrings.closingSilver,
              value: _fmtGrams(summary.closingSilver),
              color: DayBookColors.shellMuted,
            )),
          ]),
        ],
      ),
    );
  }
}

class _ClosingItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ClosingItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: DayBookStyles.labelMuted),
        const SizedBox(height: 4),
        Text(value, style: DayBookStyles.amountSmall.copyWith(color: color)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Predicted Closing Card
// ─────────────────────────────────────────────────────────────────────────────
class PredictedClosingCard extends StatelessWidget {
  final PredictedClosing prediction;
  const PredictedClosingCard({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DayBookStyles.sectionCard(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        const Icon(DayBookIcons.predict,
            color: DayBookColors.brandGold, size: 20),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(DayBookStrings.predictTitle,
              style: DayBookStyles.labelBold
                  .copyWith(color: DayBookColors.textDark)),
          Text(DayBookStrings.predictSub, style: DayBookStyles.labelMuted),
        ]),
        const Spacer(),
        Text(_fmt(prediction.predictedCash), style: DayBookStyles.amountGold),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State Row
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyRow extends StatelessWidget {
  final String message;
  const _EmptyRow({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Text(message, style: DayBookStyles.labelMuted),
    );
  }
}
