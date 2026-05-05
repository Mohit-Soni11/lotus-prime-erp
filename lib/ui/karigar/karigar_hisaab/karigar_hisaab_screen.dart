// =============================================================================
// FILE        : karigar_hisaab_screen.dart
// MODULE      : Karigar
// LAYER       : UI / Screen
// DESCRIPTION : Karigar Hisaab (Ledger) screen.
//               Split-panel layout matching CashBook + Purchase screen pattern:
//               LEFT PANEL  (300px) — Dark: karigar list, search, active selection
//               RIGHT PANEL (flex)  — Light: stats cards + chronological timeline
//               - App Bar extracted to karigar_hisaab_app_bar.dart
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../database/db/app_database.dart';
import '../../../logic/karigar/karigar_hisaab_controller.dart';
import '../../../models/karigar/karigar_enums/karigar_enums.dart';
import '../../../models/karigar/karigar_issue_model.dart';
import '../../../models/karigar/karigar_stats_model.dart';
import '../../../theme/karigar/karigar_theme.dart';
import 'karigar_hisaab_app_bar.dart'; // NAYA IMPORT

class KarigarHisaabScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const KarigarHisaabScreen({super.key, this.onBack});

  @override
  State<KarigarHisaabScreen> createState() => _KarigarHisaabScreenState();
}

class _KarigarHisaabScreenState extends State<KarigarHisaabScreen> {
  late final KarigarHisaabController _ctrl;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl = KarigarHisaabController(AppDatabase());
    _ctrl.loadKarigars();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KarigarColors.shellBg,
      // NAYA APP BAR CALL
      appBar: KarigarHisaabAppBar(
        onBack: widget.onBack ?? () => Navigator.maybePop(context),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _ctrl,
          builder: (context, _) {
            return Row(children: [
              // ── LEFT PANEL — Karigar List ──────────────────────────
              _LeftPanel(
                ctrl: _ctrl,
                searchCtrl: _searchCtrl,
              ),

              // ── RIGHT PANEL — Ledger ───────────────────────────────
              Expanded(
                child: Container(
                  color: KarigarColors.bodyBg,
                  child: _ctrl.hasKarigar
                      ? _RightPanel(ctrl: _ctrl)
                      : _SelectKarigarPrompt(),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// LEFT PANEL
// ════════════════════════════════════════════════════════════════════════════

class _LeftPanel extends StatelessWidget {
  final KarigarHisaabController ctrl;
  final TextEditingController searchCtrl;
  const _LeftPanel({required this.ctrl, required this.searchCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: KarigarStyles.leftPanelWidth,
      decoration: KarigarStyles.leftPanelDecoration,
      child: Column(children: [
        // Search
        Padding(
          padding: const EdgeInsets.all(14),
          child: TextField(
            controller: searchCtrl,
            onChanged: ctrl.onKarigarSearchChanged,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: KarigarColors.shellTextTitle,
            ),
            decoration: InputDecoration(
              hintText: 'Search karigar...',
              hintStyle: GoogleFonts.inter(
                fontSize: 13,
                color: KarigarColors.shellTextMuted,
              ),
              prefixIcon: const Icon(KarigarIcons.search,
                  color: KarigarColors.shellTextMuted, size: 18),
              filled: true,
              fillColor: KarigarColors.leftPanelBorder,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: KarigarColors.brandGold, width: 1),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),

        // Karigar count header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            Text(
              '${ctrl.filteredKarigars.length} karigar${ctrl.filteredKarigars.length == 1 ? '' : 's'}',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: KarigarColors.shellTextMuted,
              ),
            ),
          ]),
        ),

        // List
        Expanded(
          child: ctrl.isLoadingKarigars
              ? const Center(
                  child: CircularProgressIndicator(
                      color: KarigarColors.brandGold, strokeWidth: 2),
                )
              : ctrl.filteredKarigars.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(KarigarIcons.emptyKarigar,
                              size: 40, color: KarigarColors.shellBorder),
                          const SizedBox(height: 10),
                          Text('No karigars found',
                              style: KarigarStyles.karigarSub),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: ctrl.filteredKarigars.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (_, i) {
                        final k = ctrl.filteredKarigars[i];
                        final isSelected = ctrl.selectedKarigar?.id == k.id;
                        return GestureDetector(
                          onTap: () => ctrl.selectKarigar(k),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: isSelected
                                ? KarigarStyles.selectedRow
                                : BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                            child: Row(children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: isSelected
                                    ? KarigarColors.brandGold.withOpacity(0.2)
                                    : KarigarColors.leftPanelBorder,
                                child: Text(
                                  _initials(k.name),
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? KarigarColors.brandGold
                                        : KarigarColors.shellTextMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(k.name,
                                      style: KarigarStyles.karigarName.copyWith(
                                        fontSize: 13,
                                        color: isSelected
                                            ? KarigarColors.shellTextTitle
                                            : KarigarColors.shellTextTitle
                                                .withOpacity(0.85),
                                      ),
                                      overflow: TextOverflow.ellipsis),
                                  Text(k.specialization,
                                      style: KarigarStyles.karigarSub
                                          .copyWith(fontSize: 10),
                                      overflow: TextOverflow.ellipsis),
                                ],
                              )),
                              if (isSelected)
                                const Icon(Icons.chevron_right_rounded,
                                    color: KarigarColors.brandGold, size: 16),
                              if (!k.isActive)
                                Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: KarigarColors.statusCancBg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('Inactive',
                                      style: GoogleFonts.inter(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                        color: KarigarColors.statusCancelled,
                                      )),
                                ),
                            ]),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2)
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}

// ════════════════════════════════════════════════════════════════════════════
// RIGHT PANEL
// ════════════════════════════════════════════════════════════════════════════

class _RightPanel extends StatelessWidget {
  final KarigarHisaabController ctrl;
  const _RightPanel({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final k = ctrl.selectedKarigar!;
    final s = ctrl.stats;
    return Column(children: [
      // ── Karigar Header ──────────────────────────────────────────
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        decoration: const BoxDecoration(
          color: KarigarColors.cardBg,
          border: Border(
              bottom: BorderSide(color: KarigarColors.divider, width: 1)),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: KarigarColors.brandGoldLight,
            child: Text(_initials(k.name),
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: KarigarColors.brandGold,
                )),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(k.name,
                  style: KarigarStyles.sectionTitle.copyWith(fontSize: 16)),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(KarigarIcons.phone,
                    size: 11, color: KarigarColors.textMuted),
                const SizedBox(width: 4),
                Text(k.phone, style: KarigarStyles.caption),
                const SizedBox(width: 12),
                const Icon(KarigarIcons.speciality,
                    size: 11, color: KarigarColors.textMuted),
                const SizedBox(width: 4),
                Text(k.specialization, style: KarigarStyles.caption),
              ]),
            ],
          )),
        ]),
      ),

