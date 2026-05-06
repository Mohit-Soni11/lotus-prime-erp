// =============================================================================
// FILE        : smart_field_type.dart
// MODULE      : Shared → Smart Input
// LAYER       : Config / Enum
// PURPOSE     : Har text field ka "context" define karta hai — isi se
//               Claude ko pata chalta hai ki kaunsa suggestion dena hai.
// =============================================================================

enum SmartFieldType {
  // 👤 Name fields — Customer, Karigar, Family Member, Supplier names
  //    → Spell correction + Hindi Devanagari transliteration chips
  name,

  // 🏠 Address fields — Address Line 1/2, City, Area, Landmark
  //    → Spell correction + Common Indian city/area completions
  address,

  // 💍 Item fields — Jewellery item names (Gold Ring, Silver Chain, etc.)
  //    → Spell correction + Jewellery-specific item suggestions
  item,

  // 📝 Remark / Notice fields — Internal notes, customer remarks
  //    → Only spell correction, no chips (remarks are freeform)
  remark,

  // 🏢 Company / Shop name fields
  //    → Spell correction + common business name suffixes
  company,

  // 🔖 Generic — Any other text field
  //    → Basic spell correction only
  generic;

  // ── Display label (for debug/logging) ────────────────────────────────────
  String get label {
    switch (this) {
      case SmartFieldType.name:    return 'Name';
      case SmartFieldType.address: return 'Address';
      case SmartFieldType.item:    return 'Item';
      case SmartFieldType.remark:  return 'Remark';
      case SmartFieldType.company: return 'Company';
      case SmartFieldType.generic: return 'Generic';
    }
  }

  // ── Kitne minimum chars pe trigger ho ────────────────────────────────────
  int get minQueryLength {
    switch (this) {
      case SmartFieldType.address: return 3;
      case SmartFieldType.item:    return 2;
      default:                     return 2;
    }
  }

  // ── Kya chips/suggestions dikhani hain (remark mein sirf spell) ──────────
  bool get showSuggestionChips {
    return this != SmartFieldType.remark;
  }
}
