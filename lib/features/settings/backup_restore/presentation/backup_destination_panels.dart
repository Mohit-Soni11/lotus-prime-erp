import 'package:flutter/material.dart';
import '../application/backup_coordinator.dart';
import 'backup_workspace_theme.dart';

class BackupDestinationPanels extends StatelessWidget {
  const BackupDestinationPanels(
      {super.key,
      required this.controller,
      required this.onChooseFolder,
      required this.onOpenFolder,
      required this.onSetupGoogle,
      required this.onConnectGoogle,
      required this.onDisconnectGoogle,
      required this.onDriveEnabled});
  final BackupCoordinator controller;
  final VoidCallback onChooseFolder,
      onOpenFolder,
      onSetupGoogle,
      onConnectGoogle,
      onDisconnectGoogle;
  final ValueChanged<bool> onDriveEnabled;
  @override
  Widget build(BuildContext context) {
    final disabled = controller.busy || controller.restorePending;
    final local = BackupPanel(
        title: 'Local Backup',
        icon: Icons.folder_copy_outlined,
        subtitle: 'A verified copy saved on your computer or external drive.',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Backup folder',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SelectableText(controller.settings!.localFolder,
              style: const TextStyle(
                  fontSize: 12, color: BackupWorkspaceTheme.muted)),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 8, children: [
            OutlinedButton.icon(
                onPressed: disabled ? null : onChooseFolder,
                icon: const Icon(Icons.drive_file_move_outline, size: 18),
                label: const Text('Choose Folder')),
            TextButton.icon(
                onPressed: disabled ? null : onOpenFolder,
                icon: const Icon(Icons.folder_open_rounded, size: 18),
                label: const Text('Open Folder')),
          ]),
        ]));
    final cloud = BackupPanel(
        title: 'Google Drive Backup',
        icon: Icons.add_to_drive_rounded,
        subtitle: 'Back up to your own Google account.',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(
                controller.drive.auth.connected
                    ? Icons.verified_rounded
                    : Icons.cloud_off_rounded,
                color: controller.drive.auth.connected
                    ? BackupWorkspaceTheme.green
                    : BackupWorkspaceTheme.muted,
                size: 19),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
                    controller.drive.auth.email ??
                        'No Google account connected',
                    style: const TextStyle(fontWeight: FontWeight.w700)))
          ]),
          const SizedBox(height: 8),
          const Text(
              'Only Lotus ERP backup files are accessed. Your Gmail messages and other Drive files are not included.',
              style:
                  TextStyle(fontSize: 12, color: BackupWorkspaceTheme.muted)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (!controller.drive.auth.configured)
              FilledButton.icon(
                  onPressed: disabled ? null : onSetupGoogle,
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: const Text('Set Up Google Drive')),
            if (controller.drive.auth.configured)
              FilledButton.icon(
                  onPressed: disabled ? null : onConnectGoogle,
                  icon: const Icon(Icons.account_circle_outlined, size: 18),
                  label: Text(controller.drive.auth.connected
                      ? 'Change Account'
                      : 'Connect Google Account')),
            if (controller.drive.auth.connected)
              TextButton(
                  onPressed: disabled ? null : onDisconnectGoogle,
                  child: const Text('Disconnect')),
            if (controller.drive.auth.configured)
              TextButton(
                  onPressed: disabled ? null : onSetupGoogle,
                  child: const Text('Connection Setup')),
          ]),
          SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Include Google Drive',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              subtitle: const Text(
                  'Upload manual and scheduled backups after the local copy is verified.',
                  style: TextStyle(fontSize: 12)),
              value: controller.settings!.googleDriveEnabled,
              onChanged: disabled || !controller.drive.auth.connected
                  ? null
                  : onDriveEnabled),
        ]));
    return LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 1050
            ? Column(children: [local, const SizedBox(height: 16), cloud])
            : IntrinsicHeight(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    Expanded(child: local),
                    const SizedBox(width: 16),
                    Expanded(child: cloud)
                  ])));
  }
}
