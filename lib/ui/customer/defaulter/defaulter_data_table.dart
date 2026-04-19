// ==========================================
// FILE: defaulter_data_table.dart
// MODULE: Customer → Defaulter List
// DESCRIPTION: Main data table widget.
//              Shows defaulter rows with risk badges, amounts, actions.
//              Handles: loading shimmer, empty state, hover effects.
// ==========================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/customer/defaulter_model.dart';
import '../../../theme/customer/defaulter/defaulter_theme.dart';
import '../../../logic/customer/defaulter_logic.dart';

class DefaulterDataTable extends StatelessWidget {
  final List<DefaulterModel> defaulters;
  final bool isLoading;
  final String? errorMessage;

  const DefaulterDataTable({
    super.key,
    required this.defaulters,
    required this.isLoading,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Container(
        decoration: DefaulterStyles.tableContainerDecoration,
        child: Column(
          children: [
            // Table Header
            _TableHeader(),

            // Table Body
            Expanded(child: _TableBody(
              defaulters:   defaulters,
              isLoading:    isLoading,
              errorMessage: errorMessage,
            )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// TABLE HEADER
// ─────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: DefaulterStyles.tableHeaderDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _headerCell(DefaulterStrings.colCustomer,  flex: 4),
          _headerCell(DefaulterStrings.colRisk,      flex: 2, center: true),
          _headerCell(DefaulterStrings.colReference, flex: 2),
          _headerCell(DefaulterStrings.colPrincipal, flex: 2, center: true),
          _headerCell(DefaulterStrings.colInterest,  flex: 2, center: true),
          _headerCell(DefaulterStrings.colTotalDue,  flex: 2, center: true),
          _headerCell(DefaulterStrings.colDays,      flex: 2, center: true),
          _headerCell(DefaulterStrings.colActions,   flex: 2, center: true),
        ],
      ),
    );
  }

  Widget _headerCell(String label, {int flex = 1, bool center = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: DefaulterStyles.tableHeader,
      ),
    );
  }
}

// ─────────────────────────────────────────
// TABLE BODY
// ─────────────────────────────────────────

class _TableBody extends StatelessWidget {
  final List<DefaulterModel> defaulters;
  final bool   isLoading;
  final String? errorMessage;

  const _TableBody({
    required this.defaulters,
    required this.isLoading,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _ShimmerRows();
    }

    if (errorMessage != null) {
      return _ErrorState(message: errorMessage!);
    }

    if (defaulters.isEmpty) {
      return const _EmptyState();
    }

    return ListView.builder(
      itemCount:   defaulters.length,
      itemBuilder: (context, index) {
        final defaulter = defaulters[index];
        return _DefaulterRow(
          defaulter: defaulter,
          isAlternate: index.isOdd,
        );
      },
    );
  }
}

// ─────────────────────────────────────────
// DEFAULTER ROW
// ─────────────────────────────────────────

class _DefaulterRow extends StatefulWidget {
  final DefaulterModel defaulter;
  final bool           isAlternate;

  const _DefaulterRow({
    required this.defaulter,
    required this.isAlternate,
  });

  @override
  State<_DefaulterRow> createState() => _DefaulterRowState();
}

class _DefaulterRowState extends State<_DefaulterRow> {
  bool _isHovered = false;

  static final _dateFmt = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final d = widget.defaulter;

    return MouseRegion(
      onEnter:  (_) => setState(() => _isHovered = true),
      onExit:   (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 58,
        decoration: BoxDecoration(
          color: _isHovered
              ? DefaulterColors.tableHoverBg
              : (widget.isAlternate
                  ? DefaulterColors.tableRowAlt
                  : DefaulterColors.bodyPanelBg),
          border: const Border(
            bottom: BorderSide(color: DefaulterColors.tableDivider, width: 0.8),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // --- Customer Info ---
            Expanded(
              flex: 4,
              child: _CustomerCell(
                name:  d.customerName,
                mobile: d.mobile,
                city:   d.city,
                type:   d.customerType,
              ),
            ),

            // --- Risk Badge ---
            Expanded(
              flex: 2,
              child: Center(child: _RiskBadge(level: d.riskLevel)),
            ),

            // --- Reference No ---
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.referenceNo, style: DefaulterStyles.refNumber),
                  Text(
                    _dateFmt.format(d.startDate),
                    style: DefaulterStyles.customerCity,
                  ),
                ],
              ),
            ),

