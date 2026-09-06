import 'package:flutter/material.dart';

import '../../../theme/booking_advance/booking_advance_theme.dart';

class BookingSectionHeader extends StatelessWidget {
  const BookingSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                BookingAdvanceColors.goldGradientStart,
                BookingAdvanceColors.brandGold,
              ],
            ),
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: BookingAdvanceColors.brandGold.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 17),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: BookingAdvanceColors.textDark,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color:
                    BookingAdvanceColors.bodyTextMuted.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
