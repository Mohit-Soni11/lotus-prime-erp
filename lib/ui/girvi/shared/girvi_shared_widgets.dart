// =============================================================================
// FILE        : girvi_shared_widgets.dart
// MODULE      : Girvi / Pawn
// LAYER       : UI / Shared Components
// NOTE        : All shared widgets in one file. In your project split into:
//               girvi_app_bar.dart, girvi_section_card.dart,
//               girvi_field_widgets.dart, girvi_ticket_card.dart
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../theme/girvi/girvi_theme.dart';
import '../../../models/girvi/girvi_enums.dart';
import '../../../models/girvi/girvi_loan_model.dart';

// =============================================================================
// 1. GIRVI APP BAR
// =============================================================================

class GirviAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String       screenTitle;
  final String       screenSubtitle;
  final VoidCallback onBack;
  final List<Widget>? actions;

  const GirviAppBar({
    super.key,
    required this.screenTitle,
    required this.screenSubtitle,
    required this.onBack,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: GirviStyles.shellDecoration,
      child: SafeArea(
        bottom: false,
        child: Row(children: [
          _HoverBackButton(onTap: onBack),
          const SizedBox(width: 20),
          _VertDivider(),
          const SizedBox(width: 20),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 5, height: 5,
                  decoration: BoxDecoration(
                    color: GirviColors.brandGold,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                      color: GirviColors.brandGold.withOpacity(0.6),
                      blurRadius: 6,
                    )],
                  ),
                ),
                const SizedBox(width: 8),
                Text(screenTitle, style: GirviStyles.shellTitle),
              ]),
              const SizedBox(height: 5),
              const _RadarBadge(),
            ],
          ),
          const Spacer(),
          if (actions != null) ...actions!,
          const SizedBox(width: 10),
          _ModuleBadge(subtitle: screenSubtitle),
        ]),
      ),
    );
  }
}

class _HoverBackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverBackButton({required this.onTap});
  @override
  State<_HoverBackButton> createState() => _HoverBackButtonState();
}

class _HoverBackButtonState extends State<_HoverBackButton> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 42, height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GirviColors.shellBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hovered ? GirviColors.brandGold : GirviColors.shellBorder,
                width: _hovered ? 1.5 : 1.0,
              ),
              boxShadow: [
                if (_hovered)
                  BoxShadow(
                    color: GirviColors.brandGold.withOpacity(0.25),
                    blurRadius: 12, offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Icon(
              GirviIcons.backArrow,
              color: _hovered ? GirviColors.brandGold : GirviColors.shellTextTitle,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 32,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.transparent, GirviColors.shellBorder, Colors.transparent],
      ),
    ),
  );
}

class _RadarBadge extends StatefulWidget {
  const _RadarBadge();
  @override
  State<_RadarBadge> createState() => _RadarBadgeState();
}

class _RadarBadgeState extends State<_RadarBadge>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _ac;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ac = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused || s == AppLifecycleState.inactive) {
      _ac.stop();
    } else if (s == AppLifecycleState.resumed) {
      _ac.repeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ac.dispose();
    super.dispose();
  }

  Widget _wave(double delay, double size) => AnimatedBuilder(
    animation: _ac,
    builder: (_, __) {
      final v = (_ac.value + delay) % 1.0;
      return Opacity(
        opacity: 1.0 - v,
        child: Transform.scale(
          scale: 1.0 + v * 1.5,
          child: Container(
            width: size, height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: GirviColors.onlineGreen.withOpacity(0.5), width: 1.5),
            ),
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) => Row(children: [
    SizedBox(
      width: 14, height: 14,
      child: Stack(alignment: Alignment.center, children: [
        _wave(0.0, 14),
        _wave(0.5, 14),
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            color: GirviColors.onlineGreen,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
              color: GirviColors.onlineGreen,
              blurRadius: 6, spreadRadius: 1,
            )],
          ),
        ),
      ]),
    ),
    const SizedBox(width: 8),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: GirviColors.onlineGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GirviColors.onlineGreen.withOpacity(0.2)),
      ),
      child: Text(GirviStrings.systemOnline,
        style: GoogleFonts.inter(
          color: GirviColors.onlineGreen,
          fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
    ),
  ]);
}

class _ModuleBadge extends StatelessWidget {
  final String subtitle;
  const _ModuleBadge({required this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: GirviColors.moduleBadgeBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: GirviColors.moduleBadgeBorder),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: GirviColors.brandGold.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(GirviIcons.moduleIcon, color: GirviColors.brandGold, size: 14),
      ),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(GirviStrings.moduleBadge,
            style: GoogleFonts.inter(
              color: GirviColors.shellTextTitle,
              fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
          Text(subtitle,
            style: GoogleFonts.inter(
              color: GirviColors.shellTextMuted,
              fontSize: 10, fontWeight: FontWeight.w400)),
        ],
      ),
    ]),
  );
}