            // --- Principal Amount ---
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  DefaulterLogic.formatAmountCompact(d.principalAmount),
                  style: DefaulterStyles.amountText,
                ),
              ),
            ),

            // --- Interest Accrued ---
            Expanded(
              flex: 2,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DefaulterLogic.formatAmountCompact(d.interestAccrued),
                      style: DefaulterStyles.amountText.copyWith(
                        color: DefaulterColors.riskHighText,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${d.interestRate.toStringAsFixed(1)}${DefaulterStrings.interestRateUnit}',
                      style: DefaulterStyles.interestRate,
                    ),
                  ],
                ),
              ),
            ),

            // --- Total Due ---
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  DefaulterLogic.formatAmountCompact(d.totalDue),
                  style: DefaulterStyles.amountTotalDue,
                ),
              ),
            ),

            // --- Days Overdue ---
            Expanded(
              flex: 2,
              child: Center(child: _DaysOverdueCell(days: d.daysOverdue, level: d.riskLevel)),
            ),

            // --- Action Buttons ---
            Expanded(
              flex: 2,
              child: Center(child: _ActionButtons(mobile: d.mobile)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// CUSTOMER CELL
// ─────────────────────────────────────────

class _CustomerCell extends StatelessWidget {
  final String name;
  final String mobile;
  final String city;
  final String type;

  const _CustomerCell({
    required this.name,
    required this.mobile,
    required this.city,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color:        DefaulterColors.riskCriticalBg,
            shape:        BoxShape.circle,
            border: Border.all(
              color: DefaulterColors.riskCriticalBorder.withOpacity(0.3),
            ),
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize:   15,
                fontWeight: FontWeight.w800,
                color:      DefaulterColors.riskCriticalText,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Name + Mobile + City
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: DefaulterStyles.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (type == 'VIP') ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: DefaulterColors.brandGoldLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'VIP',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: DefaulterColors.brandGoldDark,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '$mobile  •  $city',
                style: DefaulterStyles.customerMobile,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// RISK BADGE
// ─────────────────────────────────────────

class _RiskBadge extends StatelessWidget {
  final DefaulterRiskLevel level;
  const _RiskBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final config = _riskConfig(level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        config.bg,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: config.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: config.dot,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            config.label,
            style: DefaulterStyles.riskBadgeText.copyWith(color: config.text),
          ),
        ],
      ),
    );
  }

  _RiskConfig _riskConfig(DefaulterRiskLevel level) {
    switch (level) {
      case DefaulterRiskLevel.critical:
        return _RiskConfig(
          label:  DefaulterStrings.riskCritical,
          bg:     DefaulterColors.riskCriticalBg,
          border: DefaulterColors.riskCriticalBorder,
          text:   DefaulterColors.riskCriticalText,
          dot:    DefaulterColors.riskCriticalDot,
        );
      case DefaulterRiskLevel.high:
        return _RiskConfig(
          label:  DefaulterStrings.riskHigh,
          bg:     DefaulterColors.riskHighBg,
          border: DefaulterColors.riskHighBorder,
          text:   DefaulterColors.riskHighText,
          dot:    DefaulterColors.riskHighDot,
        );
      case DefaulterRiskLevel.medium:
        return _RiskConfig(
          label:  DefaulterStrings.riskMedium,
          bg:     DefaulterColors.riskMediumBg,
          border: DefaulterColors.riskMediumBorder,
          text:   DefaulterColors.riskMediumText,
          dot:    DefaulterColors.riskMediumDot,
        );
      case DefaulterRiskLevel.low:
        return _RiskConfig(
          label:  DefaulterStrings.riskLow,
          bg:     DefaulterColors.riskLowBg,
          border: DefaulterColors.riskLowBorder,
          text:   DefaulterColors.riskLowText,
          dot:    DefaulterColors.riskLowDot,
        );
    }
  }
}

class _RiskConfig {
  final String label;
  final Color  bg, border, text, dot;
  const _RiskConfig({
    required this.label,
    required this.bg,
    required this.border,
    required this.text,
    required this.dot,
  });
}

// ─────────────────────────────────────────
// DAYS OVERDUE CELL
// ─────────────────────────────────────────

class _DaysOverdueCell extends StatelessWidget {
  final int               days;
  final DefaulterRiskLevel level;

  const _DaysOverdueCell({required this.days, required this.level});

  @override
  Widget build(BuildContext context) {
    final Color textColor = _colorForLevel(level);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          days.toString(),
          style: DefaulterStyles.daysText.copyWith(color: textColor),
        ),
        Text(
          DefaulterStrings.daysOverdueLabel,
          style: DefaulterStyles.daysUnit,
        ),
      ],
    );
  }

  Color _colorForLevel(DefaulterRiskLevel level) {
    switch (level) {
      case DefaulterRiskLevel.critical: return DefaulterColors.riskCriticalText;
      case DefaulterRiskLevel.high:     return DefaulterColors.riskHighText;
      case DefaulterRiskLevel.medium:   return DefaulterColors.riskMediumText;
      case DefaulterRiskLevel.low:      return DefaulterColors.riskLowText;
    }
  }
}

