// -----------------------------------------------------------------------------
// FILE: lib/theme/settings/account_profile/account_profile_icons.dart
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class AccountProfileIcons {
  AccountProfileIcons._();

  static const IconData backArrow       = Icons.arrow_back_rounded;
  static const IconData moduleIcon      = Icons.manage_accounts_rounded;
  static const IconData camera          = Icons.camera_alt_rounded;
  static const IconData edit            = Icons.edit_rounded;
  static const IconData crop            = Icons.crop_rounded;
  static const IconData person          = Icons.person_outline_rounded;
  static const IconData phone           = Icons.phone_android_rounded;
  static const IconData email           = Icons.email_outlined;
  static const IconData lock            = Icons.lock_outline_rounded;
  static const IconData lockOpen        = Icons.lock_open_rounded;
  static const IconData visibility      = Icons.visibility_outlined;
  static const IconData visibilityOff   = Icons.visibility_off_outlined;
  static const IconData save            = Icons.check_rounded;
  static const IconData shield          = Icons.shield_outlined;
  static const IconData verified        = Icons.verified_user_outlined;
  static const IconData company         = Icons.business_outlined;
  static const IconData chevronDown     = Icons.keyboard_arrow_down_rounded;
  static const IconData chevronUp       = Icons.keyboard_arrow_up_rounded;
  static const IconData gallery         = Icons.photo_library_outlined;
  static const IconData deletePhoto     = Icons.delete_outline_rounded;
  static const IconData systemOnline    = Icons.circle;
}


// -----------------------------------------------------------------------------
// FILE: lib/theme/settings/account_profile/account_profile_strings.dart
// -----------------------------------------------------------------------------

class AccountProfileStrings {
  AccountProfileStrings._();

  // ── APP BAR ───────────────────────────────────────────────────────────────
  static const String appBarTitle   = 'ACCOUNT PROFILE';
  static const String systemOnline  = 'SYSTEM ONLINE';

  // ── SECTIONS ──────────────────────────────────────────────────────────────
  static const String sectionProfile    = 'PROFILE INFORMATION';
  static const String sectionPassword   = 'CHANGE PASSWORD';
  static const String sectionAccount    = 'ACCOUNT DETAILS';

  // ── FIELDS ────────────────────────────────────────────────────────────────
  static const String labelName         = 'Full Name';
  static const String labelMobile       = 'Mobile Number';
  static const String labelEmail        = 'Email Address';
  static const String labelEmailNote    = 'Email cannot be changed here';
  static const String labelCurrentPass  = 'Current Password';
  static const String labelNewPass      = 'New Password';
  static const String labelConfirmPass  = 'Confirm New Password';

  // ── BUTTONS ───────────────────────────────────────────────────────────────
  static const String btnSave           = 'Save Changes';
  static const String btnUpdatePass     = 'Update Password';
  static const String btnChangePhoto    = 'Change Photo';
  static const String btnCrop           = 'Crop';

  // ── PHOTO MENU ────────────────────────────────────────────────────────────
  static const String photoMenuGallery  = 'Choose from Gallery';
  static const String photoMenuRemove   = 'Remove Photo';

  // ── SUCCESS / ERROR ───────────────────────────────────────────────────────
  static const String successProfile    = 'Profile updated successfully!';
  static const String successPassword   = 'Password changed successfully!';
  static const String errorPassMismatch = 'New passwords do not match';
  static const String errorPassLength   = 'Password must be at least 6 characters';
  static const String errorWrongPass    = 'Current password is incorrect';
  static const String errorNameRequired = 'Full name is required';
}


// -----------------------------------------------------------------------------
// FILE: lib/theme/settings/account_profile/account_profile_theme.dart
// Barrel export
// -----------------------------------------------------------------------------
// export 'account_profile_colors.dart';
// export 'account_profile_styles.dart';
// export 'account_profile_icons.dart';
// export 'account_profile_strings.dart';