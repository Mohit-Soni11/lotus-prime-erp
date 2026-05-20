// -----------------------------------------------------------------------------
// FILE: tax_gst_icons.dart
// TYPE: Theme / Presentation (Step C)
// AUTHOR: Senior System Architect
// DESCRIPTION: Centralized Icon resources for the Tax & GST module.
//              Strictly locked to prevent instantiation.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class TaxGstIcons {
  TaxGstIcons._(); // Locked to prevent instantiation

  // --- Section Headers ---
  static const IconData secGst = Icons.receipt_long_rounded;
  static const IconData secBis = Icons.workspace_premium_rounded;
  static const IconData secHsn = Icons.account_balance_rounded;
  static const IconData secDocs = Icons.folder_special_rounded;

  // --- Input Fields ---
  static const IconData gstNum = Icons.numbers_rounded;
  static const IconData gstLegalName = Icons.business_rounded;
  static const IconData calendar = Icons.calendar_month_rounded;
  static const IconData taxpayer = Icons.person_pin_rounded;

  static const IconData bisVerified = Icons.verified_user_rounded;
  static const IconData dateRange = Icons.date_range_rounded;

  // --- Actions ---
  static const IconData edit = Icons.edit_rounded;
  static const IconData save = Icons.check_circle_rounded;
  static const IconData portalOpen = Icons.open_in_new_rounded;
  static const IconData verifyCheck = Icons.check_circle_outline_rounded;
  static const IconData hsnSync = Icons.sync_rounded;
  static const IconData lock = Icons.lock_outline_rounded;
  static const IconData unlock = Icons.lock_open_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData arrowRight = Icons.arrow_forward_ios_rounded;

  // --- Documents ---
  static const IconData cloudUp = Icons.cloud_upload_rounded;
  static const IconData uploadFile = Icons.upload_file_rounded;
  static const IconData filePdf = Icons.picture_as_pdf_rounded;
  static const IconData previewEye = Icons.visibility_rounded;
  static const IconData removeTrash = Icons.delete_outline_rounded;
  static const IconData browse = Icons.folder_open_rounded;
  static const IconData info = Icons.info_outline_rounded;

  // --- Status ---
  static const IconData statusShield = Icons.gpp_good_rounded;
  static const IconData error = Icons.error_outline_rounded;
}
