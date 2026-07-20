import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/stock/shared/application/low_stock_alert_controller.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/low_stock_alert/low_stock_alert_models.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/app_bar/low_stock_alert_app_bar.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/screens/low_stock_manual_rule_editor_screen.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/widgets/low_stock_alert_widgets.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/widgets/low_stock_rule_setup_card.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

class LowStockRuleStudioScreen extends StatefulWidget {
  final LowStockAlertController controller;
  final int initialTab;

  const LowStockRuleStudioScreen({
    super.key,
    required this.controller,
    this.initialTab = 0,
  });

  @override
  State<LowStockRuleStudioScreen> createState() =>
      _LowStockRuleStudioScreenState();
}

class _LowStockRuleStudioScreenState extends State<LowStockRuleStudioScreen> {
  late int _tab = widget.initialTab;
  String? _autoMetalType;
  String? _autoGroupKey;

  @override
  Widget build(BuildContext context) {
    final autoMetalCards = widget.controller.inventoryRuleMetalCards;
    final selectedAutoMetal = _validAutoMetal(autoMetalCards);
    final autoGroupCards = selectedAutoMetal == null
        ? const <LowStockStockCard>[]
        : widget.controller.inventoryRuleGroupCardsForMetal(selectedAutoMetal);
    final selectedAutoGroup = _validAutoGroup(autoGroupCards);
    final autoItemCards = selectedAutoGroup == null
        ? const <LowStockStockCard>[]
        : widget.controller.inventoryRuleItemCardsForGroup(selectedAutoGroup);
    final manualRules = widget.controller.rules
        .where((rule) => rule.ruleMode == LowStockRuleMode.manual)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: InvColors.bodyBg,
      appBar: LowStockAlertAppBar(
        onBack: () => Navigator.of(context).maybePop(),
        onRefresh: widget.controller.load,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: _RuleSetupHeader(
                metalCount: autoMetalCards.length,
                ruleCardCount: widget.controller.summary.watchedGroups,
                manualRuleCount: manualRules.length,
                tab: _tab,
                onTabChanged: (value) => setState(() => _tab = value),
                onManualRule: () => _openEditor(),
              ),
            ),
          ),
          if (_tab == 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                child: _RulePathHeader(
                  selectedMetal: selectedAutoMetal,
                  selectedGroup: selectedAutoGroup,
                  metalCount: autoMetalCards.length,
                  groupCount: autoGroupCards.length,
                  itemCount: autoItemCards.length,
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 34),
            sliver: SliverToBoxAdapter(
              child: _tab == 0
                  ? _AutoRuleBrowser(
                      metalCards: autoMetalCards,
                      groupCards: autoGroupCards,
                      itemCards: autoItemCards,
                      selectedMetalType: selectedAutoMetal,
                      selectedGroupCard: selectedAutoGroup,
                      onOpenMetal: (card) {
                        setState(() {
                          _autoMetalType = card.metalType;
                          _autoGroupKey = null;
                        });
                      },
                      onBackToMetals: () {
                        setState(() {
                          _autoMetalType = null;
                          _autoGroupKey = null;
                        });
                      },
                      onOpenGroup: (card) {
                        if (card.level == LowStockCardLevel.itemGroup) {
                          _openEditor(autoCard: card);
                          return;
                        }
                        setState(() => _autoGroupKey = _groupKey(card));
                      },
                      onBackToGrades: () {
                        setState(() => _autoGroupKey = null);
                      },
                      onOpenItem: (card) => _openEditor(autoCard: card),
                    )
                  : _ManualRuleList(rules: manualRules, onTap: _openEditor),
            ),
          ),
        ],
      ),
    );
  }

  void _openEditor({LowStockStockCard? autoCard, LowStockAlertRule? rule}) {
    Navigator.of(context)
        .push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, __) => LowStockManualRuleEditorScreen(
          controller: widget.controller,
          autoCard: autoCard,
          rule: rule,
        ),
        transitionsBuilder: (_, animation, __, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.025, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    )
        .then((_) {
      if (mounted) setState(() {});
    });
  }

  String? _validAutoMetal(List<LowStockStockCard> cards) {
    final selected = _autoMetalType;
    if (selected == null) return null;
    for (final card in cards) {
      if (card.metalType.trim().toLowerCase() ==
          selected.trim().toLowerCase()) {
        return card.metalType;
      }
    }
    return null;
  }

  LowStockStockCard? _validAutoGroup(List<LowStockStockCard> cards) {
    final selected = _autoGroupKey;
    if (selected == null) return null;
    for (final card in cards) {
      if (_groupKey(card) == selected) {
        return card;
      }
    }
    return null;
  }

  String _groupKey(LowStockStockCard card) {
    final scope = card.level == LowStockCardLevel.itemGroup
        ? card.itemType
        : card.gradeLabel;
    return '${card.level}|${card.metalType}|$scope'.trim().toLowerCase();
  }
}

