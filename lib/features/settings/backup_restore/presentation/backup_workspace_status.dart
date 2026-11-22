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
      child: LayoutBuilder(builder: (context, constraints) {
        final action = FilledButton.icon(
          onPressed:
              controller.busy || controller.restorePending ? null : onBackup,
          icon: const Icon(Icons.cloud_upload_outlined, size: 23),
          label: const Text('Back Up Now'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
          ),
        );
        final lastBackup = _SummaryDetail(
          icon: Icons.calendar_month_outlined,
          label: 'Last Backup',
          value: latest == null
              ? 'No backup yet'
              : DateFormat('d MMM yyyy, hh:mm a')
                  .format(latest.createdAt.toLocal()),
        );
        final backupType = _SummaryDetail(
          icon: Icons.storage_rounded,
          label: 'Backup Type',
          value: _backupType(latest),
        );
        // The primary summary intentionally remains a single information bar on
        // desktop, matching the Backup & Restore workspace layout.
        if (constraints.maxWidth >= 1000) {
          return Row(children: [
            const Expanded(flex: 4, child: _SummaryHeading()),
            const _SummaryDivider(),
            Expanded(flex: 3, child: lastBackup),
            const _SummaryDivider(),
            Expanded(flex: 3, child: backupType),
            const SizedBox(width: 20),
            action,
          ]);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SummaryHeading(),
            const SizedBox(height: 20),
            lastBackup,
            const SizedBox(height: 16),
            backupType,
            const SizedBox(height: 20),
            Align(alignment: Alignment.centerLeft, child: action),
          ],
        );
      }),
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
        children: [
          _SummaryIcon(Icons.verified_user_outlined),
          SizedBox(width: 14),
          Flexible(
              child: Text('Business Data Backup',
                  style: TextStyle(
                      fontSize: 23,
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
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: BackupWorkspaceTheme.muted)),
              const SizedBox(height: 3),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: BackupWorkspaceTheme.ink)),
            ]),
          ),
        ],
      );
}

class _SummaryIcon extends StatelessWidget {
  const _SummaryIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: BackupWorkspaceTheme.gold.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: BackupWorkspaceTheme.amber, size: 24),
      );
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 46,
        margin: const EdgeInsets.symmetric(horizontal: 28),
        color: BackupWorkspaceTheme.border,
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