      // ── Stats Cards ─────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.all(16),
        color: KarigarColors.bodyBg,
        child: _StatsGrid(stats: s),
      ),

      // ── Timeline Label ──────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        child: Row(children: [
          const Icon(KarigarIcons.ledger,
              size: 16, color: KarigarColors.textMuted),
          const SizedBox(width: 8),
          Text('Transaction Timeline',
              style: KarigarStyles.sectionTitle.copyWith(fontSize: 13)),
        ]),
      ),

      // ── Timeline ────────────────────────────────────────────────
      Expanded(
        child: ctrl.isLoadingLedger
            ? const Center(
                child: CircularProgressIndicator(
                    color: KarigarColors.brandGold, strokeWidth: 2))
            : ctrl.ledgerEntries.isEmpty
                ? _EmptyLedger()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: ctrl.ledgerEntries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final entry = ctrl.ledgerEntries[i];
                      return entry.isIssue
                          ? _IssueEntry(issue: entry.issue!)
                          : _ReceiptEntry(receipt: entry.receipt!);
                    },
                  ),
      ),
    ]);
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2)
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}

class _StatsGrid extends StatelessWidget {
  final KarigarStatsModel stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final rupee = NumberFormat('₹##,##,##0.00', 'en_IN');
    final wt = NumberFormat('##0.000', 'en_IN');

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          icon: KarigarIcons.statsWeight,
          label: KarigarStrings.statIssuedWt,
          value: '${wt.format(stats.totalIssuedWeight)}g',
          color: KarigarColors.info,
        ),
        _StatCard(
          icon: KarigarIcons.statsWeight,
          label: KarigarStrings.statReceivedWt,
          value: '${wt.format(stats.totalReceivedWeight)}g',
          color: KarigarColors.success,
        ),
        _StatCard(
          icon: KarigarIcons.statsWeight,
          label: KarigarStrings.statPendingWt,
          value: '${wt.format(stats.pendingWeight)}g',
          color: KarigarColors.warning,
        ),
        _StatCard(
          icon: KarigarIcons.statsMoney,
          label: KarigarStrings.statBalance,
          value: rupee.format(stats.outstandingBalance),
          color: stats.outstandingBalance > 0
              ? KarigarColors.danger
              : KarigarColors.success,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: KarigarStyles.statCard(color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Expanded(
                child: Text(label,
                    style: KarigarStyles.statLabel,
                    overflow: TextOverflow.ellipsis)),
          ]),
          Text(value,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _IssueEntry extends StatelessWidget {
  final KarigarIssueWithKarigar issue;
  const _IssueEntry({required this.issue});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KarigarColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: KarigarColors.info.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
              color: KarigarColors.shadowLight,
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: KarigarColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(KarigarIcons.txnIssue,
              color: KarigarColors.info, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(KarigarStrings.ledgerIssued,
                  style: KarigarStyles.ledgerTitle
                      .copyWith(color: KarigarColors.info)),
              const Spacer(),
              Text(fmt.format(issue.issueDate), style: KarigarStyles.caption),
            ]),
            const SizedBox(height: 4),
            Text(issue.issueNumber, style: KarigarStyles.issueNumber),
            const SizedBox(height: 4),
            Text(issue.itemDescription,
                style: KarigarStyles.ledgerSub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [
              _TinyChip('${issue.netWeightIssued.toStringAsFixed(3)}g issued',
                  KarigarColors.info),
              const SizedBox(width: 6),
              _TinyChip(issue.metalDisplay, KarigarColors.brandGold),
              const SizedBox(width: 6),
              _TinyChip(
                  issue.statusEnum.label,
                  issue.isOverdue
                      ? KarigarColors.danger
                      : KarigarColors.textMuted),
            ]),
          ],
        )),
      ]),
    );
  }
}