class _RuleSetupHeader extends StatelessWidget {
  final int metalCount;
  final int ruleCardCount;
  final int manualRuleCount;
  final int tab;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onManualRule;

  const _RuleSetupHeader({
    required this.metalCount,
    required this.ruleCardCount,
    required this.manualRuleCount,
    required this.tab,
    required this.onTabChanged,
    required this.onManualRule,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: InvColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: InvColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: InvColors.shadowMedium,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 940;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flex(
                direction: compact ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: compact
                    ? CrossAxisAlignment.stretch
                    : CrossAxisAlignment.center,
                children: [
                  if (compact)
                    const _RuleSetupTitleRow()
                  else
                    const Expanded(child: _RuleSetupTitleRow()),
                  SizedBox(width: compact ? 0 : 18, height: compact ? 16 : 0),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _HeaderStat(
                        label: 'Metals',
                        value: '$metalCount',
                        icon: Icons.category_rounded,
                        color: InvColors.success,
                      ),
                      _HeaderStat(
                        label: 'Rule Cards',
                        value: '$ruleCardCount',
                        icon: Icons.inventory_2_rounded,
                        color: InvColors.brandGold,
                      ),
                      _HeaderStat(
                        label: 'Overrides',
                        value: '$manualRuleCount',
                        icon: Icons.edit_note_rounded,
                        color: InvColors.textMuted,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Flex(
                direction: compact ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: compact
                    ? CrossAxisAlignment.stretch
                    : CrossAxisAlignment.center,
                children: [
                  if (compact)
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(
                          value: 0,
                          icon: Icon(Icons.inventory_2_rounded),
                          label: Text('Inventory Cards'),
                        ),
                        ButtonSegment(
                          value: 1,
                          icon: Icon(Icons.edit_note_rounded),
                          label: Text('Manual Overrides'),
                        ),
                      ],
                      selected: {tab},
                      onSelectionChanged: (value) {
                        onTabChanged(value.first);
                      },
                    )
                  else
                    Expanded(
                      child: SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(
                            value: 0,
                            icon: Icon(Icons.inventory_2_rounded),
                            label: Text('Inventory Cards'),
                          ),
                          ButtonSegment(
                            value: 1,
                            icon: Icon(Icons.edit_note_rounded),
                            label: Text('Manual Overrides'),
                          ),
                        ],
                        selected: {tab},
                        onSelectionChanged: (value) {
                          onTabChanged(value.first);
                        },
                      ),
                    ),
                  SizedBox(width: compact ? 0 : 12, height: compact ? 12 : 0),
                  FilledButton.icon(
                    onPressed: onManualRule,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Manual Override'),
                    style: FilledButton.styleFrom(
                      backgroundColor: InvColors.brandGold,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(176, 44),
                      textStyle: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RuleSetupTitleRow extends StatelessWidget {
  const _RuleSetupTitleRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: InvColors.brandGoldLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: InvColors.brandGold.withValues(alpha: 0.24),
            ),
          ),
          child: const Icon(
            Icons.rule_folder_rounded,
            color: InvColors.brandGold,
            size: 29,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stock Alert Rule Setup',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: InvColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Inventory-linked alert levels for every metal and item card.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: InvColors.textBody,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _HeaderStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 136,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: InvStyles.cardLabel),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: InvColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RulePathHeader extends StatelessWidget {
  final String? selectedMetal;
  final LowStockStockCard? selectedGroup;
  final int metalCount;
  final int groupCount;
  final int itemCount;

  const _RulePathHeader({
    required this.selectedMetal,
    required this.selectedGroup,
    required this.metalCount,
    required this.groupCount,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    final group = selectedGroup;
    final metal = selectedMetal;
    final title = group != null
        ? '${group.metalType} / ${group.gradeLabel}'
        : metal != null
            ? _isSilver(metal)
                ? '$metal Item Cards'
                : '$metal Grade Cards'
            : 'Metal Stock Cards';
    final badge = group != null
        ? '$itemCount ITEMS'
        : metal != null
            ? _isSilver(metal)
                ? '$groupCount ITEMS'
                : '$groupCount GRADES'
            : '$metalCount METALS';
    final subtitle = group != null
        ? 'Item cards available for rule setup.'
        : metal != null
            ? 'Open a card to continue rule setup.'
            : 'Gold and Silver stock cards available for rule setup.';
    return LowStockPanel(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: InvColors.success.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_tree_rounded,
              color: InvColors.success,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: InvStyles.sectionTitle),
                const SizedBox(height: 3),
                Text(subtitle, style: InvStyles.cardNote),
              ],
            ),
          ),
          LowStockStatusPill(label: badge, color: InvColors.success),
        ],
      ),
    );
  }

