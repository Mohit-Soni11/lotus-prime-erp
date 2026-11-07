import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/reports/day_book/day_book_theme.dart';

class DayBookFormVisuals {
  const DayBookFormVisuals._();

  static Widget themed({required Widget child}) {
    final base = DayBookStyles.theme;
    return Theme(
      data: base.copyWith(
        inputDecorationTheme: base.inputDecorationTheme.copyWith(
          labelStyle: DayBookStyles.labelStrong,
          floatingLabelStyle: DayBookStyles.labelStrong
              .copyWith(color: DayBookColors.goldMetal),
          prefixStyle: DayBookStyles.labelStrong,
          hintStyle:
              DayBookStyles.label.copyWith(color: DayBookColors.textSecondary),
          fillColor: DayBookColors.bodySubtle,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: DayBookColors.textPrimary,
            textStyle: DayBookStyles.button,
          ),
        ),
      ),
      child: child,
    );
  }

  static ShapeBorder get dialogShape => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: DayBookColors.bodyBorder),
      );

  static Widget heading({
    required String title,
    required String subtitle,
    required IconData icon,
  }) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: DayBookColors.brandGoldSoft,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: DayBookColors.brandGoldBorder),
            ),
            child: Icon(icon, color: DayBookColors.goldMetal, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: DayBookStyles.sectionTitle.copyWith(fontSize: 20)),
                const SizedBox(height: 3),
                Text(subtitle, style: DayBookStyles.label),
              ],
            ),
          ),
        ],
      );

  static Widget contextStrip({required DateTime date, String? mode}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: DayBookStyles.softPanel(
          color: DayBookColors.brandGoldSoft,
          borderColor: DayBookColors.brandGoldBorder,
        ),
        child: Wrap(
          spacing: 18,
          runSpacing: 6,
          children: [
            _metadata(Icons.calendar_today_outlined,
                DateFormat('d MMM yyyy').format(date)),
            if (mode != null) _metadata(Icons.payments_outlined, mode),
          ],
        ),
      );

  static Widget _metadata(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: DayBookColors.goldMetal),
          const SizedBox(width: 7),
          Text(label, style: DayBookStyles.labelStrong),
        ],
      );

  static Widget note(String message) => Container(
        padding: const EdgeInsets.all(12),
        decoration: DayBookStyles.softPanel(
          color: DayBookColors.informationSoft,
          borderColor: DayBookColors.informationBorder,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded,
                color: DayBookColors.information, size: 18),
            const SizedBox(width: 9),
            Expanded(child: Text(message, style: DayBookStyles.label)),
          ],
        ),
      );

  static InputDecoration field(String label, IconData icon,
          {String? prefixText}) =>
      InputDecoration(
        labelText: label,
        prefixText: prefixText,
        prefixIcon: Icon(icon, color: DayBookColors.goldMetal, size: 19),
      );
}
