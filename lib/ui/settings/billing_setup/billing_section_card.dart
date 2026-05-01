// =============================================================================
// FILE        : lib/ui/settings/billing_setup/widgets/billing_section_card.dart
// MODULE      : Billing Setup
// LAYER       : Presentation / Reusable Widgets
// DESCRIPTION : Section card with lock / edit / save toggle — used by all 4
//               billing tabs. Pattern matches BasicInfoTab's _buildThemeCard.
//               Also contains all reusable field widgets:
//               BillingInputField, BillingDropdownField,
//               BillingToggleRow, BillingSectionLabel.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/settings/billing_setup/billing_setup_theme.dart';

// ═════════════════════════════════════════════════════════════════════════════
// SECTION CARD
// ═════════════════════════════════════════════════════════════════════════════
class BillingSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData sectionIcon;
  final Color accentColor;
  final bool isLocked;
  final bool isLoading;
  final bool isVerified;
  final VoidCallback onToggle;
  final List<Widget> children;

  const BillingSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.sectionIcon,
    required this.accentColor,
    required this.isLocked,
    required this.isLoading,
    required this.onToggle,
    this.isVerified = false,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BillingSetupStyles.sectionCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          _buildHeader(),

          // ── Body (fields) ────────────────────────────────────────────────
          if (!isLocked)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),

          // ── Locked preview ───────────────────────────────────────────────
          if (isLocked) _buildLockedPreview(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.04),
        borderRadius: isLocked
            ? BorderRadius.circular(BillingSetupStyles.rCard)
            : const BorderRadius.only(
                topLeft: Radius.circular(BillingSetupStyles.rCard),
                topRight: Radius.circular(BillingSetupStyles.rCard),
              ),
        border: isLocked
            ? null
            : Border(
                bottom: BorderSide(
                  color: BillingSetupColors.cardBorder,
                  width: 1,
                ),
              ),
      ),
      child: Row(
        children: [
          // Section icon box
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BillingSetupStyles.sectionIconBox(accentColor),
            child: Icon(sectionIcon, size: 16, color: accentColor),
          ),
          const SizedBox(width: 12),

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: BillingSetupStyles.sectionTitle),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: BillingSetupColors.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // Saved badge
          if (isVerified && isLocked) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration:
                  BillingSetupStyles.statusPill(BillingSetupColors.success),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    BillingSetupIcons.statusActive,
                    size: 7,
                    color: BillingSetupColors.statusActiveText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'SAVED',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: BillingSetupColors.statusActiveText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Edit / Save / Loading toggle
          _buildToggle(),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: accentColor,
        ),
      );
    }
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isLocked
              ? accentColor.withOpacity(0.10)
              : BillingSetupColors.success.withOpacity(0.10),
          borderRadius: BorderRadius.circular(BillingSetupStyles.rBtn),
          border: Border.all(
            color: isLocked
                ? accentColor.withOpacity(0.3)
                : BillingSetupColors.success.withOpacity(0.3),
          ),
        ),
        child: Icon(
          isLocked ? Icons.edit_rounded : BillingSetupIcons.save,
          size: 16,
          color: isLocked ? accentColor : BillingSetupColors.saveBtn,
        ),
      ),
    );
  }

  Widget _buildLockedPreview() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          Icon(
            BillingSetupIcons.lock,
            size: 13,
            color: BillingSetupColors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            'Tap the edit icon to modify this section',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: BillingSetupColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SECTION LABEL — "INVOICE NUMBERING" sub-header
// ═════════════════════════════════════════════════════════════════════════════
class BillingSectionLabel extends StatelessWidget {
  final String text;
  const BillingSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Text(text, style: BillingSetupStyles.sectionLabel),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BILLING INPUT FIELD
// ═════════════════════════════════════════════════════════════════════════════
class BillingInputField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final Color brandColor;
  final TextEditingController ctrl;
  final bool isLocked;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;

  const BillingInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.brandColor,
    required this.ctrl,
    required this.isLocked,
    this.focusNode,
    this.nextFocus,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  State<BillingInputField> createState() => _BillingInputFieldState();
}

class _BillingInputFieldState extends State<BillingInputField> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(() {
      if (mounted) {
        setState(() => _isFocused = widget.focusNode!.hasFocus);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label ──────────────────────────────────────────────────────────
        Row(
          children: [
            Icon(widget.icon, size: 13, color: widget.brandColor),
            const SizedBox(width: 6),
            Text(widget.label, style: BillingSetupStyles.fieldLabel),
          ],
        ),
        const SizedBox(height: 6),

        // ── Input ──────────────────────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: _isFocused && !widget.isLocked
              ? BillingSetupStyles.inputActive
              : BillingSetupStyles.inputDecoration(widget.isLocked),
          child: TextFormField(
            controller: widget.ctrl,
            focusNode: widget.focusNode,
            enabled: !widget.isLocked,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            validator: widget.validator,
            onChanged: widget.onChanged,
            maxLines: widget.maxLines,
            onFieldSubmitted: (_) {
              if (widget.nextFocus != null) {
                FocusScope.of(context).requestFocus(widget.nextFocus);
              }
            },
            style: BillingSetupStyles.fieldInput,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: BillingSetupStyles.fieldHint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BILLING DROPDOWN FIELD
// ═════════════════════════════════════════════════════════════════════════════
class BillingDropdownField extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color brandColor;
  final String value;
  final List<String> items;
  final bool isLocked;
  final ValueChanged<String?> onChanged;

  const BillingDropdownField({
    super.key,
    required this.label,
    required this.icon,
    required this.brandColor,
    required this.value,
    required this.items,
    required this.isLocked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: brandColor),
            const SizedBox(width: 6),
            Text(label, style: BillingSetupStyles.fieldLabel),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: BillingSetupStyles.dropdownHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BillingSetupStyles.inputDecoration(isLocked),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(
                BillingSetupIcons.dropDown,
                color: isLocked
                    ? BillingSetupColors.textHint
                    : BillingSetupColors.textBody,
              ),
              style: BillingSetupStyles.fieldInput,
              onChanged: isLocked ? null : onChanged,
              items: items
                  .map((item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BILLING TOGGLE ROW
// ═════════════════════════════════════════════════════════════════════════════
class BillingToggleRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final bool value;
  final bool isLocked;
  final ValueChanged<bool> onChanged;

  const BillingToggleRow({
    super.key,
    required this.label,
    this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.value,
    required this.isLocked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: subtitle != null ? 62 : BillingSetupStyles.inputHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BillingSetupStyles.inputDecoration(isLocked),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: BillingSetupStyles.fieldLabel),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: BillingSetupColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: isLocked ? null : onChanged,
            activeColor: accentColor,
          ),
        ],
      ),
    );
  }
}