  bool _isSilver(String metalType) {
    return metalType.trim().toLowerCase() == 'silver';
  }
}

class _AutoRuleBrowser extends StatelessWidget {
  final List<LowStockStockCard> metalCards;
  final List<LowStockStockCard> groupCards;
  final List<LowStockStockCard> itemCards;
  final String? selectedMetalType;
  final LowStockStockCard? selectedGroupCard;
  final ValueChanged<LowStockStockCard> onOpenMetal;
  final VoidCallback onBackToMetals;
  final ValueChanged<LowStockStockCard> onOpenGroup;
  final VoidCallback onBackToGrades;
  final ValueChanged<LowStockStockCard> onOpenItem;

  const _AutoRuleBrowser({
    required this.metalCards,
    required this.groupCards,
    required this.itemCards,
    required this.selectedMetalType,
    required this.selectedGroupCard,
    required this.onOpenMetal,
    required this.onBackToMetals,
    required this.onOpenGroup,
    required this.onBackToGrades,
    required this.onOpenItem,
  });

  @override
  Widget build(BuildContext context) {
    if (metalCards.isEmpty) {
      return const LowStockEmptyState(
        title: 'No Stock Found',
        subtitle: 'Inventory stock cards appear here after add-stock entry.',
      );
    }
    final selectedMetal = selectedMetalType;
    final selectedGroup = selectedGroupCard;
    if (selectedMetal == null) {
      return _RuleCardGrid(
        cards: metalCards,
        actionLabelBuilder: (card) => _isSilver(card.metalType)
            ? 'Open Silver Items'
            : 'Open ${card.metalType} Grades',
        onTap: onOpenMetal,
      );
    }
    if (selectedGroup != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AutoRuleBreadcrumb(
            title: '${selectedGroup.metalType} / ${selectedGroup.gradeLabel}',
            subtitle:
                '${itemCards.length} item cards. Select item type to set alert levels.',
            badge: '${itemCards.length} ITEMS',
            onBack: onBackToGrades,
          ),
          const SizedBox(height: 14),
          if (itemCards.isEmpty)
            LowStockEmptyState(
              title: 'No ${selectedGroup.gradeLabel} Item Stock',
              subtitle: 'This grade has no item-type stock card right now.',
            )
          else
            _RuleCardGrid(
              cards: itemCards,
              actionLabelBuilder: (_) => 'Set Alert Rule',
              onTap: onOpenItem,
            ),
        ],
      );
    }
    final isSilver = _isSilver(selectedMetal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AutoRuleBreadcrumb(
          title: isSilver
              ? '$selectedMetal Item Stock'
              : '$selectedMetal Grade Stock',
          subtitle: isSilver
              ? '${groupCards.length} item type cards. Select an item to set alert levels.'
              : '${groupCards.length} grade cards. Select a grade to open item type cards.',
          badge: isSilver
              ? '${groupCards.length} ITEMS'
              : '${groupCards.length} GRADES',
          onBack: onBackToMetals,
        ),
        const SizedBox(height: 14),
        if (groupCards.isEmpty)
          LowStockEmptyState(
            title: isSilver
                ? 'No $selectedMetal Item Stock'
                : 'No $selectedMetal Grade Stock',
            subtitle: 'This metal has no stock card right now.',
          )
        else
          _RuleCardGrid(
            cards: groupCards,
            actionLabelBuilder: (card) =>
                card.level == LowStockCardLevel.itemGroup
                    ? 'Set Alert Rule'
                    : 'Open Item Types',
            onTap: onOpenGroup,
          ),
      ],
    );
  }

  bool _isSilver(String metalType) {
    return metalType.trim().toLowerCase() == 'silver';
  }
}

