import 'package:flutter/material.dart';

import '../application/backup_coordinator.dart';
import 'backup_workspace_theme.dart';

class BackupDestinationPanels extends StatelessWidget {
  const BackupDestinationPanels({
    super.key,
    required this.controller,
    required this.onChooseFolder,
    required this.onOpenFolder,
    required this.onConnectGoogle,
    required this.onDisconnectGoogle,
    required this.onLocalEnabled,
    required this.onDriveEnabled,
  });

  final BackupCoordinator controller;
  final VoidCallback onChooseFolder;
  final VoidCallback onOpenFolder;
  final VoidCallback onConnectGoogle;
  final VoidCallback onDisconnectGoogle;
  final ValueChanged<bool> onLocalEnabled;
  final ValueChanged<bool> onDriveEnabled;

  @override
  Widget build(BuildContext context) {
    final disabled = controller.busy || controller.restorePending;
    final localSelected = controller.settings!.localEnabled;
    final driveSelected = controller.settings!.googleDriveEnabled;
    final connected = controller.drive.auth.connected;

    final local = BackupPanel(
      title: 'Local Backup',
      icon: Icons.folder_outlined,
      trailing: _DestinationButton(
        label: 'Local Backup',
        selected: localSelected,
        onPressed: disabled || (localSelected && !driveSelected)
            ? null
            : () => onLocalEnabled(!localSelected),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Backup Folder',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                decoration: BoxDecoration(
                  color: BackupWorkspaceTheme.surface,
                  border: Border.all(color: BackupWorkspaceTheme.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.folder_outlined,
                      color: BackupWorkspaceTheme.amber, size: 20),
                  const SizedBox(width: 9),
                  Flexible(
                      child: SelectableText(controller.settings!.localFolder,
                          maxLines: 1,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600))),
                ]),
              ),
              OutlinedButton.icon(
                  onPressed: disabled ? null : onChooseFolder,
                  icon: const Icon(Icons.folder_open_outlined, size: 18),
                  label: const Text('Choose Folder'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: BackupWorkspaceTheme.amber,
                      side:
                          const BorderSide(color: BackupWorkspaceTheme.gold))),
              OutlinedButton.icon(
                  onPressed: disabled ? null : onOpenFolder,
                  icon: const Icon(Icons.folder_open_rounded, size: 18),
                  label: const Text('Open Folder')),
            ]),
      ]),
    );

    final cloud = BackupPanel(
      title: 'Google Drive Backup',
      icon: Icons.add_to_drive_rounded,
      trailing: _DestinationButton(
        label: 'Google Drive Backup',
        selected: driveSelected,
        onPressed: disabled ||
                (!driveSelected && !connected) ||
                (driveSelected && !localSelected)
            ? null
            : () => onDriveEnabled(!driveSelected),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(connected ? Icons.verified_rounded : Icons.cloud_off_rounded,
              color: connected
                  ? BackupWorkspaceTheme.green
                  : BackupWorkspaceTheme.muted,
              size: 20),
          const SizedBox(width: 9),
          Expanded(
              child: Text(
                  controller.drive.auth.email ?? 'No Google account connected',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 16),
        Wrap(spacing: 10, runSpacing: 10, children: [
          OutlinedButton.icon(
              onPressed: disabled ? null : onConnectGoogle,
              icon: const Icon(Icons.settings_outlined, size: 18),
              label:
                  Text(connected ? 'Change Account' : 'Connect Google Account'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: BackupWorkspaceTheme.amber,
                  side: const BorderSide(color: BackupWorkspaceTheme.gold))),
          if (connected)
            OutlinedButton.icon(
                onPressed: disabled ? null : onDisconnectGoogle,
                icon: const Icon(Icons.power_settings_new_rounded, size: 18),
                label: const Text('Disconnect'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC62828),
                    side: const BorderSide(color: Color(0xFFE35555)))),
        ]),
        if (!controller.drive.auth.configured) ...[
          const SizedBox(height: 10),
          const Text('Google Drive is unavailable in this build.',
              style:
                  TextStyle(fontSize: 13, color: BackupWorkspaceTheme.muted)),
        ],
      ]),
    );

    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 1050
          ? Column(children: [local, const SizedBox(height: 16), cloud])
          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 250),
                      child: local)),
              const SizedBox(width: 16),
              Expanded(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 250),
                      child: cloud)),
            ]),
    );
  }
}

class _DestinationButton extends StatelessWidget {
  const _DestinationButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: onPressed == null && selected
            ? 'Select the other destination before turning this one off.'
            : '$label ${selected ? 'selected' : 'not selected'}',
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(
              selected ? Icons.check_circle_rounded : Icons.add_circle_outline,
              size: 17),
          label: Text(selected ? 'Selected' : 'Select'),
          style: OutlinedButton.styleFrom(
            backgroundColor: selected
                ? BackupWorkspaceTheme.gold
                : BackupWorkspaceTheme.surface,
            foregroundColor: BackupWorkspaceTheme.ink,
            side: BorderSide(
                color: selected
                    ? BackupWorkspaceTheme.gold
                    : BackupWorkspaceTheme.border),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      );
}
