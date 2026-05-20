// =============================================================================
// FILE        : karigar_icons.dart
// MODULE      : Karigar
// LAYER       : Theme / Icons
// DESCRIPTION : All IconData constants for the Karigar module.
//               Zero hardcoded icons in UI files.
// =============================================================================

import 'package:flutter/material.dart';

class KarigarIcons {
  KarigarIcons._();

  // ── APP BAR ───────────────────────────────────────────────────────────────
  static const IconData backArrow = Icons.arrow_back_rounded;
  static const IconData moduleIcon = Icons.engineering_rounded;

  // ── SECTION HEADERS ───────────────────────────────────────────────────────
  static const IconData karigarSel = Icons.person_search_rounded;
  static const IconData issueDetails = Icons.assignment_rounded;
  static const IconData metalDetails = Icons.diamond_rounded;
  static const IconData delivery = Icons.schedule_rounded;
  static const IconData wastage = Icons.analytics_rounded;
  static const IconData charges = Icons.request_quote_rounded;
  static const IconData payment = Icons.payments_rounded;
  static const IconData notes = Icons.notes_rounded;

  // ── FORM FIELDS ───────────────────────────────────────────────────────────
  static const IconData karigar = Icons.engineering_rounded;
  static const IconData phone = Icons.phone_rounded;
  static const IconData issueNumber = Icons.tag_rounded;
  static const IconData receiptNum = Icons.receipt_long_rounded;
  static const IconData description = Icons.description_rounded;
  static const IconData category = Icons.category_rounded;
  static const IconData quantity = Icons.format_list_numbered_rounded;
  static const IconData weight = Icons.scale_rounded;
  static const IconData metal = Icons.settings_input_component_rounded;
  static const IconData purity = Icons.verified_rounded;
  static const IconData calendar = Icons.calendar_today_rounded;
  static const IconData money = Icons.currency_rupee_rounded;
  static const IconData status = Icons.flag_rounded;
  static const IconData address = Icons.location_on_rounded;
  static const IconData city = Icons.location_city_rounded;
  static const IconData speciality = Icons.workspace_premium_rounded;
  static const IconData rate = Icons.percent_rounded;
  static const IconData balance = Icons.account_balance_wallet_rounded;

  // ── ACTIONS ───────────────────────────────────────────────────────────────
  static const IconData save = Icons.save_rounded;
  static const IconData reset = Icons.restart_alt_rounded;
  static const IconData addKarigar = Icons.person_add_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData receive = Icons.move_to_inbox_rounded;
  static const IconData issue = Icons.outbox_rounded;
  static const IconData markDone = Icons.check_circle_rounded;
  static const IconData cancel = Icons.cancel_rounded;
  static const IconData inProgress = Icons.hourglass_top_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData dropDown = Icons.keyboard_arrow_down_rounded;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData info = Icons.info_outline_rounded;

  // ── STATUS INDICATORS ────────────────────────────────────────────────────
  static const IconData overdue = Icons.alarm_rounded;
  static const IconData pending = Icons.pending_actions_rounded;
  static const IconData completed = Icons.task_alt_rounded;
  static const IconData paid = Icons.check_circle_outline_rounded;
  static const IconData unpaid = Icons.money_off_rounded;

  // ── HISAAB / LEDGER ──────────────────────────────────────────────────────
  static const IconData ledger = Icons.menu_book_rounded;
  static const IconData txnIssue = Icons.arrow_upward_rounded;
  static const IconData txnReceipt = Icons.arrow_downward_rounded;
  static const IconData statsWeight = Icons.scale_rounded;
  static const IconData statsMoney = Icons.currency_rupee_rounded;
  static const IconData statsJobs = Icons.work_outline_rounded;

  // ── EMPTY STATE ──────────────────────────────────────────────────────────
  static const IconData emptyJobs = Icons.work_off_rounded;
  static const IconData emptyKarigar = Icons.person_off_rounded;
}
