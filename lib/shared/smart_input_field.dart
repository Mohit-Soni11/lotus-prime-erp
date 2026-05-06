// =============================================================================
// FILE        : smart_input_field.dart
// MODULE      : Shared → Smart Input
// LAYER       : UI (Main Widget — drop-in replacement for TextField)
// PURPOSE     : Poore ERP mein Jahan bhi text type karna ho,
//               is widget ko use karo. Controller inject karo → kaam ho gaya.
//
// USAGE — as simple as:
//   SmartInputField(
//     controller: SmartInputController(fieldType: SmartFieldType.name),
//     label: 'Customer Name *',
//   )
// =============================================================================

import 'package:flutter/material.dart';
import 'smart_input_controller.dart';
import 'smart_input_colors.dart';
import 'smart_suggestion_zone.dart';

// ════════════════════════════════════════════════════════════════════════════
// SmartInputField — The Drop-In Widget
// ════════════════════════════════════════════════════════════════════════════
class SmartInputField extends StatefulWidget {
  const SmartInputField({
    super.key,
    required this.controller,

    // ── TextField appearance ─────────────────────────────────────────────
    this.label,
    this.hint,
    this.prefixIcon,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
    this.enabled = true,
    this.maxLines = 1,

    // ── Callbacks ────────────────────────────────────────────────────────
    this.onChanged,
    this.onNameSelected, // fires when user selects any suggestion
    this.validator,
  });

  final SmartInputController controller;

  final String? label;
  final String? hint;
  final Widget? prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final bool enabled;
  final int maxLines;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onNameSelected;
  final FormFieldValidator<String>? validator;

  @override
  State<SmartInputField> createState() => _SmartInputFieldState();
}

class _SmartInputFieldState extends State<SmartInputField> {
  // TextEditingController is a UI concern — lives here, NOT in controller
  late final TextEditingController _textCtrl;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  // ── Helper: update TextField without triggering onChanged ─────────────────
  void _setFieldText(String text) {
    _textCtrl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    widget.onNameSelected?.call(text);
    widget.onChanged?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ════════════════════════════════════════════════════════════════════
        // TextField — 60FPS, NEVER rebuilds due to suggestions.
        // ════════════════════════════════════════════════════════════════════
        TextFormField(
          controller: _textCtrl,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          maxLines: widget.maxLines,
          textInputAction: widget.textInputAction,
          keyboardType: widget.keyboardType ?? TextInputType.text,
          validator: widget.validator,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon,

            // ── Gold loading spinner in suffix ─────────────────────────────
            suffixIcon: _LoadingSpinner(controller: widget.controller),

            // ── Standard InputDecoration (matches AddCustomerColors) ────────
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFD4AF37), // Brand gold
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            labelStyle: const TextStyle(
              fontSize: 13,
              color: Color(0xFF374151),
            ),
            hintStyle: const TextStyle(
              fontSize: 13,
              color: Color(0xFF9CA3AF),
            ),
          ),
          onChanged: (text) {
            widget.controller.onTextChanged(text);
            widget.onChanged?.call(text);
          },
        ),

        // ════════════════════════════════════════════════════════════════════
        // LISTENEBUILDER — ONLY this subtree rebuilds on suggestions.
        // TextField + labels above are completely isolated. Zero jank.
        // ════════════════════════════════════════════════════════════════════
        ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            // Koi input nahi → zone mat dikhao
            if (widget.controller.currentQuery.trim().isEmpty) {
              return const SizedBox.shrink();
            }
            return SmartSuggestionZone(
              controller: widget.controller,
              onSpellTap: () {
                final text = widget.controller.acceptSpellCorrection();
                _setFieldText(text);
              },
              onChipTap: (chip) {
                final text = widget.controller.acceptSuggestion(chip);
                _setFieldText(text);
              },
            );
          },
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _LoadingSpinner — TextField ke suffix mein gold spinner
// Sirf isLoading == true pe dikhta hai
// ════════════════════════════════════════════════════════════════════════════
class _LoadingSpinner extends StatelessWidget {
  const _LoadingSpinner({required this.controller});
  final SmartInputController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.isLoading) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: SmartInputColors.spinnerColor,
            ),
          ),
        );
      },
    );
  }
}
