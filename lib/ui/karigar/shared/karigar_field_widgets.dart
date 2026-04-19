// =============================================================================
// FILE        : karigar_field_widgets.dart
// MODULE      : Karigar
// LAYER       : UI / Shared Components
// DESCRIPTION : Reusable form field widgets for all Karigar module screens.
//               KarigarInputField, KarigarDropdown, KarigarReadOnlyField,
//               KarigarDisabledField, KarigarRowTwo, KarigarErrorBanner.
//               All widgets are stateless or use minimal state for focus only.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/karigar/karigar_theme.dart';

// =============================================================================
// 1. INPUT FIELD
// =============================================================================

class KarigarInputField extends StatefulWidget {
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

  const KarigarInputField({
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
  State<KarigarInputField> createState() => _KarigarInputFieldState();
}

class _KarigarInputFieldState extends State<KarigarInputField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(KarigarInputField old) {
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

  BoxDecoration get _decoration {
    if (!widget.enabled) return KarigarStyles.inputDisabled;
    if (_focused)        return KarigarStyles.inputFocused;
    return KarigarStyles.inputNormal;
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = widget.controller?.text.isNotEmpty ?? false;
    final iconColor  = _focused
        ? KarigarColors.brandGold
        : hasContent
            ? KarigarColors.success.withOpacity(0.8)
            : KarigarColors.textHint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: KarigarStyles.fieldLabel),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height:   widget.maxLines > 1 ? null : KarigarStyles.inputHeight,
          decoration: _decoration,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(widget.icon,
                  key: ValueKey(iconColor), color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Container(width: 1, height: 22, color: KarigarColors.cardBorder),
            const SizedBox(width: 10),
            if (widget.prefixText != null)
              Text(widget.prefixText!,
                  style: KarigarStyles.fieldInput.copyWith(color: KarigarColors.textMuted)),
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
                style:           KarigarStyles.fieldInput,
                textInputAction: widget.nextFocus != null
                    ? TextInputAction.next
                    : TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (widget.nextFocus != null) {
                    FocusScope.of(context).requestFocus(widget.nextFocus);
                  }
                },
                decoration: InputDecoration(
                  border:         InputBorder.none,
                  hintText:       widget.hint,
                  hintStyle:      KarigarStyles.fieldHint,
                  counterText:    '',
                  errorStyle:     const TextStyle(height: 0),
                  suffixText:     widget.suffixText,
                  suffixStyle:    KarigarStyles.fieldInput.copyWith(color: KarigarColors.textMuted),
                  contentPadding: widget.maxLines > 1
                      ? const EdgeInsets.symmetric(vertical: 14)
                      : const EdgeInsets.only(bottom: 2),
                ),
              ),
            ),
            if (widget.suffixWidget != null) ...[
              const SizedBox(width: 6),
              widget.suffixWidget!,
            ],
          ]),
        ),
      ],
    );
  }
}

// =============================================================================
// 2. DROPDOWN
// =============================================================================

class KarigarDropdown<T> extends StatelessWidget {
  final String             label;
  final IconData           icon;
  final T                  value;
  final List<T>            items;
  final String Function(T) itemLabel;
  final void Function(T?)  onChanged;

  const KarigarDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: KarigarStyles.fieldLabel),
        const SizedBox(height: 6),
        Container(
          height: KarigarStyles.dropdownHeight,
          decoration: KarigarStyles.inputNormal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(children: [
            Icon(icon, color: KarigarColors.textHint, size: 18),
            const SizedBox(width: 10),
            Container(width: 1, height: 22, color: KarigarColors.cardBorder),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value:         value,
                  isExpanded:    true,
                  dropdownColor: KarigarColors.cardBg,
                  icon: const Icon(KarigarIcons.dropDown,
                      color: KarigarColors.textMuted, size: 20),
                  style:         KarigarStyles.fieldInput,
                  items: items.map((item) =>
                    DropdownMenuItem<T>(
                      value: item,
                      child: Text(itemLabel(item),
                          style: KarigarStyles.fieldInput,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ).toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

// =============================================================================
// 3. READ-ONLY VALUE BOX
// =============================================================================

class KarigarReadOnlyField extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;
  final String?  note;

  const KarigarReadOnlyField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: KarigarStyles.fieldLabel),
        const SizedBox(height: 6),
        Container(
          height: KarigarStyles.inputHeight,
          decoration: KarigarStyles.readOnlyBox(color),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Container(width: 1, height: 22, color: color.withOpacity(0.25)),
            const SizedBox(width: 10),
            Text(value, style: KarigarStyles.readOnlyValue.copyWith(color: color)),
          ]),
        ),
        if (note != null) ...[
          const SizedBox(height: 4),
          Text(note!, style: KarigarStyles.caption),
        ],
      ],
    );
  }
}

// =============================================================================
// 4. DISABLED FIELD
// =============================================================================

class KarigarDisabledField extends StatelessWidget {
  final String   label;
  final IconData icon;
  final String   value;

  const KarigarDisabledField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: KarigarStyles.fieldLabel),
        const SizedBox(height: 6),
        Container(
          height: KarigarStyles.inputHeight,
          decoration: KarigarStyles.inputDisabled,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(children: [
            Icon(icon, color: KarigarColors.textHint, size: 18),
            const SizedBox(width: 10),
            Container(width: 1, height: 22, color: KarigarColors.cardBorder),
            const SizedBox(width: 10),
            Text(value, style: KarigarStyles.fieldHint.copyWith(fontSize: 13)),
          ]),
        ),
      ],
    );
  }
}

// =============================================================================
// 5. TWO-COLUMN ROW HELPER
// =============================================================================

class KarigarRowTwo extends StatelessWidget {
  final Widget left;
  final Widget right;
  const KarigarRowTwo({super.key, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
    );
  }
}

// =============================================================================
// 6. ERROR BANNER
// =============================================================================

class KarigarErrorBanner extends StatelessWidget {
  final String       message;
  final VoidCallback onDismiss;
  const KarigarErrorBanner({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color:  KarigarColors.dangerBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KarigarColors.danger.withOpacity(0.4)),
      ),
      child: Row(children: [
        Icon(KarigarIcons.warning, color: KarigarColors.danger, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message,
            style: GoogleFonts.inter(color: KarigarColors.danger, fontSize: 13))),
        GestureDetector(
          onTap: onDismiss,
          child: Icon(KarigarIcons.close, color: KarigarColors.danger, size: 18),
        ),
      ]),
    );
  }
}

// =============================================================================
// 7. STATUS PILL
// =============================================================================

class KarigarStatusPill extends StatelessWidget {
  final String label;
  final Color  color;
  final IconData? icon;

  const KarigarStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: KarigarStyles.statusPill(color),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
        ],
        Text(label, style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        )),
      ]),
    );
  }
}

// =============================================================================
// 8. WASTAGE INDICATOR BANNER
// =============================================================================

class WastageBanner extends StatelessWidget {
  final double wastagePercent;
  const WastageBanner({super.key, required this.wastagePercent});

  @override
  Widget build(BuildContext context) {
    final isCritical = wastagePercent > 5.0;
    final isHigh     = wastagePercent > 2.0;
    if (!isHigh && !isCritical) return const SizedBox.shrink();

    final color   = isCritical ? KarigarColors.danger : KarigarColors.warning;
    final message = isCritical
        ? KarigarStrings.noteWastageCritical
        : KarigarStrings.noteWastageHigh;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(children: [
        Icon(KarigarIcons.warning, color: color, size: 16),
        const SizedBox(width: 10),
        Expanded(child: Text(message,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ))),
      ]),
    );
  }
}
