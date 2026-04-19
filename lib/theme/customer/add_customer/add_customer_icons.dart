// -----------------------------------------------------------------------------
// FILE: add_customer_icons.dart
// MODULE: Customer → Add New Customer
// -----------------------------------------------------------------------------
 
import 'package:flutter/material.dart';
 
class AddCustomerIcons {
  AddCustomerIcons._();
 
  // ── APP BAR ───────────────────────────────────────────────────────────────
  static const IconData backArrow     = Icons.arrow_back_rounded;
  static const IconData moduleIcon    = Icons.person_add_rounded;
 
  // ── FORM FIELD PREFIXES ───────────────────────────────────────────────────
  static const IconData name          = Icons.person_outline_rounded;
  static const IconData mobile        = Icons.phone_android_rounded;
  static const IconData whatsapp      = Icons.chat_bubble_outline_rounded;
  static const IconData city          = Icons.location_city_rounded;
  static const IconData notes         = Icons.notes_rounded;
  static const IconData customerType  = Icons.card_membership_rounded;
 
  // ── CUSTOMER TYPE TOGGLE ─────────────────────────────────────────────────
  static const IconData regular       = Icons.person_rounded;
  static const IconData vip           = Icons.workspace_premium_rounded;
 
  // ── SAVE BUTTON ──────────────────────────────────────────────────────────
  static const IconData save          = Icons.check_circle_rounded;
  static const IconData saving        = Icons.hourglass_empty_rounded;
 
  // ── VALIDATION ───────────────────────────────────────────────────────────
  static const IconData errorIcon     = Icons.error_outline_rounded;
  static const IconData successIcon   = Icons.check_circle_outline_rounded;
  static const IconData required      = Icons.star_rounded;
 
  // ── SECTION HEADER ───────────────────────────────────────────────────────
  static const IconData contactSection   = Icons.contact_phone_rounded;
  static const IconData locationSection  = Icons.place_rounded;
  static const IconData typeSection      = Icons.category_rounded;
}