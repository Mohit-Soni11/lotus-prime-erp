// ============================================================
// FILE    : lib/ui/settings/tax_gst/widgets/tax_gst_field_row.dart
// MODULE  : Tax & GST Configuration
// DESC    : Layout + input widgets.
//           TaxGstFieldRow   → responsive 2-column layout
//           TaxGstInputField → labelled text input
//           TaxGstDropdownRow, TaxGstSectionDivider, TaxGstSaveButton
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/settings/tax_gst/tax_gst_theme.dart';

// =============================================================================
// 1. TWO-COLUMN RESPONSIVE LAYOUT
// Usage:
//   TaxGstFieldRow(children: [fieldA, fieldB])
// =============================================================================
class TaxGstFieldRow extends StatelessWidget {
  const TaxGstFieldRow({
    super.key,
    required this.children,
    this.gap = TaxGstStyles.fieldGapH,
  });

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 520) {
      // Stack vertically on narrow screens (phone)
      return Column(
        children: children
            .expand(
              (child) => [child, SizedBox(height: TaxGstStyles.fieldGapV)],
            )
            .toList()
          ..removeLast(),
      );
    }
    // Side-by-side on tablet/desktop
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children
          .expand((child) => [Expanded(child: child), SizedBox(width: gap)])
          .toList()
        ..removeLast(),
    );
  }
}

// =============================================================================
// 2. LABELLED TEXT INPUT FIELD
// Usage:
//   TaxGstInputField(
//     label: 'GSTIN',
//     hint: '22AAAAA0000A1Z5',
//     controller: _gstinController,
//   )
// NOTE: Sections use TextFormField directly with TaxGstStyles.inputDecoration.
//       Use this widget only for standalone/dark-background contexts.
// =============================================================================
class TaxGstInputField extends StatelessWidget {
  const TaxGstInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.helperText,
    this.isRequired = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLength = 100,
    this.obscureText = false,
    this.suffixIcon,
    this.onChanged,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final String? helperText;
  final bool isRequired;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLength;
  final bool obscureText;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              if (isRequired) ...[
                const SizedBox(width: 4),
                const Text('*',
                    style: TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Input
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLength: maxLength,
            obscureText: obscureText,
            onChanged: onChanged,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 14),
              helperText: helperText,
              helperStyle:
                  GoogleFonts.inter(color: Colors.white38, fontSize: 11),
              suffixIcon: suffixIcon,
              counterText: '',
              filled: true,
              fillColor: const Color(0xFF1A1D27),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFF16A34A), width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 3. DROPDOWN ROW
// =============================================================================
class TaxGstDropdownRow extends StatelessWidget {
  const TaxGstDropdownRow({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isRequired = false,
  });

  final String label;
  final String value;
  final List<String> items;
  final void Function(String?) onChanged;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              if (isRequired) ...[
                const SizedBox(width: 4),
                const Text('*',
                    style: TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            dropdownColor: const Color(0xFF1E2130),
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1A1D27),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFF16A34A), width: 1.5),
              ),
            ),
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white38),
            items: items
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e,
                          style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 14)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 4. SECTION DIVIDER
// =============================================================================
class TaxGstSectionDivider extends StatelessWidget {
  const TaxGstSectionDivider({
    super.key,
    required this.title,
    this.icon,
    this.color = const Color(0xFF16A34A),
  });

  final String title;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
          ],
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(color: color.withOpacity(0.2), thickness: 1),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 5. SAVE BUTTON
// =============================================================================
class TaxGstSaveButton extends StatelessWidget {
  const TaxGstSaveButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.label = 'Save Changes',
  });

  final VoidCallback onPressed;
  final bool isLoading;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF16A34A),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF16A34A).withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
