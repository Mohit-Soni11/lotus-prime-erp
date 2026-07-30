// -----------------------------------------------------------------------------
// FILE: branding_icons.dart
// TYPE: Theme Layer / Icons
// AUTHOR: Senior System Architect
// DESCRIPTION: Centralized IconData repository. Keeps the UI completely decoupled
//              from specific icon libraries (like Material or Cupertino).
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class BrandingIcons {
  // Private constructor
  BrandingIcons._();

  // --- Section Headers ---
  static const IconData secSocial = Icons.public_rounded;
  static const IconData website = Icons.language_rounded;
  static const IconData instagram = Icons.camera_alt_rounded;
  static const IconData facebook = Icons.facebook_rounded;
  static const IconData youtube = Icons.play_circle_fill_rounded;
  static const IconData whatsappChannel = Icons.campaign_rounded;

  // --- Actions & Status ---
  static const IconData edit = Icons.edit_rounded;
  static const IconData save = Icons.check_circle_rounded;
  static const IconData lock = Icons.lock_outline_rounded;
  static const IconData linkTest = Icons.open_in_new_rounded;
  static const IconData statusSync = Icons.verified_rounded;
}
