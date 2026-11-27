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
  String? _selectedRecordId;

  BackupRecord? get _selectedRecord {
    for (final record in widget.records) {
      if (record.id == _selectedRecordId) return record;
    }
    return null;
  }

  @override
  void didUpdateWidget(covariant BackupHistoryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedRecordId != null && _selectedRecord == null) {
      _selectedRecordId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<BackupRecord>>{};
    for (final record in widget.records) {
      groups.putIfAbsent(_destinationLabel(record), () => []).add(record);
    }
    for (final records in groups.values) {
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return BackupPanel(
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
        FilledButton.icon(
          onPressed: widget.enabled && _selectedRecord != null
              ? () => widget.onRestore(_selectedRecord!)
              : null,
          icon: const Icon(Icons.restore_rounded, size: 18),
          label: const Text('Restore Selected'),
        ),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (widget.records.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: _EmptyBackupHistory(),
          ),
        for (final label in const [
          'Local',
          'Google Drive',
          'Local + Google Drive'
        ])
          if (groups[label] case final records?)
            _BackupGroup(
              label: label,
              records: records,
              selectedRecordId: _selectedRecordId,
              enabled: widget.enabled,
              connected: widget.connected,
              onSelect: (record) =>
                  setState(() => _selectedRecordId = record.id),
              onRetryUpload: widget.onRetryUpload,
            ),
      ]),
    );
  }
}

class _BackupGroup extends StatelessWidget {
  const _BackupGroup({
    required this.label,
    required this.records,
    required this.selectedRecordId,
    required this.enabled,
    required this.connected,
    required this.onSelect,
    required this.onRetryUpload,
  });

  final String label;
  final List<BackupRecord> records;
  final String? selectedRecordId;
  final bool enabled;
  final bool connected;
  final ValueChanged<BackupRecord> onSelect;
  final ValueChanged<BackupRecord> onRetryUpload;

  Widget _row(BackupRecord record) => _BackupHistoryRow(
        record: record,
        selected: record.id == selectedRecordId,
        enabled: enabled,
        onSelect: () => onSelect(record),
        onRetryUpload:
            connected && record.localPath != null && record.cloudError != null
                ? () => onRetryUpload(record)
                : null,
      );

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: BackupWorkspaceTheme.surfaceLow,
          border: Border.all(color: BackupWorkspaceTheme.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(
              label == 'Local'
                  ? Icons.folder_outlined
                  : label == 'Google Drive'
                      ? Icons.add_to_drive_rounded
                      : Icons.cloud_done_outlined,
              color: BackupWorkspaceTheme.amber,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: BackupWorkspaceTheme.ink)),
            ),
            Text(
                '${records.length} recovery ${records.length == 1 ? 'point' : 'points'}',
                style: const TextStyle(color: BackupWorkspaceTheme.muted)),
          ]),
          const SizedBox(height: 12),
          _row(records.first),
          if (records.length > 1)
            ExpansionTile(
              key: PageStorageKey('backup-history-$label'),
              title: Text('Earlier recovery points (${records.length - 1})'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              children: [for (final record in records.skip(1)) _row(record)],
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
    required this.selected,
    required this.enabled,
    required this.onSelect,
    this.onRetryUpload,
  });

  final BackupRecord record;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelect;
  final VoidCallback? onRetryUpload;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        button: true,
        label: 'Select ${_destinationLabel(record)} backup',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('backup-row-${record.id}'),
            onTap: enabled ? onSelect : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: selected
                    ? BackupWorkspaceTheme.gold.withValues(alpha: 0.10)
                    : BackupWorkspaceTheme.surface,
                border: Border.all(
                    color: selected
                        ? BackupWorkspaceTheme.gold
                        : BackupWorkspaceTheme.border,
                    width: selected ? 1.5 : 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: LayoutBuilder(builder: (context, constraints) {
                final primary =
                    _BackupIdentity(record: record, selected: selected);
                final actions = Wrap(spacing: 8, runSpacing: 8, children: [
                  if (onRetryUpload != null)
                    OutlinedButton.icon(
                      onPressed: enabled ? onRetryUpload : null,
                      icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: const Text('Retry Upload'),
                    ),
                ]);
                final warning = record.cloudError == null
                    ? null
                    : const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                            'Google Drive upload needs a retry. Local copy is safe.',
                            style: TextStyle(
                                fontSize: 13,
                                color: BackupWorkspaceTheme.amber)),
                      );

                if (constraints.maxWidth < 760) {
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        primary,
                        if (warning != null) warning,
                        if (record.missingMediaCount > 0)
                          _MissingMediaNotice(record),
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
                            flex: 3,
                            child: Center(
                                child:
                                    _BackupDestinationBadge(record: record))),
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
                      if (record.missingMediaCount > 0)
                        _MissingMediaNotice(record),
                    ]);
              }),
            ),
          ),
        ),
      );

  String _size(int bytes) => bytes >= 1024 * 1024 * 1024
      ? '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB'
      : bytes >= 1024 * 1024
          ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
          : '${(bytes / 1024).toStringAsFixed(1)} KB';
}

class _BackupIdentity extends StatelessWidget {
  const _BackupIdentity({required this.record, required this.selected});

  final BackupRecord record;
  final bool selected;

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        _BackupIcon(
            icon: selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected
                ? BackupWorkspaceTheme.amber
                : BackupWorkspaceTheme.muted),
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
    final label = _destinationLabel(record);
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

String _destinationLabel(BackupRecord record) {
  final local = record.localPath != null;
  final drive = record.driveId != null;
  if (local && drive) return 'Local + Google Drive';
  return drive ? 'Google Drive' : 'Local';
}

class _MissingMediaNotice extends StatelessWidget {
  const _MissingMediaNotice(this.record);

  final BackupRecord record;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
            '${record.missingMediaCount} invoice PDFs or linked files were unavailable',
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
