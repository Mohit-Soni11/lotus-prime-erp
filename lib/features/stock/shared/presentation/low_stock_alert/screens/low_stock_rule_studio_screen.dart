import 'package:flutter/material.dart';

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

    return Scaffold(
      backgroundColor: InvColors.bodyBg,
      appBar: LowStockAlertAppBar(
        onBack: () => _handleBack(context),
        onRefresh: widget.controller.load,
        title: _pageTitle(selectedAutoMetal, selectedAutoGroup),
        icon: Icons.rule_folder_rounded,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
            sliver: SliverToBoxAdapter(
              child: _AutoRuleBrowser(
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
                onOpenGroup: (card) {
                  if (card.level == LowStockCardLevel.itemGroup) {
                    _openEditor(autoCard: card);
                    return;
                  }
                  setState(() => _autoGroupKey = _groupKey(card));
                },
                onOpenItem: (card) => _openEditor(autoCard: card),
              ),
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

  void _handleBack(BuildContext context) {
    if (_autoGroupKey != null) {
      setState(() => _autoGroupKey = null);
      return;
    }
    if (_autoMetalType != null) {
      setState(() {
        _autoMetalType = null;
        _autoGroupKey = null;
      });
      return;
    }
    Navigator.of(context).maybePop();
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

  String _pageTitle(String? selectedMetal, LowStockStockCard? selectedGroup) {
    if (selectedGroup != null) {
      if (selectedGroup.level == LowStockCardLevel.itemGroup) {
        return '${selectedGroup.title} Rule Setup';
      }
      return '${selectedGroup.gradeLabel} Item Stock';
    }
    if (selectedMetal != null) {
      return selectedMetal.trim().toLowerCase() == 'silver'
          ? 'Silver Item Stock'
          : '$selectedMetal Grade Stock';
    }
    return 'Stock Alert Rule Setup';
  }
}

class _AutoRuleBrowser extends StatelessWidget {
  final List<LowStockStockCard> metalCards;
  final List<LowStockStockCard> groupCards;
  final List<LowStockStockCard> itemCards;
  final String? selectedMetalType;
  final LowStockStockCard? selectedGroupCard;
  final ValueChanged<LowStockStockCard> onOpenMetal;
  final ValueChanged<LowStockStockCard> onOpenGroup;
  final ValueChanged<LowStockStockCard> onOpenItem;

  const _AutoRuleBrowser({
    required this.metalCards,
    required this.groupCards,
    required this.itemCards,
    required this.selectedMetalType,
    required this.selectedGroupCard,
    required this.onOpenMetal,
    required this.onOpenGroup,
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
      if (itemCards.isEmpty) {
        return LowStockEmptyState(
          title: 'No ${selectedGroup.gradeLabel} Item Stock',
          subtitle: 'This grade has no item-type stock card right now.',
        );
      }
      return _RuleCardGrid(
        cards: itemCards,
        actionLabelBuilder: (_) => 'Set Alert Rule',
        onTap: onOpenItem,
      );
    }
    final isSilver = _isSilver(selectedMetal);
    if (groupCards.isEmpty) {
      return LowStockEmptyState(
        title: isSilver
            ? 'No $selectedMetal Item Stock'
            : 'No $selectedMetal Grade Stock',
        subtitle: 'This metal has no stock card right now.',
      );
    }
    return _RuleCardGrid(
      cards: groupCards,
      actionLabelBuilder: (card) => card.level == LowStockCardLevel.itemGroup
          ? 'Set Alert Rule'
          : 'Open Item Types',
      onTap: onOpenGroup,
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
