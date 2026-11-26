import 'package:flutter/material.dart';

enum PasswordStrength { empty, weak, fair, strong }

extension PasswordStrengthX on PasswordStrength {
  String get label => switch (this) {
        PasswordStrength.empty => '',
        PasswordStrength.weak => 'Weak',
        PasswordStrength.fair => 'Good',
        PasswordStrength.strong => 'Strong',
      };

  Color get color => switch (this) {
        PasswordStrength.empty => const Color(0xFFE2E8F0),
        PasswordStrength.weak => const Color(0xFFDC2626),
        PasswordStrength.fair => const Color(0xFFD97706),
        PasswordStrength.strong => const Color(0xFF16A34A),
      };

  int get filledSegments => switch (this) {
        PasswordStrength.empty => 0,
        PasswordStrength.weak => 1,
        PasswordStrength.fair => 2,
        PasswordStrength.strong => 3,
      };
}

abstract final class PasswordStrengthEvaluator {
  static PasswordStrength evaluate(String value) {
    if (value.isEmpty) return PasswordStrength.empty;
    var score = 0;
    if (value.length >= 8) score++;
    if (RegExp(r'[A-Za-z]').hasMatch(value) && RegExp(r'\d').hasMatch(value)) {
      score++;
    }
    if (RegExp(r'[A-Z]').hasMatch(value) &&
        RegExp(r'[a-z]').hasMatch(value) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
      score++;
    }
    return switch (score) {
      3 => PasswordStrength.strong,
      2 => PasswordStrength.fair,
      _ => PasswordStrength.weak,
    };
  }
}