// =============================================================================
// 2. SECTION CARD
// =============================================================================

class GirviSectionCard extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   subtitle;
  final Color    accent;
  final Widget   child;

  const GirviSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: GirviStyles.cardWithAccent(accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: GirviColors.divider)),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: GirviStyles.sectionIconBox(accent),
                child: Icon(icon, color: accent, size: 17),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,    style: GirviStyles.sectionTitle),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GirviStyles.caption.copyWith(fontSize: 11)),
                ],
              ),
            ]),
          ),
          // Body
          Padding(
            padding: GirviStyles.cardPadding,
            child: child,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 3. FIELD WIDGETS
// =============================================================================

class GirviInputField extends StatefulWidget {
  final String                    label;
  final String                    hint;
  final IconData                  icon;
  final TextEditingController?    controller;
  final FocusNode?                focusNode;
  final FocusNode?                nextFocus;
  final int                       maxLines;
  final bool                      enabled;
  final String?                   prefixText;
  final String?                   suffixText;
  final Widget?                   suffixWidget;
  final TextInputType?            keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)?    onChanged;

  const GirviInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.controller,
    this.focusNode,
    this.nextFocus,
    this.maxLines    = 1,
    this.enabled     = true,
    this.prefixText,
    this.suffixText,
    this.suffixWidget,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
  });

  @override
  State<GirviInputField> createState() => _GirviInputFieldState();
}

