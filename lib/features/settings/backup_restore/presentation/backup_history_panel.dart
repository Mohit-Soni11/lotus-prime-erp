import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/backup_record.dart';
import 'backup_workspace_theme.dart';

class BackupHistoryPanel extends StatefulWidget {
  const BackupHistoryPanel({
    super.key,
    required this.records,
    required this.enabled,
    required this.connected,
    required this.onRefreshCloud,
    required this.onRestore,
    required this.onRetryUpload,
    required this.onPickLocal,
  });

  final List<BackupRecord> records;
  final bool enabled;
  final bool connected;
  final VoidCallback onRefreshCloud;
  final VoidCallback onPickLocal;
  final ValueChanged<BackupRecord> onRestore;
  final ValueChanged<BackupRecord> onRetryUpload;

  @override
  State<BackupHistoryPanel> createState() => _BackupHistoryPanelState();
}

class _BackupHistoryPanelState extends State<BackupHistoryPanel> {
  int _limit = 10;

  @override
  Widget build(BuildContext context) => BackupPanel(
        title: 'Backups & Recovery',
        icon: Icons.storage_rounded,
        trailing: Wrap(spacing: 8, children: [
          if (widget.connected)
            IconButton(
              tooltip: 'Refresh Google Drive backups',
              onPressed: widget.enabled ? widget.onRefreshCloud : null,
              icon: const Icon(Icons.refresh_rounded),
              style: IconButton.styleFrom(
                foregroundColor: BackupWorkspaceTheme.amber,
                side: const BorderSide(color: BackupWorkspaceTheme.gold),
              ),
            ),
          OutlinedButton.icon(
            onPressed: widget.enabled ? widget.onPickLocal : null,
            icon: const Icon(Icons.file_open_outlined, size: 18),
            label: const Text('Restore Backup File'),
            style: OutlinedButton.styleFrom(
              foregroundColor: BackupWorkspaceTheme.ink,
              side: const BorderSide(color: BackupWorkspaceTheme.gold),
            ),
          ),
        ]),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (widget.records.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: _EmptyBackupHistory(),
            ),
          for (final record in widget.records.take(_limit))
            _BackupHistoryRow(
              record: record,
              enabled: widget.enabled,
              onRestore: () => widget.onRestore(record),
              onRetryUpload: widget.connected &&
                      record.localPath != null &&
                      record.cloudError != null
                  ? () => widget.onRetryUpload(record)
                  : null,
            ),
          if (widget.records.length > _limit)
            TextButton(
              onPressed: () => setState(() => _limit += 10),
              child: const Text('Show More Backups'),
            ),
        ]),
      );
}

class _EmptyBackupHistory extends StatelessWidget {
  const _EmptyBackupHistory();

  @override
  Widget build(BuildContext context) => const Column(children: [
        _BackupIcon(icon: Icons.inventory_2_outlined, size: 24),
        SizedBox(height: 10),
        Text('No backups found.',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: BackupWorkspaceTheme.ink)),
        SizedBox(height: 4),
        Text('Create a backup or restore a backup file.',
            style: TextStyle(fontSize: 13, color: BackupWorkspaceTheme.muted)),
      ]);
}

class _BackupHistoryRow extends StatelessWidget {
  const _BackupHistoryRow({
    required this.record,
    required this.enabled,
    required this.onRestore,
    this.onRetryUpload,
  });

  final BackupRecord record;
  final bool enabled;
  final VoidCallback onRestore;
  final VoidCallback? onRetryUpload;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: BackupWorkspaceTheme.surface,
          border: Border.all(color: BackupWorkspaceTheme.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          final primary = _BackupIdentity(record: record);
          final actions = Wrap(spacing: 8, runSpacing: 8, children: [
            if (onRetryUpload != null)
              OutlinedButton.icon(
                onPressed: enabled ? onRetryUpload : null,
                icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                label: const Text('Retry Upload'),
              ),
            FilledButton.icon(
              onPressed: enabled ? onRestore : null,
              icon: const Icon(Icons.restore_rounded, size: 18),
              label: const Text('Restore'),
              style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
            ),
          ]);
          final warning = record.cloudError == null
              ? null
              : const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                      'Google Drive upload needs a retry. Local copy is safe.',
                      style: TextStyle(
                          fontSize: 13, color: BackupWorkspaceTheme.amber)),
                );

          if (constraints.maxWidth < 760) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  primary,
                  if (warning != null) warning,
                  if (record.missingMediaCount > 0) _MissingMediaNotice(record),
                  const SizedBox(height: 14),
                  actions,
                ]);
          }
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(flex: 5, child: primary),
                  _VerticalDivider(),
                  Expanded(
                      flex: 2,
                      child: _BackupMetric(
                        icon: Icons.storage_rounded,
                        value: _size(record.size),
                      )),
                  const SizedBox(width: 16),
                  actions,
                ]),
                if (warning != null) warning,
                if (record.missingMediaCount > 0) _MissingMediaNotice(record),
              ]);
        }),
      );

  String _size(int bytes) => bytes >= 1024 * 1024 * 1024
      ? '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB'
      : bytes >= 1024 * 1024
          ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
          : '${(bytes / 1024).toStringAsFixed(1)} KB';
}

class _BackupIdentity extends StatelessWidget {
  const _BackupIdentity({required this.record});

  final BackupRecord record;

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        const _BackupIcon(
            icon: Icons.check_circle_rounded,
            color: BackupWorkspaceTheme.green),
        const SizedBox(width: 12),
        Flexible(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                DateFormat('d MMM yyyy, hh:mm a')
                    .format(record.createdAt.toLocal()),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: BackupWorkspaceTheme.ink)),
            const SizedBox(height: 6),
            _BackupDestinationBadge(record: record),
          ]),
        ),
      ]);
}

class _BackupMetric extends StatelessWidget {
  const _BackupMetric({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: BackupWorkspaceTheme.amber, size: 22),
        const SizedBox(width: 9),
        Flexible(
            child: Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: BackupWorkspaceTheme.ink))),
      ]);
}

class _BackupDestinationBadge extends StatelessWidget {
  const _BackupDestinationBadge({required this.record});

  final BackupRecord record;

  @override
  Widget build(BuildContext context) {
    final local = record.localPath != null;
    final drive = record.driveId != null;
    final label = local && drive
        ? 'Local + Google Drive'
        : drive
            ? 'Google Drive'
            : 'Local';
    final icon = local && drive
        ? Icons.sync_rounded
        : drive
            ? Icons.add_to_drive_rounded
            : Icons.folder_outlined;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: BackupWorkspaceTheme.gold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: BackupWorkspaceTheme.gold.withValues(alpha: 0.55)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: BackupWorkspaceTheme.amber),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: BackupWorkspaceTheme.ink)),
      ]),
    );
  }
}

class _MissingMediaNotice extends StatelessWidget {
  const _MissingMediaNotice(this.record);

  final BackupRecord record;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
            '${record.missingMediaCount} linked media files were unavailable',
            style: const TextStyle(
                fontSize: 13, color: BackupWorkspaceTheme.amber)),
      );
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 42,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        color: BackupWorkspaceTheme.border,
      );
}

class _BackupIcon extends StatelessWidget {
  const _BackupIcon({required this.icon, this.color, this.size = 20});

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      Icon(icon, color: color ?? BackupWorkspaceTheme.amber, size: size);
}
