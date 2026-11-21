import 'package:flutter/material.dart';
import '../../domain/notification_item.dart';
import '../../domain/notification_filters.dart';
import '../notification_theme.dart';
import '../notification_view_state.dart';

class NotificationToolbar extends StatelessWidget {
  final List<NotificationItem> items;
  final NotificationViewState view;
  final VoidCallback onViewChanged;
  final VoidCallback? onMarkAllRead;
  final VoidCallback? onClearMessages;
  final VoidCallback? onRefresh;
  final bool busy;
  final String? error;

  const NotificationToolbar(
      {super.key,
      required this.items,
      required this.view,
      required this.onViewChanged,
      this.onMarkAllRead,
      this.onClearMessages,
      this.onRefresh,
      this.busy = false,
      this.error});

  @override
  Widget build(BuildContext context) {
    final canRead = items.any((item) => !item.isRead) && onMarkAllRead != null;
    final filters = NotificationFilters.options(items);
    final buttonStyle = OutlinedButton.styleFrom(
      foregroundColor: NotificationTheme.ink,
      side: const BorderSide(color: NotificationTheme.border),
      minimumSize: const Size(0, 48),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: Theme.of(context)
          .textTheme
          .labelMedium
          ?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(
            child: DecoratedBox(
          decoration: BoxDecoration(
              gradient: NotificationTheme.goldGradient,
              borderRadius: BorderRadius.circular(12)),
          child: TextButton.icon(
              onPressed: canRead ? onMarkAllRead : null,
              style: TextButton.styleFrom(
                  foregroundColor: NotificationTheme.onGold,
                  disabledForegroundColor:
                      NotificationTheme.onGold.withValues(alpha: 0.65),
                  minimumSize: const Size(0, 48),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(fontSize: 12, fontWeight: FontWeight.w700)),
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Mark all read', textAlign: TextAlign.center)),
        )),
        const SizedBox(width: 8),
        Expanded(
            child: OutlinedButton.icon(
                onPressed: items.every((item) => item.isProtected)
                    ? null
                    : onClearMessages,
                style: buttonStyle,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label:
                    const Text('Clear messages', textAlign: TextAlign.center))),
        const SizedBox(width: 8),
        SizedBox(
            width: 48,
            height: 48,
            child: IconButton.outlined(
                tooltip: 'Refresh',
                onPressed: onRefresh,
                style: IconButton.styleFrom(
                    foregroundColor: NotificationTheme.ink,
                    side: const BorderSide(color: NotificationTheme.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                icon: const Icon(Icons.refresh_rounded, size: 23))),
      ]),
      const SizedBox(height: 16),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: TextFormField(
                // EditableText owns a scroll position; isolate it from the list.
                key: PageStorageKey(
                    'notification-search-${view.searchRevision}'),
                initialValue: view.search,
                style:
                    const TextStyle(color: NotificationTheme.ink, fontSize: 13),
                onChanged: (value) {
                  view.search = value;
                  onViewChanged();
                },
                decoration: const InputDecoration(
                    hintText: 'Search notifications...',
                    prefixIcon: Icon(Icons.search_rounded, size: 22),
                    isDense: true))),
        const SizedBox(width: 10),
        PopupMenuButton<String>(
          tooltip: 'Filter notifications',
          initialValue: view.filter,
          color: NotificationTheme.surface,
          constraints: const BoxConstraints(minWidth: 190, maxHeight: 400),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: NotificationTheme.border)),
          onSelected: (filter) {
            view.filter = filter;
            onViewChanged();
          },
          itemBuilder: (_) => [
            for (final filter in filters)
              PopupMenuItem(
                  value: filter,
                  child: Row(children: [
                    Expanded(
                        child: Text(filter,
                            style:
                                const TextStyle(color: NotificationTheme.ink))),
                    if (filter == view.filter)
                      const Icon(Icons.check_rounded,
                          size: 18, color: NotificationTheme.gold),
                  ]))
          ],
          child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                  color: NotificationTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: view.filter == 'All'
                          ? NotificationTheme.border
                          : NotificationTheme.gold)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.filter_alt_outlined,
                    size: 20, color: NotificationTheme.ink),
                SizedBox(width: 6),
                Text('Filters',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: NotificationTheme.muted),
              ])),
        ),
      ]),
      if (view.filter != 'All')
        Align(
            alignment: Alignment.centerLeft,
            child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: InputChip(
                    label: Text(view.filter),
                    onDeleted: () {
                      view.filter = 'All';
                      onViewChanged();
                    },
                    deleteButtonTooltipMessage: 'Show all notifications'))),
      if (busy)
        const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(minHeight: 2)),
      if (error != null)
        Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(error!,
                style: const TextStyle(
                    color: NotificationTheme.red, fontSize: 12))),
    ]);
  }
}