class _ReceiptEntry extends StatelessWidget {
  final KarigarReceiptWithDetails receipt;
  const _ReceiptEntry({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    final rupee = NumberFormat('₹##,##,##0.00', 'en_IN');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KarigarColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: receipt.isHighWastage
              ? KarigarColors.danger.withOpacity(0.35)
              : KarigarColors.success.withOpacity(0.25),
          width: receipt.isHighWastage ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
              color: KarigarColors.shadowLight,
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: KarigarColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(KarigarIcons.txnReceipt,
              color: KarigarColors.success, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(KarigarStrings.ledgerReceived,
                  style: KarigarStyles.ledgerTitle
                      .copyWith(color: KarigarColors.success)),
              const Spacer(),
              Text(fmt.format(receipt.receiptDate),
                  style: KarigarStyles.caption),
            ]),
            const SizedBox(height: 4),
            Text(receipt.receiptNumber,
                style: KarigarStyles.issueNumber
                    .copyWith(color: KarigarColors.success)),
            const SizedBox(height: 4),
            Text('Issue ref: ${receipt.issueNumber}',
                style: KarigarStyles.ledgerSub),
            const SizedBox(height: 6),
            Row(children: [
              _TinyChip('${receipt.netWeightReceived.toStringAsFixed(3)}g rcvd',
                  KarigarColors.success),
              const SizedBox(width: 6),
              _TinyChip(
                  'Wastage: ${receipt.wastagePercent.toStringAsFixed(2)}%',
                  receipt.isHighWastage
                      ? KarigarColors.danger
                      : KarigarColors.textMuted),
              const SizedBox(width: 6),
              _TinyChip(rupee.format(receipt.makingChargesAmount),
                  KarigarColors.accentCharges),
            ]),

            // Wastage warning
            if (receipt.isHighWastage) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: KarigarColors.danger.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: KarigarColors.danger.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(KarigarIcons.warning,
                      color: KarigarColors.danger, size: 12),
                  const SizedBox(width: 6),
                  Text(KarigarStrings.noteWastageHigh,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: KarigarColors.danger,
                      )),
                ]),
              ),
            ],
          ],
        )),
      ]),
    );
  }
}

class _TinyChip extends StatelessWidget {
  final String label;
  final Color color;
  const _TinyChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          )),
    );
  }
}

class _EmptyLedger extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(KarigarIcons.ledger, size: 56, color: KarigarColors.textHint),
        const SizedBox(height: 16),
        Text(KarigarStrings.emptyLedgerTitle,
            style: KarigarStyles.sectionTitle.copyWith(fontSize: 15)),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(KarigarStrings.emptyLedgerSub,
              style: KarigarStyles.caption.copyWith(fontSize: 13),
              textAlign: TextAlign.center),
        ),
      ],
    ));
  }
}

class _SelectKarigarPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(KarigarIcons.karigarSel, size: 60, color: KarigarColors.textHint),
        const SizedBox(height: 16),
        Text(KarigarStrings.ledgerSelectPrompt,
            style: KarigarStyles.sectionTitle.copyWith(
              fontSize: 15,
              color: KarigarColors.textMuted,
            ),
            textAlign: TextAlign.center),
      ],
    ));
  }
}

String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2)
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
}
