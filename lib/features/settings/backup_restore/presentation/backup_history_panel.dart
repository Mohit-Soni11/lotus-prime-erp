import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/backup_record.dart';
import 'backup_workspace_theme.dart';

class BackupHistoryPanel extends StatefulWidget {
  const BackupHistoryPanel(
      {super.key,
      required this.local,
      required this.cloud,
      required this.enabled,
      required this.connected,
      required this.onRefreshCloud,
      required this.onRestore,
      required this.onRetryUpload,
      required this.onPickLocal});
  final List<BackupRecord> local, cloud;
  final bool enabled, connected;
  final VoidCallback onRefreshCloud, onPickLocal;
  final ValueChanged<BackupRecord> onRestore, onRetryUpload;
  @override
  State<BackupHistoryPanel> createState() => _BackupHistoryPanelState();
}

class _BackupHistoryPanelState extends State<BackupHistoryPanel> {
  bool _cloud = false;
  int _limit = 10;
  @override
  Widget build(BuildContext context) {
    final records = _cloud ? widget.cloud : widget.local;
    return BackupPanel(
        title: 'Backups & Recovery',
        icon: Icons.restore_rounded,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              children: [
                SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                          value: false,
                          icon: Icon(Icons.computer_rounded, size: 18),
                          label: Text('Local')),
                      ButtonSegment(
                          value: true,
                          icon: Icon(Icons.add_to_drive_rounded, size: 18),
                          label: Text('Google Drive')),
                    ],
                    selected: {
                      _cloud
                    },
                    onSelectionChanged: !widget.enabled
                        ? null
                        : (value) {
                            setState(() {
                              _cloud = value.single;
                              _limit = 10;
                            });
                            if (_cloud && widget.connected) {
                              widget.onRefreshCloud();
                            }
                          }),
                Wrap(spacing: 8, children: [
                  if (_cloud)
                    OutlinedButton.icon(
                        onPressed: widget.enabled && widget.connected
                            ? widget.onRefreshCloud
                            : null,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Refresh Drive')),
                  OutlinedButton.icon(
                      onPressed: widget.enabled ? widget.onPickLocal : null,
                      icon: const Icon(Icons.file_open_outlined, size: 18),
                      label: const Text('Restore Local File'),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: BackupWorkspaceTheme.gold))),
                ]),
              ]),
          const SizedBox(height: 16),
          if (records.isEmpty)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(children: [
                  Icon(
                      _cloud
                          ? Icons.cloud_outlined
                          : Icons.inventory_2_outlined,
                      size: 34,
                      color: BackupWorkspaceTheme.muted),
                  const SizedBox(height: 10),
                  Text(
                      _cloud && !widget.connected
                          ? 'Connect your Google account to view Drive backups.'
                          : 'No ${_cloud ? 'Google Drive' : 'local'} backups found.',
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: BackupWorkspaceTheme.muted)),
                ])),
          for (final record in records.take(_limit))
            _BackupHistoryRow(
                record: record,
                enabled: widget.enabled,
                onRestore: () => widget.onRestore(record),
                onRetryUpload: widget.connected &&
                        record.localPath != null &&
                        record.cloudError != null
                    ? () => widget.onRetryUpload(record)
                    : null),
          if (records.length > _limit)
            TextButton(
                onPressed: () => setState(() => _limit += 10),
                child: const Text('Show More Backups')),
        ]));
  }
}

class _BackupHistoryRow extends StatelessWidget {
  const _BackupHistoryRow(
      {required this.record,
      required this.enabled,
      required this.onRestore,
      this.onRetryUpload});
  final BackupRecord record;
  final bool enabled;
  final VoidCallback onRestore;
  final VoidCallback? onRetryUpload;
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: BackupWorkspaceTheme.surfaceLow,
          border: Border.all(color: BackupWorkspaceTheme.border),
          borderRadius: BorderRadius.circular(12)),
      child: LayoutBuilder(builder: (context, constraints) {
        final date = Text(
            DateFormat('d MMM yyyy, hh:mm a')
                .format(record.createdAt.toLocal()),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800));
        final size = Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.storage_rounded, size: 20),
          const SizedBox(width: 8),
          Text(_size(record.size),
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ]);
        final actions = Wrap(spacing: 8, runSpacing: 6, children: [
          if (onRetryUpload != null)
            OutlinedButton.icon(
                onPressed: enabled ? onRetryUpload : null,
                icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                label: const Text('Retry Upload')),
          FilledButton.icon(
              onPressed: enabled ? onRestore : null,
              icon: const Icon(Icons.restore_rounded, size: 18),
              label: const Text('Restore')),
        ]);
        final warnings = <Widget>[
          if (record.cloudError != null)
            const Text('Drive upload needs a retry. Local copy is safe.',
                style:
                    TextStyle(fontSize: 13, color: BackupWorkspaceTheme.amber)),
          if (record.missingMediaCount > 0)
            Text(
                '${record.missingMediaCount} linked media files were unavailable',
                style: const TextStyle(
                    fontSize: 13, color: BackupWorkspaceTheme.amber)),
        ];
        if (constraints.maxWidth < (onRetryUpload == null ? 660 : 840)) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.check_circle_rounded,
                      color: BackupWorkspaceTheme.green),
                  const SizedBox(width: 10),
                  Expanded(child: date),
                ]),
                const SizedBox(height: 10),
                size,
                for (final warning in warnings) ...[
                  const SizedBox(height: 6),
                  warning,
                ],
                const SizedBox(height: 12),
                actions,
              ]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: BackupWorkspaceTheme.green),
            const SizedBox(width: 14),
            Expanded(child: date),
            Container(width: 1, height: 28, color: BackupWorkspaceTheme.border),
            const SizedBox(width: 30),
            Expanded(child: size),
            actions,
          ]),
          for (final warning in warnings) ...[
            const SizedBox(height: 8),
            warning,
          ],
        ]);
      }));
  String _size(int bytes) => bytes >= 1024 * 1024 * 1024
      ? '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB'
      : bytes >= 1024 * 1024
          ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
          : '${(bytes / 1024).toStringAsFixed(1)} KB';
}
