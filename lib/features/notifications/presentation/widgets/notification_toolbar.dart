import 'package:flutter/material.dart';
import '../../domain/notification_item.dart';
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
    final unread = items.where((item) => !item.isRead).length;
    final important = items.where((item) => item.isProtected).length;
    final categories = items.map((item) => item.type).toSet().toList()..sort();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(
          '${items.length} notifications · $unread unread · $important important',
          style: const TextStyle(color: NotificationTheme.muted, fontSize: 12)),
      const SizedBox(height: 6),
      Wrap(spacing: 8, runSpacing: 4, children: [
        TextButton(
            onPressed: unread == 0 ? null : onMarkAllRead,
            style:
                TextButton.styleFrom(foregroundColor: NotificationTheme.gold),
            child: const Text('Mark all read')),
        TextButton(
            onPressed: items.every((item) => item.isProtected)
                ? null
                : onClearMessages,
            style:
                TextButton.styleFrom(foregroundColor: NotificationTheme.gold),
            child: const Text('Clear messages')),
        IconButton(
            tooltip: 'Refresh',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded,
                color: NotificationTheme.muted, size: 19)),
      ]),
      if (busy) const LinearProgressIndicator(),
      if (error != null)
        Text(error!, style: const TextStyle(color: NotificationTheme.red)),
      ExpansionTile(
        // Expansion and both scroll offsets must have separate storage paths.
        key: const PageStorageKey('notification-search-filters'),
        tilePadding: EdgeInsets.zero,
        initiallyExpanded: view.filter != 'All' || view.search.isNotEmpty,
        title: const Text('Search and filters',
            style: TextStyle(fontSize: 12, color: NotificationTheme.muted)),
        children: [
          TextFormField(
              key: PageStorageKey('notification-search-${view.searchRevision}'),
              initialValue: view.search,
              style:
                  const TextStyle(color: NotificationTheme.ink, fontSize: 13),
              onChanged: (value) {
                view.search = value;
                onViewChanged();
              },
              decoration: const InputDecoration(
                  hintText: 'Search notifications',
                  prefixIcon: Icon(Icons.search_rounded),
                  isDense: true)),
          const SizedBox(height: 8),
          SingleChildScrollView(
              key: const PageStorageKey('notification-filter-scroll'),
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final filter in [
                  'All',
                  'Important',
                  'Unread',
                  ...categories
                ])
                  Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                          label: Text(filter),
                          selected: view.filter == filter,
                          onSelected: (_) {
                            view.filter = filter;
                            onViewChanged();
                          })),
              ])),
        ],
      ),
    ]);
  }
}
