import 'package:flutter/material.dart';
import '../domain/notification_item.dart';
import '../domain/notification_filters.dart';
import 'notification_theme.dart';
import 'notification_view_state.dart';
import 'widgets/notification_header.dart';
import 'widgets/notification_list.dart';
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

  bool _matches(NotificationItem item) =>
      NotificationFilters.matches(_view.filter, item) &&
      '${item.title} ${item.desc}'
          .toLowerCase()
          .contains(_view.search.trim().toLowerCase());

  @override
  Widget build(BuildContext context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 800),
        backgroundColor: NotificationTheme.background,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: NotificationTheme.border)),
        child: SizedBox(
          width: 720,
          height: MediaQuery.sizeOf(context).height * 0.86,
          child: Theme(
            data: NotificationTheme.data(Theme.of(context)),
            child: Scaffold(
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
                final visible = items.where(_matches).toList();
                final enabled = !_busy && !_opening;
                return Column(children: [
                  NotificationHeader(
                      items: items, onClose: () => Navigator.pop(context)),
                  const Divider(height: 1, color: NotificationTheme.border),
                  Expanded(
                      child: CustomScrollView(
                    key: const PageStorageKey('notification-list-scroll'),
                    controller: widget.scrollController,
                    slivers: [
                      SliverPadding(
                          padding: const EdgeInsets.all(18),
                          sliver: SliverToBoxAdapter(
                            child: NotificationToolbar(
                              items: items,
                              view: _view,
                              onViewChanged: () => setState(() {}),
                              busy: _busy,
                              error: _actionError,
                              onMarkAllRead: enabled && !failed
                                  ? () => _run(widget.onMarkAllRead)
                                  : null,
                              onClearMessages: enabled &&
                                      !failed &&
                                      widget.onClearMessages != null
                                  ? _clearMessages
                                  : null,
                              onRefresh: enabled && widget.onRefresh != null
                                  ? () => _run(widget.onRefresh!)
                                  : null,
                            ),
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
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: NotificationTheme.muted),
                                  ))),
                        )
                      else
                        NotificationList(
                          items: visible,
                          enabled: enabled,
                          onOpen: _open,
                          onMarkRead: widget.onMarkRead == null
                              ? null
                              : (item) => _run(() => widget.onMarkRead!(item)),
                        ),
                    ],
                  )),
                ]);
              },
            ))),
          ),
        ),
      );
}
