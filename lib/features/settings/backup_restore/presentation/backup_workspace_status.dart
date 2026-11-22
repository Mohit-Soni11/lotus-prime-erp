import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../application/backup_coordinator.dart';
import '../domain/backup_record.dart';
import 'backup_workspace_theme.dart';

class BackupWorkspaceOverview extends StatelessWidget {
  const BackupWorkspaceOverview(
      {super.key, required this.controller, required this.onBackup});

  final BackupCoordinator controller;
  final VoidCallback onBackup;

  @override
  Widget build(BuildContext context) {
    final latest = controller.records.isEmpty ? null : controller.records.first;
    return BackupPanel(
      child: Wrap(
        spacing: 28,
        runSpacing: 18,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const _SummaryHeading(),
          _SummaryDetail(
            icon: Icons.calendar_month_outlined,
            label: 'Last Backup',
            value: latest == null
                ? 'No backup yet'
                : DateFormat('d MMM yyyy, hh:mm a')
                    .format(latest.createdAt.toLocal()),
          ),
          _SummaryDetail(
            icon: Icons.storage_rounded,
            label: 'Backup Type',
            value: _backupType(latest),
          ),
          FilledButton.icon(
            onPressed:
                controller.busy || controller.restorePending ? null : onBackup,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Back Up Now'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            ),
          ),
        ],
      ),
    );
  }

  String _backupType(BackupRecord? record) {
    if (record == null) return '—';
    if (record.localPath != null && record.driveId != null) {
      return 'Local + Google Drive';
    }
    return record.driveId != null ? 'Google Drive Backup' : 'Local Backup';
  }
}

class _SummaryHeading extends StatelessWidget {
  const _SummaryHeading();

  @override
  Widget build(BuildContext context) => const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SummaryIcon(Icons.verified_user_outlined),
          SizedBox(width: 14),
          Flexible(
              child: Text('Business Data Backup',
                  style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: BackupWorkspaceTheme.ink))),
        ],
      );
}

class _SummaryDetail extends StatelessWidget {
  const _SummaryDetail(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SummaryIcon(icon),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: BackupWorkspaceTheme.muted)),
            const SizedBox(height: 3),
            Text(value,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: BackupWorkspaceTheme.ink)),
          ]),
        ],
      );
}

class _SummaryIcon extends StatelessWidget {
  const _SummaryIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: BackupWorkspaceTheme.gold.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: BackupWorkspaceTheme.ink, size: 22),
      );
}

class BackupWorkspaceNotice extends StatelessWidget {
  const BackupWorkspaceNotice(
      {super.key, required this.message, this.error = false, this.action});

  final String message;
  final bool error;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: error ? const Color(0xFFFFF5E8) : const Color(0xFFEAF9F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: error ? const Color(0xFFE9C98E) : const Color(0xFFA7E3BF)),
        ),
        child: Row(children: [
          Icon(
              error
                  ? Icons.info_outline_rounded
                  : action != null
                      ? Icons.restart_alt_rounded
                      : Icons.check_circle_outline_rounded,
              color: error
                  ? BackupWorkspaceTheme.amber
                  : BackupWorkspaceTheme.green),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      fontSize: 14, color: BackupWorkspaceTheme.ink))),
          if (action != null)
            TextButton(onPressed: action, child: const Text('Restart')),
        ]),
      );
}
