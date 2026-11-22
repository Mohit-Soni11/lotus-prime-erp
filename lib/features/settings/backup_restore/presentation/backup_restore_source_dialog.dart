import 'package:flutter/material.dart';

import '../domain/backup_record.dart';
import 'backup_workspace_theme.dart';

enum BackupRestoreSource { local, googleDrive }

Future<BackupRestoreSource?> selectBackupRestoreSource(
    BuildContext context, BackupRecord record,
    {required bool googleDriveConnected}) {
  final hasLocal = record.localPath != null;
  final hasDrive = record.driveId != null;
  if (hasLocal && hasDrive) {
    return chooseBackupRestoreSource(context,
        googleDriveConnected: googleDriveConnected);
  }
  if (hasLocal) return Future.value(BackupRestoreSource.local);
  if (hasDrive) return Future.value(BackupRestoreSource.googleDrive);
  throw StateError('This backup has no available restore copy.');
}

Future<BackupRestoreSource?> chooseBackupRestoreSource(BuildContext context,
        {required bool googleDriveConnected}) =>
    showDialog<BackupRestoreSource>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Choose Restore Source'),
        content: SizedBox(
          width: 440,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('This backup has two copies. Choose one to restore.'),
            ),
            const SizedBox(height: 18),
            _SourceOption(
              icon: Icons.folder_outlined,
              title: 'Local Backup',
              subtitle: 'Restore the copy saved on this computer.',
              onTap: () =>
                  Navigator.pop(dialogContext, BackupRestoreSource.local),
            ),
            const SizedBox(height: 10),
            _SourceOption(
              icon: Icons.add_to_drive_rounded,
              title: 'Google Drive Backup',
              subtitle: googleDriveConnected
                  ? 'Download and verify the copy in Google Drive.'
                  : 'Connect Google Drive to restore this copy.',
              onTap: googleDriveConnected
                  ? () => Navigator.pop(
                      dialogContext, BackupRestoreSource.googleDrive)
                  : null,
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: BackupWorkspaceTheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: BackupWorkspaceTheme.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(icon, color: BackupWorkspaceTheme.amber, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 13, color: BackupWorkspaceTheme.muted)),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right_rounded,
                    color: BackupWorkspaceTheme.amber),
            ]),
          ),
        ),
      );
}
