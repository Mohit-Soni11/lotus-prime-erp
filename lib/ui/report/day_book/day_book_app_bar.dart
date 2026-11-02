import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../logic/report/day_book/day_book_controller.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';

enum _ExportAction { pdf, csv, share }

class DayBookAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DayBookAppBar({
    super.key,
    required this.onBack,
    required this.onRefresh,
    required this.ctrl,
    required this.compact,
    this.onExportPdf,
    this.onExportCsv,
    this.onSharePdf,
  });

  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportCsv;
  final VoidCallback? onSharePdf;
  final DayBookController ctrl;
  final bool compact;

  @override
  Size get preferredSize => Size.fromHeight(compact ? 116 : 76);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
      decoration: const BoxDecoration(
        color: DayBookColors.shellPanel,
        border: Border(bottom: BorderSide(color: DayBookColors.shellBorder)),
        boxShadow: [
          BoxShadow(
              color: Color(0x26000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: ctrl,
          builder: (context, child) => compact
              ? Column(
                  children: [
                    Expanded(child: _identityAndActions()),
                    SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          _DateControl(ctrl: ctrl, compact: true),
                        ],
                      ),
                    ),
                  ],
                )
              : _identityAndActions(),
        ),
      ),
    );
  }

  Widget _identityAndActions() {
    return Row(
      children: [
        _HeaderIconButton(
          icon: DayBookIcons.back,
          tooltip: 'Back to previous screen',
          onPressed: onBack,
        ),
        SizedBox(width: compact ? 10 : 18),
        if (!compact) ...[
          Container(width: 1, height: 32, color: DayBookColors.shellBorder),
          const SizedBox(width: 18),
        ],
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DayBookColors.goldGradientStart,
                DayBookColors.brandGold
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(DayBookIcons.module, color: Colors.white, size: 18),
        ),
        SizedBox(width: compact ? 10 : 14),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DayBookStrings.moduleTitle,
                style: DayBookStyles.appBarTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!compact)
                Text(
                  DayBookStrings.moduleSubtitle,
                  style: DayBookStyles.appBarSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        if (!compact) ...[
          _DateControl(ctrl: ctrl, compact: false),
          const SizedBox(width: 10),
        ],
        _ExportMenu(
          onPdf: ctrl.summary == null ? null : onExportPdf,
          onCsv: ctrl.summary == null ? null : onExportCsv,
          onShare: ctrl.summary == null ? null : onSharePdf,
        ),
        const SizedBox(width: 6),
        _HeaderIconButton(
          icon: DayBookIcons.refresh,
          tooltip: DayBookStrings.refresh,
          onPressed: ctrl.isLoading ? null : onRefresh,
          loading: ctrl.isLoading,
        ),
      ],
    );
  }
}

class _ExportMenu extends StatelessWidget {
  const _ExportMenu({this.onPdf, this.onCsv, this.onShare});

  final VoidCallback? onPdf;
  final VoidCallback? onCsv;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ExportAction>(
      tooltip: 'Export Day Book',
      enabled: onPdf != null || onCsv != null || onShare != null,
      icon: const Icon(DayBookIcons.share, size: 18),
      style: IconButton.styleFrom(
        fixedSize: const Size(42, 42),
        backgroundColor: DayBookColors.shellBorder.withValues(alpha: 0.3),
        foregroundColor: DayBookColors.shellTitle,
        disabledForegroundColor: DayBookColors.shellMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: DayBookColors.shellBorder),
        ),
      ),
      onSelected: (action) {
        switch (action) {
          case _ExportAction.pdf:
            onPdf?.call();
          case _ExportAction.csv:
            onCsv?.call();
          case _ExportAction.share:
            onShare?.call();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _ExportAction.pdf,
          enabled: onPdf != null,
          child: const _ExportMenuLabel(
            icon: DayBookIcons.pdf,
            label: DayBookStrings.exportPdf,
          ),
        ),
        PopupMenuItem(
          value: _ExportAction.csv,
          enabled: onCsv != null,
          child: const _ExportMenuLabel(
            icon: DayBookIcons.table,
            label: DayBookStrings.exportCsv,
          ),
        ),
        PopupMenuItem(
          value: _ExportAction.share,
          enabled: onShare != null,
          child: const _ExportMenuLabel(
            icon: DayBookIcons.share,
            label: DayBookStrings.sharePdf,
          ),
        ),
      ],
    );
  }
}

class _ExportMenuLabel extends StatelessWidget {
  const _ExportMenuLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 12),
        Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _DateControl extends StatelessWidget {
  const _DateControl({required this.ctrl, required this.compact});

  final DayBookController ctrl;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dateLabel = ctrl.isToday
        ? 'Today'
        : DateFormat(compact ? 'd MMM yy' : 'd MMM yyyy')
            .format(ctrl.selectedDate);

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: DayBookColors.shellBg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: DayBookColors.shellBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DateButton(
            icon: DayBookIcons.previous,
            tooltip: 'Previous day',
            onPressed: ctrl.goToPreviousDay,
          ),
          Tooltip(
            message: DayBookStrings.chooseDate,
            child: InkWell(
              onTap: () => ctrl.selectDate(context),
              borderRadius: BorderRadius.circular(7),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!compact || ctrl.isToday) ...[
                      const Icon(
                        DayBookIcons.calendar,
                        size: 15,
                        color: DayBookColors.brandGold,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      dateLabel,
                      style: DayBookStyles.appBarSubtitle.copyWith(
                        color: DayBookColors.shellTitle,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _DateButton(
            icon: DayBookIcons.next,
            tooltip: 'Next day',
            onPressed: ctrl.canGoNext ? ctrl.goToNextDay : null,
          ),
          if (!ctrl.isToday) ...[
            Container(width: 1, height: 22, color: DayBookColors.shellBorder),
            _DateButton(
              icon: DayBookIcons.today,
              tooltip: DayBookStrings.returnToToday,
              onPressed: ctrl.goToToday,
            ),
          ],
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton(
      {required this.icon, required this.tooltip, this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
      style: IconButton.styleFrom(
        fixedSize: const Size(36, 36),
        foregroundColor: DayBookColors.shellMuted,
        disabledForegroundColor:
            DayBookColors.shellMuted.withValues(alpha: 0.35),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.loading = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: const Size(42, 42),
        backgroundColor: DayBookColors.shellBorder.withValues(alpha: 0.3),
        foregroundColor: DayBookColors.shellTitle,
        disabledForegroundColor:
            DayBookColors.shellMuted.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: DayBookColors.shellBorder),
        ),
      ),
      icon: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: DayBookColors.brandGold,
              ),
            )
          : Icon(icon, size: 19),
    );
  }
}
