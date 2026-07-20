import 'package:flutter/material.dart';

import 'package:lotus_erp/features/stock/shared/application/low_stock_alert_controller.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/low_stock_alert/low_stock_alert_models.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/app_bar/low_stock_alert_app_bar.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/screens/low_stock_manual_rule_editor_screen.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/widgets/low_stock_alert_widgets.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/widgets/low_stock_smart_card.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: InvColors.brandGold,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Manual Rule'),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: LowStockPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LowStockSectionHeader(
                      icon: Icons.rule_folder_rounded,
                      title: 'Stock Alert Rule Studio',
                      subtitle:
                          'Choose stock from inventory, then set when low-stock alerts should start.',
                      trailing: LowStockStatusPill(
                        label: _tab == 0 ? 'INVENTORY' : 'SAVED',
                        color:
                            _tab == 0 ? InvColors.success : InvColors.brandGold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(
                          value: 0,
                          icon: Icon(Icons.inventory_2_rounded),
                          label: Text('Inventory Stock'),
                        ),
                        ButtonSegment(
                          value: 1,
                          icon: Icon(Icons.edit_note_rounded),
                          label: Text('Saved Rules'),
                        ),
                      ],
                      selected: {_tab},
                      onSelectionChanged: (value) {
                        setState(() => _tab = value.first);
                      },
                    ),
                  ],
                ),
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
                child: LowStockSmartCard(
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