class _GirviInputFieldState extends State<GirviInputField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(GirviInputField old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      old.focusNode?.removeListener(_onFocus);
      widget.focusNode?.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() {
    if (mounted) setState(() => _focused = widget.focusNode?.hasFocus ?? false);
  }

  BoxDecoration get _dec {
    if (!widget.enabled) return GirviStyles.inputDisabled;
    if (_focused)        return GirviStyles.inputFocused;
    return GirviStyles.inputNormal;
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = widget.controller?.text.isNotEmpty ?? false;
    final iconColor  = _focused
        ? GirviColors.brandGold
        : hasContent
            ? GirviColors.success.withOpacity(0.8)
            : GirviColors.textHint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: GirviStyles.fieldLabel),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height:   widget.maxLines > 1 ? null : GirviStyles.inputHeight,
          decoration: _dec,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(widget.icon,
                  key: ValueKey(iconColor), color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Container(width: 1, height: 22, color: GirviColors.cardBorder),
            const SizedBox(width: 10),
            if (widget.prefixText != null)
              Text(widget.prefixText!,
                  style: GirviStyles.fieldInput.copyWith(color: GirviColors.textMuted)),
            Expanded(
              child: TextFormField(
                controller:      widget.controller,
                focusNode:       widget.focusNode,
                maxLines:        widget.maxLines,
                enabled:         widget.enabled,
                keyboardType:    widget.keyboardType,
                inputFormatters: widget.inputFormatters,
                validator:       widget.validator,
                onChanged:       widget.onChanged,
                style:           GirviStyles.fieldInput,
                textInputAction: widget.nextFocus != null
                    ? TextInputAction.next
                    : TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (widget.nextFocus != null) {
                    FocusScope.of(context).requestFocus(widget.nextFocus);
                  }
                },
                decoration: InputDecoration(
                  border:      InputBorder.none,
                  hintText:    widget.hint,
                  hintStyle:   GirviStyles.fieldHint,
                  counterText: '',
                  errorStyle:  const TextStyle(height: 0),
                  suffixText:  widget.suffixText,
                  suffixStyle: GirviStyles.fieldLabel.copyWith(
                      color: GirviColors.textMuted),
                  suffix:      widget.suffixWidget,
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

// ── Dropdown ─────────────────────────────────────────────────────────────────

class GirviDropdown<T> extends StatelessWidget {
  final String             label;
  final IconData           icon;
  final T                  value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;

  const GirviDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GirviStyles.fieldLabel),
        const SizedBox(height: 6),
        Container(
          height: GirviStyles.inputHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: GirviStyles.inputNormal,
          child: Row(children: [
            Icon(icon, color: GirviColors.brandGold, size: 18),
            const SizedBox(width: 10),
            Container(width: 1, height: 22, color: GirviColors.cardBorder),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value:    value,
                  items:    items,
                  onChanged: onChanged,
                  icon:     const Icon(GirviIcons.expandDown,
                      color: GirviColors.textMuted, size: 18),
                  style:    GirviStyles.fieldInput,
                  dropdownColor: GirviColors.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  isExpanded: true,
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

// ── Read-Only Field ───────────────────────────────────────────────────────────

class GirviReadOnlyField extends StatelessWidget {
  final String  label;
  final String  value;
  final Color?  valueColor;
  final bool    highlighted;

  const GirviReadOnlyField({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: highlighted
          ? BoxDecoration(
              color: GirviColors.brandGold.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: GirviColors.brandGold.withOpacity(0.25)),
            )
          : BoxDecoration(
              color: GirviColors.inputBgLocked,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: GirviColors.divider),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GirviStyles.readOnlyLabel),
          const SizedBox(height: 4),
          Text(
            value,
            style: GirviStyles.readOnlyValue.copyWith(
              color: valueColor ?? (highlighted ? GirviColors.brandGold : GirviColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Two-Column Row ────────────────────────────────────────────────────────────

class GirviRowTwo extends StatelessWidget {
  final Widget left;
  final Widget right;
  final double gap;

  const GirviRowTwo({
    super.key,
    required this.left,
    required this.right,
    this.gap = 12,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: left),
      SizedBox(width: gap),
      Expanded(child: right),
    ],
  );
}

// ── Error Banner ──────────────────────────────────────────────────────────────

class GirviErrorBanner extends StatelessWidget {
  final String message;
  const GirviErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: GirviColors.dangerBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: GirviColors.dangerBorder),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, color: GirviColors.danger, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(message,
          style: GoogleFonts.inter(color: GirviColors.danger, fontSize: 13))),
    ]),
  );
}

// =============================================================================
// 4. GIRVI TICKET CARD (for list screen)
// =============================================================================

class GirviTicketCard extends StatelessWidget {
  final GirviLoanWithCustomer data;
  final VoidCallback          onTap;
  final VoidCallback?         onRelease;

  const GirviTicketCard({
    super.key,
    required this.data,
    required this.onTap,
    this.onRelease,
  });

  @override
  Widget build(BuildContext context) {
    final loan     = data.loan;
    final fmt      = NumberFormat('#,##,##0.00', 'en_IN');
    final dateFmt  = DateFormat('dd MMM yyyy');

    final statusColor  = loan.statusColor;
    final statusBg     = loan.statusBgColor;
    final statusLabel  = loan.statusLabel;
    final isActive     = loan.isActive || loan.isOverdue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: GirviColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: statusColor, width: 4),
          ),
          boxShadow: const [
            BoxShadow(color: GirviColors.shadowLight, blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            // ── Header row ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(children: [
                // Ticket icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(GirviIcons.ticket, color: statusColor, size: 16),
                ),
                const SizedBox(width: 12),
                // Ticket number + customer
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loan.ticketNo, style: GirviStyles.ticketNumber),
                      const SizedBox(height: 2),
                      Text(data.customerName,
                          style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: GirviColors.textDark)),
                      Text(data.customerMobile,
                          style: GirviStyles.caption),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(statusLabel,
                      style: GirviStyles.statusBadge.copyWith(color: statusColor)),
                ),
              ]),
            ),

            // ── Divider ────────────────────────────────────────────────────
            Container(height: 1, color: GirviColors.divider),

            // ── Details row ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(children: [
                // Item info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loan.itemDescription,
                          style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w500,
                            color: GirviColors.textBody),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text('${loan.metalType} ${loan.metalPurity} · ${loan.netWeight.toStringAsFixed(2)}g',
                          style: GirviStyles.caption),
                    ],
                  ),
                ),
                // Loan amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${fmt.format(loan.loanAmount)}',
                        style: GoogleFonts.manrope(
                          fontSize: 16, fontWeight: FontWeight.w900,
                          color: GirviColors.textDark)),
                    Text('Loan Amount', style: GirviStyles.caption),
                  ],
                ),
              ]),
            ),

            // ── Footer row (dates + interest) ─────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: GirviColors.bodyBg,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              child: Row(children: [
                // Start date
                _MiniStat(
                  label: 'Start',
                  value: dateFmt.format(loan.startDate),
                  icon:  GirviIcons.dates,
                  color: GirviColors.info,
                ),
                const SizedBox(width: 16),
                // Maturity / release date
                _MiniStat(
                  label: loan.isClosed ? 'Released' : 'Maturity',
                  value: loan.releaseDate != null
                      ? dateFmt.format(loan.releaseDate!)
                      : loan.maturityDate != null
                          ? dateFmt.format(loan.maturityDate!)
                          : 'N/A',
                  icon:  loan.isClosed ? GirviIcons.released : GirviIcons.dates,
                  color: loan.isOverdue ? GirviColors.danger : GirviColors.success,
                ),
                const Spacer(),
                // Accrued interest
                if (isActive) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${fmt.format(loan.accruedInterest)}',
                          style: GoogleFonts.manrope(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: loan.isOverdue ? GirviColors.danger : GirviColors.warning)),
                      Text('Interest Due', style: GirviStyles.caption),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
                // Release button (only for active)
                if (isActive && onRelease != null)
                  GestureDetector(
                    onTap: onRelease,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: GirviColors.success,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(GirviIcons.release, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text('Release',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String  label;
  final String  value;
  final IconData icon;
  final Color   color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 13),
      const SizedBox(width: 4),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GirviStyles.caption.copyWith(fontSize: 10)),
          Text(value, style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: GirviColors.textDark)),
        ],
      ),
    ],
  );
}
