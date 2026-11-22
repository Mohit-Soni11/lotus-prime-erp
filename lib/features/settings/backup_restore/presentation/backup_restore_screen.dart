import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/feedback/app_feedback.dart';
import '../application/backup_coordinator.dart';
import '../application/backup_runtime.dart';
import '../data/backup_archive_service.dart';
import '../data/backup_file_safety.dart';
import '../domain/backup_record.dart';
import 'backup_destination_panels.dart';
import 'backup_history_panel.dart';
import 'backup_schedule_panel.dart';
import 'backup_workspace_app_bar.dart';
import 'backup_workspace_theme.dart';
import 'backup_workspace_status.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key, required this.onBack, this.controller});
  final VoidCallback onBack;
  final BackupCoordinator? controller;
  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  late Future<BackupCoordinator> _loading = _load();
  Future<BackupCoordinator> _load() async =>
      widget.controller ?? await BackupRuntime.instance.coordinator();

  Future<void> _action(Future<void> Function() action,
      {String? success}) async {
    try {
      await action();
      if (mounted && success != null) {
        AppFeedback.success(context, message: success);
      }
    } catch (error) {
      if (mounted) {
        AppFeedback.warning(context,
            message: error
                .toString()
                .replaceFirst('Bad state: ', '')
                .replaceFirst('FormatException: ', ''));
      }
    }
  }

  Future<void> _pickLocal(BackupCoordinator controller) async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['lotusbackup'],
        dialogTitle: 'Select Lotus ERP Backup');
    final path = result?.files.single.path;
    if (path != null) await _restore(controller, file: File(path));
  }

  Future<void> _restore(BackupCoordinator controller,
      {File? file, BackupRecord? record}) async {
    VerifiedBackup? preview;
    File? downloaded;
    try {
      final source = file ??
          (record!.localPath != null
              ? File(record.localPath!)
              : downloaded = await controller.download(record));
      preview = await controller.inspect(source);
      if (!mounted) return;
      final approved = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
                title: const Text('Restore This Backup?'),
                content: SizedBox(
                    width: 520,
                    child: SingleChildScrollView(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(
                              'Created: ${DateFormat('d MMM yyyy, h:mm a').format(preview!.createdAt.toLocal())}'),
                          const SizedBox(height: 8),
                          Text(
                              '${preview.fileCount} files verified · Databases checked'),
                          if ((preview.manifest['missingMedia'] as List? ?? [])
                              .isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                                '${(preview.manifest['missingMedia'] as List).length} linked media files were missing when this backup was created and cannot be restored.',
                                style:
                                    const TextStyle(color: Color(0xFFB45309))),
                          ],
                          const SizedBox(height: 16),
                          const Text(
                              'This replaces the current business records, shop settings, photos and documents with this backup.'),
                          const SizedBox(height: 12),
                          const Text(
                              'A verified recovery backup of your current data will be kept locally before anything is replaced.'),
                          const SizedBox(height: 12),
                          const Text(
                              'Lotus ERP will restart. Sign in with the account credentials saved in the restored backup.'),
                        ]))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel')),
                  FilledButton.icon(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      icon: const Icon(Icons.restore_rounded, size: 18),
                      label: const Text('Restore & Restart'))
                ],
              ));
      if (approved != true) return;
      await controller.prepareRestore(source);
      await deleteBackupEntity(preview.directory.path);
      preview = null;
      if (downloaded != null && await downloaded.exists()) {
        await downloaded.delete();
        downloaded = null;
      }
      await BackupRuntime.instance.restartForRestore();
    } catch (error) {
      if (mounted) {
        AppFeedback.warning(context,
            message: error
                .toString()
                .replaceFirst('Bad state: ', '')
                .replaceFirst('FormatException: ', ''));
      }
    } finally {
      if (preview != null) await deleteBackupEntity(preview.directory.path);
      if (downloaded != null && await downloaded.exists()) {
        await downloaded.delete();
      }
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
      data: BackupWorkspaceTheme.of(context),
      child: FutureBuilder<BackupCoordinator>(
          future: _loading,
          builder: (context, snapshot) {
            final controller = snapshot.data;
            if (controller == null) {
              return Scaffold(
                  appBar: BackupWorkspaceAppBar(onBack: widget.onBack),
                  body: Center(
                      child: snapshot.hasError
                          ? Column(mainAxisSize: MainAxisSize.min, children: [
                              const Text(
                                  'Backup settings could not be loaded.'),
                              const SizedBox(height: 14),
                              FilledButton(
                                  onPressed: () =>
                                      setState(() => _loading = _load()),
                                  child: const Text('Retry')),
                            ])
                          : const CircularProgressIndicator()));
            }
            return AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final enabled =
                      !controller.busy && !controller.restorePending;
                  return PopScope(
                      canPop: !controller.restorePending,
                      child: Scaffold(
                        appBar: BackupWorkspaceAppBar(
                            onBack: controller.restorePending
                                ? null
                                : widget.onBack,
                            busy: controller.busy),
                        body: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  BackupWorkspaceOverview(
                                      controller: controller,
                                      onBackup: () => _action(
                                          controller.backupNow,
                                          success:
                                              'Local backup created and verified.')),
                                  if (controller.busy) ...[
                                    const SizedBox(height: 16),
                                    LinearProgressIndicator(
                                        value: controller.progress),
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      Expanded(child: Text(controller.phase)),
                                      if (controller.signingIn)
                                        TextButton(
                                            onPressed: controller
                                                .drive.auth.cancelSignIn,
                                            child: const Text('Cancel Sign-in'))
                                    ])
                                  ],
                                  if (controller.error != null) ...[
                                    const SizedBox(height: 16),
                                    BackupWorkspaceNotice(
                                        message: controller.error!, error: true)
                                  ],
                                  if (controller.records.isNotEmpty &&
                                      controller
                                              .records.first.missingMediaCount >
                                          0) ...[
                                    const SizedBox(height: 16),
                                    BackupWorkspaceNotice(
                                        message:
                                            'The latest backup is saved, but ${controller.records.first.missingMediaCount} linked photo or document files were already missing and could not be included.',
                                        error: true),
                                  ],
                                  if (controller.restorePending) ...[
                                    const SizedBox(height: 16),
                                    BackupWorkspaceNotice(
                                        message:
                                            'Restore is prepared. Restart Lotus ERP to safely apply the selected backup.',
                                        action: () => _action(BackupRuntime
                                            .instance.restartForRestore))
                                  ],
                                  const SizedBox(height: 20),
                                  BackupDestinationPanels(
                                      controller: controller,
                                      onChooseFolder: () => _action(() async {
                                            final folder = await FilePicker
                                                .platform
                                                .getDirectoryPath(
                                                    dialogTitle:
                                                        'Choose Local Backup Folder');
                                            if (folder != null) {
                                              await controller.saveSettings(
                                                  BackupSettings(
                                                      localFolder: folder,
                                                      googleDriveEnabled:
                                                          controller.settings!
                                                              .googleDriveEnabled,
                                                      schedule: controller
                                                          .settings!.schedule));
                                            }
                                          }),
                                      onOpenFolder: () => _action(() async {
                                            final directory = Directory(
                                                controller
                                                    .settings!.localFolder);
                                            await directory.create(
                                                recursive: true);
                                            if (!await launchUrl(
                                                directory.uri)) {
                                              throw StateError(
                                                  'Could not open the backup folder.');
                                            }
                                          }),
                                      onConnectGoogle: () => _action(
                                          controller.connectGoogle,
                                          success:
                                              'Google Drive backup connected.'),
                                      onDisconnectGoogle: () =>
                                          _action(controller.disconnectGoogle),
                                      onDriveEnabled: (value) => _action(() =>
                                          controller.saveSettings(
                                              BackupSettings(
                                                  localFolder: controller
                                                      .settings!.localFolder,
                                                  googleDriveEnabled: value,
                                                  schedule: controller
                                                      .settings!.schedule)))),
                                  const SizedBox(height: 20),
                                  BackupSchedulePanel(
                                      schedule: controller.settings!.schedule,
                                      enabled: enabled,
                                      onSave: (schedule) => _action(
                                          () => controller.saveSettings(
                                              BackupSettings(
                                                  localFolder: controller
                                                      .settings!.localFolder,
                                                  googleDriveEnabled: controller
                                                      .settings!
                                                      .googleDriveEnabled,
                                                  schedule: schedule)),
                                          success: 'Backup schedule saved.')),
                                  const SizedBox(height: 20),
                                  BackupHistoryPanel(
                                      local: controller.records,
                                      cloud: controller.cloudRecords,
                                      connected:
                                          controller.drive.auth.connected,
                                      enabled: enabled,
                                      onRefreshCloud: () =>
                                          _action(controller.refreshCloud),
                                      onPickLocal: () => _pickLocal(controller),
                                      onRestore: (record) =>
                                          _restore(controller, record: record),
                                      onRetryUpload: (record) => _action(
                                          () => controller.retryUpload(record),
                                          success:
                                              'Backup uploaded to Google Drive.')),
                                  const SizedBox(height: 18),
                                  const Text(
                                      'Backups include business records, shop settings, photos and documents. Google authorization and active login sessions remain on this device.',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: BackupWorkspaceTheme.muted)),
                                ])),
                      ));
                });
          }));
}
