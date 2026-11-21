import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../application/backup_coordinator.dart';
import 'backup_workspace_theme.dart';

class BackupWorkspaceOverview extends StatelessWidget {
  const BackupWorkspaceOverview(
      {super.key, required this.controller, required this.onBackup});
  final BackupCoordinator controller;
  final VoidCallback onBackup;
  @override
  Widget build(BuildContext context) => BackupPanel(
      title: 'Protect Your Business Data',
      icon: Icons.shield_outlined,
      subtitle: 'Local recovery and Google Drive backup in one place.',
      child: Wrap(
          spacing: 24,
          runSpacing: 16,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Last verified local backup',
                  style: TextStyle(
                      fontSize: 12, color: BackupWorkspaceTheme.muted)),
              const SizedBox(height: 5),
              Text(
                  controller.records.isEmpty
                      ? 'No backup created yet'
                      : DateFormat('d MMM yyyy · h:mm a')
                          .format(controller.records.first.createdAt.toLocal()),
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w800)),
            ]),
            FilledButton.icon(
                onPressed: controller.busy || controller.restorePending
                    ? null
                    : onBackup,
                icon: const Icon(Icons.backup_rounded),
                label: const Text('Back Up Now'),
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 18))),
          ]));
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
          color: error ? const Color(0xFFFFF7ED) : const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color:
                  error ? const Color(0xFFFED7AA) : const Color(0xFFA7F3D0))),
      child: Row(children: [
        Icon(error ? Icons.info_outline_rounded : Icons.restart_alt_rounded,
            color:
                error ? const Color(0xFFB45309) : BackupWorkspaceTheme.green),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
        if (action != null)
          TextButton(onPressed: action, child: const Text('Restart'))
      ]));
}
