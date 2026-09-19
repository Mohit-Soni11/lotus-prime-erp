part of '../new_girvi_screen.dart';

class _InvoiceCustomerCard extends StatelessWidget {
  final String name;
  final String mobile;
  final bool ready;

  const _InvoiceCustomerCard({
    required this.name,
    required this.mobile,
    required this.ready,
  });

  @override
  Widget build(BuildContext context) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final initials = ready && words.isNotEmpty
        ? words.take(2).map((word) => word[0].toUpperCase()).join()
        : '?';

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: ready
            ? GirviColors.info.withValues(alpha: 0.055)
            : GirviColors.warning.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ready
              ? GirviColors.info.withValues(alpha: 0.18)
              : GirviColors.warning.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ready
                  ? GirviColors.info.withValues(alpha: 0.13)
                  : GirviColors.warning.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              initials,
              style: GoogleFonts.manrope(
                color: ready ? GirviColors.info : GirviColors.warning,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ready ? 'BORROWER' : 'BORROWER REQUIRED',
                  style: GoogleFonts.inter(
                    color: GirviColors.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: GirviColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mobile,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GirviStyles.caption.copyWith(fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ready
                  ? GirviColors.success.withValues(alpha: 0.09)
                  : GirviColors.inputBgLocked,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ready
                    ? GirviColors.success.withValues(alpha: 0.20)
                    : GirviColors.cardBorder,
              ),
            ),
            child: Icon(
              ready ? Icons.lock_rounded : Icons.person_search_outlined,
              color: ready ? GirviColors.success : GirviColors.textHint,
              size: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceAmountHero extends StatelessWidget {
  final String loanAmount;
  final String duration;

  const _InvoiceAmountHero({
    required this.loanAmount,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GirviColors.brandGold.withValues(alpha: 0.14),
            GirviColors.brandGold.withValues(alpha: 0.045),
          ],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: GirviColors.brandGold.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: GirviColors.brandGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  GirviIcons.cash,
                  color: GirviColors.brandDeep,
                  size: 16,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'LOAN TO DISBURSE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.brandDeep,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: GirviColors.cardBg.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: GirviColors.brandGold.withValues(alpha: 0.24),
                  ),
                ),
                child: Text(
                  duration,
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            loanAmount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: GirviColors.textDark,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InvoiceMetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.17)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GirviStyles.caption.copyWith(
              fontSize: 12.5,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: GirviColors.textDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceDetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InvoiceDetailSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 9, 11, 8),
            child: Row(
              children: [
                Icon(icon, color: GirviColors.brandGold, size: 15),
                const SizedBox(width: 7),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: GirviColors.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.75,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: GirviColors.divider),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 11),
                child: Divider(height: 1, color: GirviColors.divider),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _InvoiceDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InvoiceDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: GirviColors.textHint, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GirviStyles.caption.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            flex: 2,
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: GoogleFonts.manrope(
                color: valueColor ?? GirviColors.textDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoicePaymentPart {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InvoicePaymentPart({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _InvoicePaymentBreakdown extends StatelessWidget {
  final List<_InvoicePaymentPart> parts;
  final String totalPaid;
  final String loanAmount;
  final String differenceLabel;
  final bool ready;

  const _InvoicePaymentBreakdown({
    required this.parts,
    required this.totalPaid,
    required this.loanAmount,
    required this.differenceLabel,
    required this.ready,
  });

  @override
  Widget build(BuildContext context) {
    final mixed = parts.length > 1;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: ready
              ? GirviColors.success.withValues(alpha: 0.24)
              : GirviColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: GirviColors.info.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: GirviColors.info,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mixed ? 'MIXED PAYMENT' : 'PAYMENT BREAKDOWN',
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.65,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Automatically detected from entered amounts',
                      style: GirviStyles.caption.copyWith(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: GirviColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: GirviColors.info.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  'AUTO',
                  style: GoogleFonts.inter(
                    color: GirviColors.info,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.45,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (parts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
              decoration: BoxDecoration(
                color: GirviColors.cardBg,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: GirviColors.cardBorder),
              ),
              child: Text(
                'Enter Cash, UPI, Bank or Cheque amount above.',
                textAlign: TextAlign.center,
                style: GirviStyles.caption.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final part in parts) _InvoicePaymentChip(part: part),
              ],
            ),
          const SizedBox(height: 10),
          Container(height: 1, color: GirviColors.divider),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _InvoicePaymentTotal(
                  label: 'Disbursed',
                  value: totalPaid,
                  color: ready ? GirviColors.success : GirviColors.textDark,
                ),
              ),
              Container(
                width: 1,
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: GirviColors.divider,
              ),
              Expanded(
                child: _InvoicePaymentTotal(
                  label: 'Loan Amount',
                  value: loanAmount,
                  color: GirviColors.brandDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: ready
                  ? GirviColors.success.withValues(alpha: 0.08)
                  : GirviColors.warning.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  ready
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: ready ? GirviColors.success : GirviColors.warning,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    ready ? 'Payment total matched' : differenceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: ready ? GirviColors.success : GirviColors.warning,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
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

class _InvoicePaymentChip extends StatelessWidget {
  final _InvoicePaymentPart part;

  const _InvoicePaymentChip({required this.part});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: part.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: part.color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(part.icon, color: part.color, size: 14),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                part.label,
                style: GoogleFonts.inter(
                  color: GirviColors.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                part.value,
                style: GoogleFonts.manrope(
                  color: GirviColors.textDark,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoicePaymentTotal extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InvoicePaymentTotal({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GirviStyles.caption.copyWith(fontSize: 12.5)),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            color: color,
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _InvoiceReadinessCard extends StatelessWidget {
  final bool customerReady;
  final bool itemsReady;
  final bool amountReady;
  final bool paymentReady;
  final bool kycAttached;

  const _InvoiceReadinessCard({
    required this.customerReady,
    required this.itemsReady,
    required this.amountReady,
    required this.paymentReady,
    required this.kycAttached,
  });

  @override
  Widget build(BuildContext context) {
    final allReady = customerReady && itemsReady && amountReady && paymentReady;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: allReady
            ? GirviColors.success.withValues(alpha: 0.055)
            : GirviColors.warning.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: allReady
              ? GirviColors.success.withValues(alpha: 0.20)
              : GirviColors.warning.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allReady ? Icons.verified_rounded : Icons.fact_check_outlined,
                color: allReady ? GirviColors.success : GirviColors.warning,
                size: 16,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  allReady ? 'READY TO CREATE INVOICE' : 'INVOICE CHECKLIST',
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.55,
                  ),
                ),
              ),
              _InvoiceOptionalBadge(
                label: kycAttached ? 'KYC ATTACHED' : 'KYC OPTIONAL',
                active: kycAttached,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _InvoiceCheckChip(label: 'Customer', complete: customerReady),
              _InvoiceCheckChip(label: 'Items', complete: itemsReady),
              _InvoiceCheckChip(label: 'Loan', complete: amountReady),
              _InvoiceCheckChip(label: 'Payment', complete: paymentReady),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceCheckChip extends StatelessWidget {
  final String label;
  final bool complete;

  const _InvoiceCheckChip({
    required this.label,
    required this.complete,
  });

  @override
  Widget build(BuildContext context) {
    final color = complete ? GirviColors.success : GirviColors.textHint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: complete
            ? GirviColors.success.withValues(alpha: 0.09)
            : GirviColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            complete
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              color: complete ? GirviColors.textDark : GirviColors.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceOptionalBadge extends StatelessWidget {
  final String label;
  final bool active;

  const _InvoiceOptionalBadge({
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? GirviColors.success : GirviColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}

class _TicketActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final bool busy;
  final VoidCallback? onTap;

  const _TicketActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    this.busy = false,
    this.onTap,
  });

  @override
  State<_TicketActionButton> createState() => _TicketActionButtonState();
}

class _TicketActionButtonState extends State<_TicketActionButton> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (_hovered == value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hovered == value) return;
      setState(() => _hovered = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final bg = widget.filled
        ? GirviColors.brandGold
        : (_hovered && enabled ? GirviColors.brandGoldLight : Colors.white);
    final fg = widget.filled ? GirviColors.shellBg : GirviColors.brandDeep;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? bg : GirviColors.inputBgLocked,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.filled
                  ? GirviColors.brandGold
                  : GirviColors.brandGold.withValues(alpha: 0.55),
            ),
            boxShadow: widget.filled && enabled
                ? [
                    BoxShadow(
                      color: GirviColors.brandGold.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: widget.busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: GirviColors.shellBg,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, color: fg, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          color: fg,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
