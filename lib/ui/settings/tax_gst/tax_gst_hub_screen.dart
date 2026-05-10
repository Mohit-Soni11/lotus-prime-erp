// ============================================================
// FILE    : lib/ui/settings/tax_gst/tax_gst_hub_screen.dart
// MODULE  : Tax & GST Configuration
// AUTHOR  : Lotus Prime ERP
// VERSION : 1.0.0
// DESC    : Main screen — 7 expandable section cards.
//           Owns TaxGstHubLogic. Passes section logics to sections.
//           Uses Provider pattern via ListenableBuilder.
// ============================================================

import 'package:flutter/material.dart';
import '../../../theme/settings/tax_gst/tax_gst_theme.dart';
import '../../../logic/setting/tax_gst/tax_gst_hub_logic.dart';
import '../../../../database/db/app_database.dart';
import 'tax_gst_app_bar.dart';
import 'widgets/tax_gst_sync_banner.dart';
import 'widgets/tax_gst_section_card.dart';
import 'sections/gst_registration_section.dart';
import 'sections/gst_slabs_section.dart';
import 'sections/hsn_code_section.dart';
import 'sections/tax_preferences_section.dart';
import 'sections/tcs_tds_section.dart';
import 'sections/e_invoice_section.dart';
import 'sections/bis_hallmark_section.dart';

class TaxGstHubScreen extends StatefulWidget {
  const TaxGstHubScreen({super.key, required this.database});
  final AppDatabase database;

  @override
  State<TaxGstHubScreen> createState() => _TaxGstHubScreenState();
}

class _TaxGstHubScreenState extends State<TaxGstHubScreen>
    with TickerProviderStateMixin {
  late final TaxGstHubLogic _logic;

  // Section card metadata — driven entirely from theme strings & colors
  static const List<_CardMeta> _cards = [
    _CardMeta(
      icon: TaxGstIcons.card01,
      title: TaxGstStrings.card01Title,
      subtitle: TaxGstStrings.card01Subtitle,
      tag: TaxGstStrings.card01Tag,
      accentColor: TaxGstColors.card01Accent,
      accentLight: TaxGstColors.card01Light,
    ),
    _CardMeta(
      icon: TaxGstIcons.card02,
      title: TaxGstStrings.card02Title,
      subtitle: TaxGstStrings.card02Subtitle,
      tag: TaxGstStrings.card02Tag,
      accentColor: TaxGstColors.card02Accent,
      accentLight: TaxGstColors.card02Light,
    ),
    _CardMeta(
      icon: TaxGstIcons.card03,
      title: TaxGstStrings.card03Title,
      subtitle: TaxGstStrings.card03Subtitle,
      tag: TaxGstStrings.card03Tag,
      accentColor: TaxGstColors.card03Accent,
      accentLight: TaxGstColors.card03Light,
    ),
    _CardMeta(
      icon: TaxGstIcons.card04,
      title: TaxGstStrings.card04Title,
      subtitle: TaxGstStrings.card04Subtitle,
      tag: TaxGstStrings.card04Tag,
      accentColor: TaxGstColors.card04Accent,
      accentLight: TaxGstColors.card04Light,
    ),
    _CardMeta(
      icon: TaxGstIcons.card05,
      title: TaxGstStrings.card05Title,
      subtitle: TaxGstStrings.card05Subtitle,
      tag: TaxGstStrings.card05Tag,
      accentColor: TaxGstColors.card05Accent,
      accentLight: TaxGstColors.card05Light,
    ),
    _CardMeta(
      icon: TaxGstIcons.card06,
      title: TaxGstStrings.card06Title,
      subtitle: TaxGstStrings.card06Subtitle,
      tag: TaxGstStrings.card06Tag,
      accentColor: TaxGstColors.card06Accent,
      accentLight: TaxGstColors.card06Light,
    ),
    _CardMeta(
      icon: TaxGstIcons.card07,
      title: TaxGstStrings.card07Title,
      subtitle: TaxGstStrings.card07Subtitle,
      tag: TaxGstStrings.card07Tag,
      accentColor: TaxGstColors.card07Accent,
      accentLight: TaxGstColors.card07Light,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _logic = TaxGstHubLogic(widget.database);
    _logic.initialise();
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  // ── Section body builder ──────────────────────────────────────
  Widget _buildSectionBody(int index) {
    return switch (index) {
      0 => GstRegistrationSection(logic: _logic.registrationLogic),
      1 => GstSlabsSection(logic: _logic.slabsLogic),
      2 => HsnCodeSection(logic: _logic.hsnLogic),
      3 => TaxPreferencesSection(logic: _logic.preferencesLogic),
      4 => TcsTdsSection(logic: _logic.tcsTdsLogic),
      5 => EInvoiceSection(logic: _logic.eInvoiceLogic),
      6 => BisHallmarkSection(logic: _logic.bisLogic),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaxGstColors.bodyBackground,
      appBar: TaxGstAppBar(
        onBackPressed: () => Navigator.maybePop(context),
      ),
      body: ListenableBuilder(
        listenable: _logic,
        builder: (context, _) {
          // ── Loading state ──────────────────────────────────────
          if (_logic.isLoading) {
            return const _LoadingView();
          }

          // ── Error state ────────────────────────────────────────
          if (_logic.loadError != null) {
            return _ErrorView(
              message: _logic.loadError!,
              onRetry: _logic.initialise,
            );
          }

          // ── Main content ───────────────────────────────────────
          return SafeArea(
            top: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: TaxGstStyles.pageInsets,
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Sync Banner
                      const TaxGstSyncBanner(),
                      const SizedBox(height: TaxGstStyles.space2XL),

                      // Section label
                      Text(
                        TaxGstStrings.hubSectionLabel,
                        style: TaxGstStyles.sectionLabel(context),
                      ),
                      const SizedBox(height: TaxGstStyles.spaceLG),

                      // 7 Section Cards
                      ..._cards.asMap().entries.map((entry) {
                        final i = entry.key;
                        final meta = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: TaxGstStyles.cardGap),
                          child: TaxGstSectionCard(
                            index: i,
                            icon: meta.icon,
                            title: meta.title,
                            subtitle: meta.subtitle,
                            tag: meta.tag,
                            accentColor: meta.accentColor,
                            accentLight: meta.accentLight,
                            isExpanded: _logic.isExpanded(i),
                            onTap: () => _logic.toggleCard(i),
                            expandedChild: _buildSectionBody(i),
                          ),
                        );
                      }),

                      const SizedBox(height: TaxGstStyles.space3XL),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Card metadata model ───────────────────────────────────────────────────────

class _CardMeta {
  const _CardMeta({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.accentColor,
    required this.accentLight,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;
  final Color accentColor;
  final Color accentLight;
}

// ── Loading State ─────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: TaxGstColors.accentPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading Tax & GST configuration…',
            style: TaxGstStyles.sectionSubtitle(context),
          ),
        ],
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(TaxGstIcons.statusError,
                size: 48, color: TaxGstColors.statusDanger.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(message,
                style: TaxGstStyles.sectionSubtitle(context),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(TaxGstIcons.actionRefresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TaxGstColors.accentPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(TaxGstStyles.radiusButton)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