class _RuleCardGrid extends StatelessWidget {
  final List<LowStockStockCard> cards;
  final String Function(LowStockStockCard card) actionLabelBuilder;
  final ValueChanged<LowStockStockCard> onTap;

  const _RuleCardGrid({
    required this.cards,
    required this.actionLabelBuilder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 1260
            ? (constraints.maxWidth - 32) / 3
            : constraints.maxWidth >= 820
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final card in cards)
              SizedBox(
                width: width,
                child: LowStockRuleSetupCard(
                  card: card,
                  actionLabel: actionLabelBuilder(card),
                  onTap: () => onTap(card),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AutoRuleBreadcrumb extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onBack;

  const _AutoRuleBreadcrumb({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return LowStockPanel(
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: 'Back to metals',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: InvStyles.sectionTitle),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: InvStyles.cardNote,
                ),
              ],
            ),
          ),
          LowStockStatusPill(
            label: badge,
            color: InvColors.success,
          ),
        ],
      ),
    );
  }
}

class _ManualRuleList extends StatelessWidget {
  final List<LowStockAlertRule> rules;
  final void Function({LowStockAlertRule rule}) onTap;

  const _ManualRuleList({required this.rules, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (rules.isEmpty) {
      return const LowStockEmptyState(
        title: 'No Manual Rules',
        subtitle:
            'Use stock cards to set your own red, yellow and green levels.',
      );
    }
    return Column(
      children: [
        for (final rule in rules) ...[
          _RuleTile(
            title: rule.scopeLabel,
            subtitle:
                'Red ${rule.criticalUnits} | Yellow ${rule.thresholdUnits} | Target ${rule.targetUnits}',
            badge: 'MANUAL',
            color: InvColors.brandGold,
            onTap: () => onTap(rule: rule),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _RuleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final Color color;
  final VoidCallback onTap;

  const _RuleTile({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.28)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.rule_rounded, color: color, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: InvStyles.itemName),
                    const SizedBox(height: 4),
                    Text(subtitle, style: InvStyles.itemSku),
                  ],
                ),
              ),
              LowStockStatusPill(label: badge, color: color),
              const SizedBox(width: 10),
              Icon(Icons.arrow_forward_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
