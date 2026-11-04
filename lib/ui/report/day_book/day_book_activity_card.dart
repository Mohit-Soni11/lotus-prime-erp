import 'package:flutter/material.dart';

import '../../../models/reports/day_book/day_book_smart_summary.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_card_presentation.dart';
import 'day_book_smart_details_dialog.dart';

class DayBookActivityCard extends StatefulWidget {
  const DayBookActivityCard({
    super.key,
    required this.card,
    required this.isDemo,
  });

  final DayBookSmartCard card;
  final bool isDemo;

  @override
  State<DayBookActivityCard> createState() => _DayBookActivityCardState();
}

class _DayBookActivityCardState extends State<DayBookActivityCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final display = DayBookCardPresentation.fromCard(widget.card);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration:
            reducedMotion ? Duration.zero : const Duration(milliseconds: 160),
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [display.gradientStart, display.gradientEnd],
          ),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: _hovered
                ? display.accent.withValues(alpha: 0.55)
                : display.border,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: display.accent.withValues(alpha: 0.12),
                    blurRadius: 13,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => DayBookSmartDetailsDialog(
                card: widget.card,
                isDemo: widget.isDemo,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: display.iconBackground,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child:
                          Icon(display.icon, size: 21, color: display.accent),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            display.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DayBookStyles.labelStrong.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: display.valueColor,
                            ),
                          ),
                          Text(
                            display.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DayBookStyles.valueLarge.copyWith(
                              fontSize: 18,
                              height: 1.12,
                              color: DayBookColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: display.accent),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    display.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DayBookStyles.label.copyWith(
                      fontSize: 10.7,
                      height: 1.18,
                      color: DayBookColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
