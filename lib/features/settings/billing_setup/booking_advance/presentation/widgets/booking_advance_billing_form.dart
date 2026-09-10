import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../../models/setting/billing_setup/booking_advance_billing_model.dart';
import '../../../../../../../theme/settings/billing_setup/billing_setup_colors.dart';
import '../../domain/booking_advance_billing_input.dart';
import 'booking_advance_billing_section_card.dart';
import 'booking_advance_billing_toggle_tile.dart';

class BookingAdvanceBillingForm extends StatelessWidget {
  final BookingAdvanceBillingModel model;
  final BookingAdvanceBillingInput input;
  final TextEditingController termsController;
  final TextEditingController footerController;
  final ValueChanged<BookingAdvanceBillingInput> onInputChanged;
  final ValueChanged<bool> onPrintTermsChanged;
  final ValueChanged<bool> onPrintFooterChanged;

  const BookingAdvanceBillingForm({
    super.key,
    required this.model,
    required this.input,
    required this.termsController,
    required this.footerController,
    required this.onInputChanged,
    required this.onPrintTermsChanged,
    required this.onPrintFooterChanged,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF0F766E);

    return Column(
      children: [
        BookingAdvanceBillingSectionCard(
          title: 'Bilingual Terms & Footer',
          subtitle:
              'English and Hindi customer copy printed line by line on the receipt',
          icon: Icons.article_outlined,
          accent: accent,
          child: _TermsAndFooterFields(
            model: model,
            input: input,
            accent: accent,
            termsController: termsController,
            footerController: footerController,
            onInputChanged: onInputChanged,
            onPrintTermsChanged: onPrintTermsChanged,
            onPrintFooterChanged: onPrintFooterChanged,
          ),
        ),
      ],
    );
  }
}

class _TermsAndFooterFields extends StatelessWidget {
  final BookingAdvanceBillingModel model;
  final BookingAdvanceBillingInput input;
  final Color accent;
  final TextEditingController termsController;
  final TextEditingController footerController;
  final ValueChanged<BookingAdvanceBillingInput> onInputChanged;
  final ValueChanged<bool> onPrintTermsChanged;
  final ValueChanged<bool> onPrintFooterChanged;

  const _TermsAndFooterFields({
    required this.model,
    required this.input,
    required this.accent,
    required this.termsController,
    required this.footerController,
    required this.onInputChanged,
    required this.onPrintTermsChanged,
    required this.onPrintFooterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ResponsiveGrid(
          minTileWidth: 255,
          children: [
            BookingAdvanceBillingToggleTile(
              label: 'Print Terms',
              description: 'Include booking terms text on generated receipts.',
              value: model.printTermsAndConditions,
              accent: accent,
              onChanged: onPrintTermsChanged,
            ),
            BookingAdvanceBillingToggleTile(
              label: 'Print Footer',
              description: 'Include the final customer message at the bottom.',
              value: model.printFooterMessage,
              accent: accent,
              onChanged: onPrintFooterChanged,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _TextInput(
          label: 'Terms & Conditions',
          helper: 'Use one clear English or Hindi policy line per row.',
          hintText:
              'Final billing will be prepared at delivery according to final item weight and applicable rate.',
          controller: termsController,
          maxLines: 9,
          onChanged: (value) => onInputChanged(
            input.copyWith(termsAndConditions: value),
          ),
        ),
        const SizedBox(height: 14),
        _TextInput(
          label: 'Footer Message',
          helper: 'Short customer acknowledgement printed after totals.',
          hintText: 'Please keep this booking receipt safely.',
          controller: footerController,
          maxLines: 4,
          onChanged: (value) => onInputChanged(
            input.copyWith(footerMessage: value),
          ),
        ),
      ],
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  final double minTileWidth;
  final List<Widget> children;

  const _ResponsiveGrid({
    required this.minTileWidth,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= minTileWidth * 3 + 32
            ? 3
            : width >= minTileWidth * 2 + 16
                ? 2
                : 1;
        final spacing = columns == 1 ? 0.0 : 12.0;
        final tileWidth = (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: 12,
          children: [
            for (final child in children)
              SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}

class _TextInput extends StatelessWidget {
  final String label;
  final String helper;
  final String? hintText;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final int maxLines;

  const _TextInput({
    required this.label,
    required this.helper,
    required this.controller,
    required this.onChanged,
    this.hintText,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: label,
      helper: helper,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: onChanged,
        style: GoogleFonts.inter(
          color: BillingSetupColors.textDark,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
        decoration: _inputDecoration(hintText: hintText),
      ),
    );
  }
}

class _FieldShell extends StatelessWidget {
  final String label;
  final String helper;
  final Widget child;

  const _FieldShell({
    required this.label,
    required this.helper,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BillingSetupColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: BillingSetupColors.textDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            helper,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: BillingSetupColors.textMuted,
              fontSize: 11.5,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration({
  String? hintText,
}) {
  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    hintStyle: GoogleFonts.inter(
      color: BillingSetupColors.textMuted.withValues(alpha: 0.58),
      fontSize: 12,
      height: 1.35,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFDCE3EA)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFDCE3EA)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.4),
    ),
  );
}
