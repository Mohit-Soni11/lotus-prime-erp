import 'package:flutter/material.dart';

import '../../../models/reports/day_book/day_book_models.dart';
import '../../../models/reports/day_book/day_book_receipts_register.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_receipts_register_metrics.dart';
import 'day_book_receipts_register_table.dart';

class DayBookReceiptsRegisterPanel extends StatefulWidget {
  const DayBookReceiptsRegisterPanel({
    super.key,
    required this.summary,
    this.register,
    this.initialTab = DayBookRegisterTab.due,
    this.showExpandAction = true,
  });

  final DayBookSummary summary;
  final DayBookReceiptsRegister? register;
  final DayBookRegisterTab initialTab;
  final bool showExpandAction;

  @override
  State<DayBookReceiptsRegisterPanel> createState() =>
      _DayBookReceiptsRegisterPanelState();
}

class _DayBookReceiptsRegisterPanelState
    extends State<DayBookReceiptsRegisterPanel> {
  late DayBookRegisterTab _selected = widget.initialTab;
  int _visibleCount = 30;

  void _expand() {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: DayBookColors.bodyBg,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1450, maxHeight: 800),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Close expanded view',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            Flexible(
                child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: DayBookReceiptsRegisterPanel(
                summary: widget.summary,
                register: widget.register,
                initialTab: _selected,
                showExpandAction: false,
              ),
            )),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final register =
        widget.register ?? DayBookReceiptsRegister.fromSummary(widget.summary);
    final count = switch (_selected) {
      DayBookRegisterTab.due => register.dues.length,
      DayBookRegisterTab.received => register.received.length,
      DayBookRegisterTab.expense => register.expenses.length,
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 17),
      decoration: DayBookStyles.panel(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            width: 35,
            height: 35,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DayBookColors.brandGoldSoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.receipt_long_outlined,
                color: DayBookColors.goldMetal, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text('Receipts, Dues & Expenses',
                  style: DayBookStyles.sectionTitle.copyWith(fontSize: 18))),
          if (widget.showExpandAction)
            IconButton(
              tooltip: 'Expand records',
              onPressed: _expand,
              icon: const Icon(Icons.open_in_full_rounded,
                  color: DayBookColors.goldMetal, size: 18),
            ),
        ]),
        const SizedBox(height: 12),
        _RegisterTabs(
          register: register,
          selected: _selected,
          onSelected: (tab) => setState(() {
            _selected = tab;
            _visibleCount = 30;
          }),
        ),
        const SizedBox(height: 12),
        DayBookReceiptsRegisterMetrics(register: register, tab: _selected),
        const SizedBox(height: 10),
        if (count == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: Text('No records for this day.',
                    style: DayBookStyles.label)),
          )
        else
          DayBookReceiptsRegisterTable(
            register: register,
            summary: widget.summary,
            tab: _selected,
            visibleCount: _visibleCount,
          ),
        if (count > _visibleCount)
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: () => setState(() => _visibleCount += 30),
              icon: const Icon(Icons.expand_more_rounded),
              label: Text('Show more · ${count - _visibleCount} remaining'),
            ),
          ),
      ]),
    );
  }
}

class _RegisterTabs extends StatelessWidget {
  const _RegisterTabs({
    required this.register,
    required this.selected,
    required this.onSelected,
  });

  final DayBookReceiptsRegister register;
  final DayBookRegisterTab selected;
  final ValueChanged<DayBookRegisterTab> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final inline = constraints.maxWidth >= 650;
          final row = Row(children: [
            for (final tab in DayBookRegisterTab.values)
              inline
                  ? Expanded(child: _tab(tab))
                  : SizedBox(width: 220, child: _tab(tab)),
          ]);
          return ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Container(
              height: 37,
              decoration: BoxDecoration(
                border: Border.all(color: DayBookColors.bodyBorder),
                borderRadius: BorderRadius.circular(9),
              ),
              child: inline
                  ? row
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal, child: row),
            ),
          );
        },
      );

  Widget _tab(DayBookRegisterTab tab) {
    final active = selected == tab;
    final (label, icon, count) = switch (tab) {
      DayBookRegisterTab.due => (
          'Today Due',
          Icons.schedule_rounded,
          register.dues.length
        ),
      DayBookRegisterTab.received => (
          'Received',
          Icons.check_rounded,
          register.received.length
        ),
      DayBookRegisterTab.expense => (
          'Expense',
          Icons.receipt_long_outlined,
          register.expenses.length
        ),
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('register-tab-${tab.name}'),
        onTap: () => onSelected(tab),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(colors: [
                    Color(0xFFB77C0B),
                    Color(0xFFD9A72F),
                  ])
                : null,
            border: const Border(
                right: BorderSide(color: DayBookColors.bodyBorder)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon,
                size: 17,
                color: active ? Colors.white : DayBookColors.goldMetal),
            const SizedBox(width: 7),
            Text('$label ($count)',
                style: DayBookStyles.labelStrong.copyWith(
                  fontSize: 13,
                  color: active ? Colors.white : DayBookColors.textPrimary,
                )),
          ]),
        ),
      ),
    );
  }
}
