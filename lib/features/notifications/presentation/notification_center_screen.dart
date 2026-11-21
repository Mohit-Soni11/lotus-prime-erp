import 'package:flutter/material.dart';
import '../domain/notification_item.dart';
import 'notification_theme.dart';
import 'notification_view_state.dart';
import 'widgets/notification_card.dart';
import 'widgets/notification_toolbar.dart';

class NotificationCenterScreen extends StatefulWidget {
  final Stream<List<NotificationItem>> stream;
  final List<NotificationItem> initialItems;
  final Object? initialError;
  final ScrollController? scrollController;
  final NotificationViewState? viewState;
  final Future<void> Function() onMarkAllRead;
  final Future<void> Function()? onClearMessages;
  final Future<void> Function()? onRefresh;
  final Future<void> Function(NotificationItem)? onMarkRead;
  final ValueChanged<NotificationItem> onSelect;
  const NotificationCenterScreen(
      {super.key,
      required this.stream,
      required this.initialItems,
      this.initialError,
      this.scrollController,
      this.viewState,
      required this.onMarkAllRead,
      this.onClearMessages,
      this.onRefresh,
      this.onMarkRead,
      required this.onSelect});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  bool _busy = false;
  bool _opening = false;
  String? _actionError;
  late final _view = widget.viewState ?? NotificationViewState();

  Future<bool> _run(Future<void> Function() action) async {
    if (_busy) return false;
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      await action();
      return true;
    } catch (_) {
      if (mounted) {
        setState(() =>
            _actionError = 'The action could not be saved. Please try again.');
      }
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(NotificationItem item) async {
    if (_opening || _busy) return;
    setState(() => _opening = true);
    if (widget.onMarkRead != null && !item.isRead) {
      if (!await _run(() => widget.onMarkRead!(item))) {
        if (mounted) setState(() => _opening = false);
        return;
      }
    }
    if (mounted) widget.onSelect(item);
  }

  Future<void> _clearMessages() async {
    if (widget.onClearMessages == null) return;
    if (await _run(widget.onClearMessages!) && mounted) {
      setState(_view.resetFilters);
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
      insetPadding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Theme(
          data: ThemeData.dark(useMaterial3: true).copyWith(
              scaffoldBackgroundColor: NotificationTheme.background,
              colorScheme: ColorScheme.fromSeed(
                  seedColor: NotificationTheme.gold,
                  brightness: Brightness.dark)),
          child: Scaffold(
            appBar: AppBar(
                backgroundColor: NotificationTheme.shell,
                foregroundColor: Colors.white,
                leading: IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded)),
                title: const Text('Notifications',
                    style:
                        TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                actions: [
                  IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded))
                ]),
            body: SafeArea(
                child: StreamBuilder<List<NotificationItem>>(
              stream: widget.stream,
              initialData: widget.initialItems,
              builder: (context, snapshot) {
                final items = [...?snapshot.data]
                  ..sort(NotificationItem.compare);
                final failed = snapshot.hasError ||
                    (snapshot.connectionState == ConnectionState.waiting &&
                        widget.initialError != null);
                final visible = items
                    .where((item) =>
                        (_view.filter == 'All' ||
                            (_view.filter == 'Important' && item.isProtected) ||
                            (_view.filter == 'Unread' && !item.isRead) ||
                            item.type == _view.filter) &&
                        '${item.title} ${item.desc}'
                            .toLowerCase()
                            .contains(_view.search.toLowerCase()))
                    .toList();
                return CustomScrollView(
                  key: const PageStorageKey('notification-list-scroll'),
                  controller: widget.scrollController,
                  slivers: [
                    SliverPadding(
                        padding: const EdgeInsets.all(14),
                        sliver: SliverToBoxAdapter(
                          child: NotificationToolbar(
                              items: items,
                              view: _view,
                              onViewChanged: () => setState(() {}),
                              busy: _busy,
                              error: _actionError,
                              onMarkAllRead: _busy || failed
                                  ? null
                                  : () => _run(widget.onMarkAllRead),
                              onClearMessages: _busy ||
                                      failed ||
                                      widget.onClearMessages == null
                                  ? null
                                  : _clearMessages,
                              onRefresh: _busy || widget.onRefresh == null
                                  ? null
                                  : () => _run(widget.onRefresh!)),
                        )),
                    if (failed || visible.isEmpty)
                      SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                              child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                      failed
                                          ? 'Notifications could not be loaded. Use Refresh to try again.'
                                          : items.isEmpty
                                              ? 'All caught up'
                                              : 'No notifications match this view.',
                                      style: const TextStyle(
                                          color: NotificationTheme.muted)))))
                    else
                      SliverPadding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                          sliver: SliverList.separated(
                              itemCount: visible.length,
                              separatorBuilder: (_, __) => const Divider(
                                  height: 1, color: NotificationTheme.border),
                              itemBuilder: (_, index) {
                                final item = visible[index];
                                return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (index == 0 ||
                                          (visible[index - 1].sortRank < 10) !=
                                              (item.sortRank < 10))
                                        Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10),
                                            child: Text(
                                                item.sortRank < 10
                                                    ? 'DAILY ESSENTIALS'
                                                    : 'ACTIVITY & ALERTS',
                                                style: const TextStyle(
                                                    color:
                                                        NotificationTheme.muted,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 1))),
                                      NotificationCard(
                                          item: item,
                                          onOpen:
                                              _busy || _opening || !item.canOpen
                                                  ? null
                                                  : () => _open(item),
                                          onMarkRead: _busy ||
                                                  widget.onMarkRead == null
                                              ? null
                                              : () => _run(() =>
                                                  widget.onMarkRead!(item))),
                                    ]);
                              })),
                  ],
                );
              },
            )),
          ),
        ),
      ));
}
