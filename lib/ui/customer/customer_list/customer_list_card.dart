// -----------------------------------------------------------------------------
// FILE: customer_list_card.dart
// MODULE: Customer -> Customer List
// DESCRIPTION: Production customer row with activity, account, and status cues.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../models/customer/customer_enums/customer_list_enums.dart';
import '../../../models/customer/customer_list/customer_list_ui_model.dart';
import '../../../theme/customer/customer_list/customer_list_theme.dart';

class CustomerListCard extends StatefulWidget {
  final CustomerListItemModel customer;
  final VoidCallback? onTap;

  const CustomerListCard({
    super.key,
    required this.customer,
    this.onTap,
  });

  @override
  State<CustomerListCard> createState() => _CustomerListCardState();
}

class _CustomerListCardState extends State<CustomerListCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.004 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: _isHovered
                ? CustomerListStyles.cardDecorationHover
                : CustomerListStyles.cardDecoration,
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  left: 0,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _isHovered ? 5 : 3,
                      color: _activityAccent,
                    ),
                  ),
                ),
                Padding(
                  padding: CustomerListStyles.cardPaddingH,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 880;
                      return compact
                          ? _buildCompactLayout()
                          : _buildWideLayout();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        _buildAvatar(),
        const SizedBox(width: 16),
        Expanded(flex: 5, child: _buildIdentity()),
        const SizedBox(width: 18),
        Expanded(flex: 4, child: _buildActivityPill()),
        const SizedBox(width: 18),
        _buildMetricRail(),
        const SizedBox(width: 12),
        _buildOpenArrow(),
      ],
    );
  }

  Widget _buildCompactLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 14),
            Expanded(child: _buildIdentity()),
            _buildOpenArrow(),
          ],
        ),
        const SizedBox(height: 14),
        _buildActivityPill(),
        const SizedBox(height: 12),
        _buildMetricRail(compact: true),
      ],
    );
  }

  Widget _buildAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: CustomerListStyles.avatarSize,
          height: CustomerListStyles.avatarSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.customer.isVip
                  ? const [
                      CustomerListColors.brandGoldBg,
                      CustomerListColors.vipBadgeBg,
                    ]
                  : const [
                      CustomerListColors.infoBg,
                      CustomerListColors.bodyPanelBg,
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _activityAccent.withValues(alpha: 0.45)),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.customer.initials,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: widget.customer.isVip
                  ? CustomerListColors.brandGoldDark
                  : CustomerListColors.info,
            ),
          ),
        ),
        if (widget.customer.isActiveAccount)
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: CustomerListColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: CustomerListColors.bodyPanelBg,
                  width: 3,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIdentity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                widget.customer.name,
                style: CustomerListStyles.customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _buildTypeBadge(),
            if (widget.customer.hasDue) ...[
              const SizedBox(width: 6),
              _buildSmallBadge(
                "DUE",
                CustomerListColors.dangerBg,
                CustomerListColors.dangerText,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildInlineMeta(
              CustomerListIcons.phone,
              widget.customer.mobile.isEmpty
                  ? "No mobile"
                  : widget.customer.mobile,
            ),
            _buildInlineMeta(
              CustomerListIcons.city,
              widget.customer.city.isEmpty
                  ? CustomerListStrings.noCity
                  : widget.customer.city,
            ),
            _buildInlineMeta(
              CustomerListIcons.calendar,
              "Since ${widget.customer.formattedDate}",
              muted: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityPill() {
    final colors = _activityPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: CustomerListColors.bodyPanelBg.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_activityIcon, size: 17, color: colors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.customer.lastActivityLabel,
                  style: CustomerListStyles.activityLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "${widget.customer.activityAgeLabel} - ${widget.customer.lastActivityDetail}",
                  style: CustomerListStyles.activityMeta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRail({bool compact = false}) {
    final metrics = [
      _MetricTile(
        icon: CustomerListIcons.invoice,
        label: "Invoices",
        value: widget.customer.billCount.toString(),
        accent: CustomerListColors.info,
        background: CustomerListColors.infoBg,
      ),
      _MetricTile(
        icon: CustomerListIcons.due,
        label: "Due",
        value: _formatMoney(widget.customer.dueAmount),
        accent: widget.customer.hasDue
            ? CustomerListColors.danger
            : CustomerListColors.success,
        background: widget.customer.hasDue
            ? CustomerListColors.dangerBg
            : CustomerListColors.successBg,
      ),
      _MetricTile(
        icon: CustomerListIcons.girvi,
        label: "Girvi",
        value: widget.customer.activeGirviCount.toString(),
        accent: CustomerListColors.violet,
        background: CustomerListColors.violetBg,
      ),
      _MetricTile(
        icon: CustomerListIcons.advance,
        label: "Advance",
        value: widget.customer.activeAdvanceCount.toString(),
        accent: CustomerListColors.teal,
        background: CustomerListColors.tealBg,
      ),
    ];

    if (compact) {
      return Wrap(spacing: 8, runSpacing: 8, children: metrics);
    }

    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (int i = 0; i < metrics.length; i++) ...[
        metrics[i],
        if (i != metrics.length - 1) const SizedBox(width: 8),
      ],
    ]);
  }

  Widget _buildOpenArrow() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: _isHovered
            ? CustomerListColors.brandGoldBg
            : CustomerListColors.bodyPanelMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isHovered
              ? CustomerListColors.brandGold
              : CustomerListColors.bodyBorder,
        ),
      ),
      child: Icon(
        CustomerListIcons.arrowRight,
        size: 14,
        color: _isHovered
            ? CustomerListColors.brandGoldDark
            : CustomerListColors.bodyTextSoft,
      ),
    );
  }

  Widget _buildInlineMeta(IconData icon, String text, {bool muted = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 13,
          color: muted
              ? CustomerListColors.bodyTextSoft
              : CustomerListColors.bodyTextMuted,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: muted
              ? CustomerListStyles.customerSince
              : CustomerListStyles.customerDetail,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTypeBadge() {
    final tier = widget.customer.type;
    final Color background;
    final Color foreground;
    final Color border;
    final IconData icon;

    switch (tier) {
      case CustomerType.elite:
        background = CustomerListColors.vipBadgeBg;
        foreground = CustomerListColors.vipBadgeText;
        border = CustomerListColors.vipBadgeBorder;
        icon = CustomerListIcons.vipBadge;
        break;
      case CustomerType.gold:
        background = CustomerListColors.brandGoldBg;
        foreground = CustomerListColors.brandGoldDark;
        border = CustomerListColors.brandGold;
        icon = Icons.star_rounded;
        break;
      case CustomerType.silver:
        background = CustomerListColors.bodyPanelMuted;
        foreground = CustomerListColors.bodyTextMuted;
        border = CustomerListColors.bodyTextSoft;
        icon = Icons.star_half_rounded;
        break;
      case CustomerType.standard:
        background = CustomerListColors.regularBadgeBg;
        foreground = CustomerListColors.regularBadgeText;
        border = CustomerListColors.regularBadgeBorder;
        icon = CustomerListIcons.defaultAvatar;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border.withValues(alpha: 0.75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: foreground),
          const SizedBox(width: 4),
          Text(
            tier.displayLabel.toUpperCase(),
            style: CustomerListStyles.regularBadge.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBadge(String text, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: CustomerListStyles.regularBadge.copyWith(color: foreground),
      ),
    );
  }

  Color get _activityAccent => _activityPalette.accent;

  IconData get _activityIcon {
    switch (widget.customer.lastActivityKind) {
      case CustomerActivityKind.profile:
        return CustomerListIcons.defaultAvatar;
      case CustomerActivityKind.invoice:
        return CustomerListIcons.invoice;
      case CustomerActivityKind.advance:
        return CustomerListIcons.advance;
      case CustomerActivityKind.girvi:
        return CustomerListIcons.girvi;
    }
  }

  _ActivityPalette get _activityPalette {
    switch (widget.customer.lastActivityKind) {
      case CustomerActivityKind.profile:
        return const _ActivityPalette(
          accent: CustomerListColors.brandGold,
          background: CustomerListColors.brandGoldBg,
        );
      case CustomerActivityKind.invoice:
        return const _ActivityPalette(
          accent: CustomerListColors.info,
          background: CustomerListColors.infoBg,
        );
      case CustomerActivityKind.advance:
        return const _ActivityPalette(
          accent: CustomerListColors.teal,
          background: CustomerListColors.tealBg,
        );
      case CustomerActivityKind.girvi:
        return const _ActivityPalette(
          accent: CustomerListColors.violet,
          background: CustomerListColors.violetBg,
        );
    }
  }

  static String _formatMoney(double value) {
    if (value <= 0.01) return "Rs 0";
    if (value >= 10000000)
      return "Rs ${(value / 10000000).toStringAsFixed(1)}Cr";
    if (value >= 100000) return "Rs ${(value / 100000).toStringAsFixed(1)}L";
    if (value >= 1000) return "Rs ${(value / 1000).toStringAsFixed(1)}K";
    return "Rs ${value.toStringAsFixed(0)}";
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final Color background;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(height: 6),
          Text(
            value,
            style: CustomerListStyles.metricValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            label.toUpperCase(),
            style: CustomerListStyles.metricLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActivityPalette {
  final Color accent;
  final Color background;

  const _ActivityPalette({
    required this.accent,
    required this.background,
  });
}
