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
        subtitle:
            'Restore a verified local backup or a backup from your Google account.',
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
                      label: const Text('Restore Local File')),
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
          border: Border.all(color: BackupWorkspaceTheme.border),
          borderRadius: BorderRadius.circular(12)),
      child: LayoutBuilder(builder: (context, constraints) {
        final details =
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              DateFormat('d MMM yyyy · h:mm a')
                  .format(record.createdAt.toLocal()),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(
              '${_size(record.size)}  ·  Verified backup${record.driveId != null ? '  ·  Google Drive' : '  ·  Local'}',
              style: const TextStyle(
                  fontSize: 12, color: BackupWorkspaceTheme.muted)),
          if (record.cloudError != null) ...[
            const SizedBox(height: 5),
            const Text('Local backup saved · Drive upload needs a retry',
                style: TextStyle(fontSize: 12, color: Color(0xFFB45309)))
          ],
          if (record.missingMediaCount > 0) ...[
            const SizedBox(height: 5),
            Text(
                '${record.missingMediaCount} linked media files were unavailable',
                style: const TextStyle(fontSize: 12, color: Color(0xFFB45309))),
          ],
        ]);
        final actions = Wrap(spacing: 8, runSpacing: 6, children: [
          if (onRetryUpload != null)
            TextButton.icon(
                onPressed: enabled ? onRetryUpload : null,
                icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                label: const Text('Retry Upload')),
          OutlinedButton.icon(
              onPressed: enabled ? onRestore : null,
              icon: const Icon(Icons.restore_rounded, size: 18),
              label: const Text('Restore')),
        ]);
        if (constraints.maxWidth < 660) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [details, const SizedBox(height: 12), actions]);
        }
        return Row(children: [
          const Icon(Icons.verified_outlined,
              color: BackupWorkspaceTheme.green),
          const SizedBox(width: 14),
          Expanded(child: details),
          const SizedBox(width: 12),
          actions
        ]);
      }));
  String _size(int bytes) => bytes >= 1024 * 1024 * 1024
      ? '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB'
      : bytes >= 1024 * 1024
          ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
          : '${(bytes / 1024).toStringAsFixed(1)} KB';
}