// ─────────────────────────────────────────
// ACTION BUTTONS
// ─────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final String mobile;
  const _ActionButtons({required this.mobile});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Call button
        _ActionBtn(
          icon:    DefaulterIcons.phoneCall,
          color:   DefaulterColors.callBtnBg,
          tooltip: DefaulterStrings.btnCall,
          onTap:   () => _makeCall(context, mobile),
        ),

        const SizedBox(width: 6),

        // Copy mobile number
        _ActionBtn(
          icon:    DefaulterIcons.notify,
          color:   DefaulterColors.notifyBtnBg,
          tooltip: DefaulterStrings.btnNotify,
          onTap:   () => _copyNumber(context, mobile),
        ),
      ],
    );
  }

  void _makeCall(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback: copy number
      await Clipboard.setData(ClipboardData(text: number));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:  Text(DefaulterStrings.copySuccess),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _copyNumber(BuildContext context, String number) async {
    await Clipboard.setData(ClipboardData(text: number));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:  Text(DefaulterStrings.copySuccess),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData    icon;
  final Color       color;
  final String      tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width:  30,
          height: 30,
          decoration: BoxDecoration(
            color:        color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// SHIMMER ROWS (Loading State)
// ─────────────────────────────────────────

class _ShimmerRows extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor:      Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      period:         const Duration(milliseconds: 1200),
      child: ListView.builder(
        itemCount:   8,
        itemBuilder: (_, i) => Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: DefaulterColors.tableDivider, width: 0.8),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:  MainAxisAlignment.center,
                  children: [
                    Container(width: 140, height: 13, color: Colors.white),
                    const SizedBox(height: 5),
                    Container(width: 100, height: 10, color: Colors.white),
                  ],
                ),
              ),
              Container(width: 60, height: 22, color: Colors.white),
              const SizedBox(width: 16),
              Container(width: 70, height: 13, color: Colors.white),
              const SizedBox(width: 16),
              Container(width: 70, height: 13, color: Colors.white),
              const SizedBox(width: 16),
              Container(width: 70, height: 13, color: Colors.white),
              const SizedBox(width: 16),
              Container(width: 70, height: 13, color: Colors.white),
              const SizedBox(width: 16),
              Container(width: 40, height: 13, color: Colors.white),
              const SizedBox(width: 16),
              Container(width: 60, height: 28, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color:  DefaulterColors.riskLowBg,
              shape:  BoxShape.circle,
            ),
            child: const Icon(
              DefaulterIcons.emptyState,
              size:  38,
              color: DefaulterColors.riskLowText,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            DefaulterStrings.emptyTitle,
            style: DefaulterStyles.emptyTitle,
          ),
          const SizedBox(height: 8),
          Text(
            DefaulterStrings.emptySubtitle,
            style:     DefaulterStyles.emptySubtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// ERROR STATE
// ─────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size:  48,
            color: DefaulterColors.riskCriticalText,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style:     DefaulterStyles.emptyTitle.copyWith(
              color: DefaulterColors.riskCriticalText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}