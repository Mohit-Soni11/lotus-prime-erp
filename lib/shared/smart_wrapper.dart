// =============================================================================
// FILE        : smart_wrapper.dart
// MODULE      : Shared → Smart Input
// LAYER       : UI Widget
// PURPOSE     : Kisi bhi existing TextFormField ke upar/neeche
//               SmartInput suggestions dikhata hai — bina screen badle.
//
// HOW IT WORKS:
//   - Aapka existing TextFormField bilkul UNCHANGED rehta hai
//   - SmartWrapper us field ko sunta hai (TextEditingController ke through)
//   - Jab bhi user type kare, neeche suggestions dikha deta hai
//
// USAGE:
//   SmartWrapper(
//     fieldType: SmartFieldType.name,
//     textController: _firstNameCtrl,   ← aapka existing controller
//     child: TextFormField(             ← aapka existing field UNCHANGED
//       controller: _firstNameCtrl,
//       ...
//     ),
//   )
// =============================================================================

import 'package:flutter/material.dart';
import 'smart_input_controller.dart';
import 'smart_field_type.dart';
import 'smart_suggestion_zone.dart';

class SmartWrapper extends StatefulWidget {
  const SmartWrapper({
    super.key,
    required this.fieldType,
    required this.textController,
    required this.child,
  });

  /// Kis type ka field hai — name, address, item, company, remark
  final SmartFieldType fieldType;

  /// Aapka existing TextEditingController — isse SmartWrapper sunta hai
  final TextEditingController textController;

  /// Aapka existing TextFormField — bilkul UNCHANGED
  final Widget child;

  @override
  State<SmartWrapper> createState() => _SmartWrapperState();
}

class _SmartWrapperState extends State<SmartWrapper> {
  late final SmartInputController _smart;

  @override
  void initState() {
    super.initState();
    _smart = SmartInputController(fieldType: widget.fieldType);
    // Existing TextEditingController ko suno
    widget.textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    _smart.onTextChanged(widget.textController.text);
  }

  // Suggestion accept hone pe field update karo
  void _onSpellTap() {
    final corrected = _smart.acceptSpellCorrection();
    widget.textController.value = TextEditingValue(
      text: corrected,
      selection: TextSelection.collapsed(offset: corrected.length),
    );
  }

  void _onChipTap(String chip) {
    _smart.acceptSuggestion(chip);
    widget.textController.value = TextEditingValue(
      text: chip,
      selection: TextSelection.collapsed(offset: chip.length),
    );
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onTextChanged);
    _smart.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ Aapka existing TextFormField — ek bhi line change nahi
        widget.child,

        // ✅ Suggestions neeche — sirf tab dikhen jab zaroorat ho
        ListenableBuilder(
          listenable: _smart,
          builder: (context, _) {
            if (_smart.currentQuery.trim().isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SmartSuggestionZone(
                controller: _smart,
                onSpellTap: _onSpellTap,
                onChipTap: _onChipTap,
              ),
            );
          },
        ),
      ],
    );
  }
}
