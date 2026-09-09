part of '../booking_customer_panel.dart';

class _NoCustomerMatch extends StatelessWidget {
  final BookingAdvanceController ctrl;

  const _NoCustomerMatch({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final mobile = ctrl.mobileCtrl.text.trim();
    final name = ctrl.nameCtrl.text.trim();
    final lookupText = mobile.isNotEmpty ? 'Mobile: $mobile' : 'Name: $name';

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: BookingAdvanceColors.brandGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.person_search_rounded,
                  color: BookingAdvanceColors.goldHoverDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No Customer Match',
                      style: TextStyle(
                        color: BookingAdvanceColors.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Use Create Customer to register this buyer.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: BookingAdvanceColors.bodyTextMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: BookingAdvanceColors.formInputBg.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: BookingAdvanceColors.bodyBorder.withValues(alpha: 0.8),
              ),
            ),
            child: Text(
              lookupText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: BookingAdvanceColors.textDark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchTile extends StatefulWidget {
  final Map<String, dynamic> customer;
  final VoidCallback onTap;
  const _SearchTile({required this.customer, required this.onTap});
  @override
  State<_SearchTile> createState() => _SearchTileState();
}

class _SearchTileState extends State<_SearchTile> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final address =
        (widget.customer['address'] ?? widget.customer['city'] ?? '')
            .toString()
            .trim();
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: _h ? const Color(0xFFFAF6EC) : Colors.transparent,
            child: Row(children: [
              const Icon(BookingAdvanceIcons.profile,
                  color: BookingAdvanceColors.brandGold, size: 18),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(widget.customer['name'] ?? '',
                        style: const TextStyle(
                            color: BookingAdvanceColors.textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                    Text(
                        '${widget.customer['mobile'] ?? ''}${address.isNotEmpty ? "  |  $address" : ""}',
                        style: const TextStyle(
                            color: BookingAdvanceColors.bodyTextMuted,
                            fontSize: 12)),
                  ])),
            ])),
      ),
    );
  }
}

class _HoverBtn extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;
  const _HoverBtn(
      {required this.title,
      required this.icon,
      required this.isPrimary,
      required this.onTap});
  @override
  State<_HoverBtn> createState() => _HoverBtnState();
}

class _HoverBtnState extends State<_HoverBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _h ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 42,
            width: 184,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: widget.isPrimary
                  ? LinearGradient(colors: [
                      _h
                          ? BookingAdvanceColors.goldGradientStart
                          : BookingAdvanceColors.brandGold,
                      _h
                          ? BookingAdvanceColors.brandGold
                          : BookingAdvanceColors.goldHoverDark,
                    ], begin: Alignment.topLeft, end: Alignment.bottomRight)
                  : null,
              color: widget.isPrimary
                  ? null
                  : (_h
                      ? BookingAdvanceColors.bodyPanelBg
                      : BookingAdvanceColors.formInputBg),
              border: widget.isPrimary
                  ? null
                  : Border.all(
                      color: _h
                          ? BookingAdvanceColors.brandGold
                          : BookingAdvanceColors.bodyBorder,
                      width: _h ? 1.5 : 1.0),
              boxShadow: [
                if (widget.isPrimary)
                  BoxShadow(
                      color: BookingAdvanceColors.brandGold
                          .withValues(alpha: _h ? 0.6 : 0.4),
                      blurRadius: _h ? 16 : 10,
                      offset: const Offset(0, 4))
                else if (_h)
                  BoxShadow(
                      color: BookingAdvanceColors.brandGold
                          .withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(widget.icon,
                    size: 16,
                    color: widget.isPrimary
                        ? Colors.white
                        : (_h
                            ? BookingAdvanceColors.goldHoverDark
                            : BookingAdvanceColors.textDark)),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: widget.isPrimary
                              ? Colors.white
                              : (_h
                                  ? BookingAdvanceColors.goldHoverDark
                                  : BookingAdvanceColors.textDark),
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
