// ==========================================
// FILE: shared_pos_components.dart
// TYPE: Reusable UI Components (UPGRADED)
// AUTHOR: Senior System Architect
// DESCRIPTION: Highly optimized, zero-lag UI widgets.
//              ✅ 100% Theme Mapped & Pixel-Perfect.
// ==========================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';

// ==========================================
// 1. REUSABLE TABLE HEADER
// ==========================================
class PosTableHeader extends StatelessWidget {
  final String title;
  final int flex;
  final TextAlign textAlign;

  const PosTableHeader({
    super.key,
    required this.title,
    required this.flex,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        textAlign: textAlign,
        style: SalesPosStyles.tableColumnHeader,
      ),
    );
  }
}

// ==========================================
// 2. ATOMIC TEXT FIELD (ZERO-LAG INPUT)
// ==========================================
class PosAtomicTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isNumber;
  final FocusNode? focusNode;
  final Function(String)? onSubmitted;
  final Color focusBorderColor;
  // ✅ FIX: Explicit textInputAction — caller decides next/done
  final TextInputAction? textInputAction;

  const PosAtomicTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.isNumber = false,
    this.focusNode,
    this.onSubmitted,
    this.focusBorderColor = SalesPosColors.brandGold,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    // Default: 'done' only when onSubmitted adds new item (last field), else 'next'
    final action = textInputAction ??
        (onSubmitted != null ? TextInputAction.done : TextInputAction.next);

    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: isNumber
            ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
            : null,
        textInputAction: action,
        style: SalesPosStyles.standardRowText,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: SalesPosStyles.subTitleMuted.copyWith(fontSize: 13),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          filled: true,
          fillColor: SalesPosColors.bodyPanelBg,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: SalesPosColors.bodyBorder)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: SalesPosColors.bodyBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: focusBorderColor, width: 1.5)),
        ),
        onSubmitted: onSubmitted,
      ),
    );
  }
}
