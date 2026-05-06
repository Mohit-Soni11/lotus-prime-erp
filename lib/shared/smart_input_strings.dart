// =============================================================================
// FILE        : smart_input_strings.dart
// MODULE      : Shared → Smart Input
// LAYER       : Theme → Strings
// =============================================================================

import 'smart_field_type.dart';

class SmartInputStrings {
  SmartInputStrings._();

  static const String spellPrefix = 'Search instead for ';
  static const String loadingText = 'Thinking...';

  // Chip section label per field type
  static String chipLabel(SmartFieldType type) {
    switch (type) {
      case SmartFieldType.name:
        return 'हिंदी:';
      case SmartFieldType.address:
        return 'Suggestions:';
      case SmartFieldType.item:
        return 'Items:';
      case SmartFieldType.company:
        return 'Companies:';
      default:
        return 'Options:';
    }
  }
}
