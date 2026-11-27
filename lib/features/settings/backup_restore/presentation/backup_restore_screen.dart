import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../application/backup_coordinator.dart';
import '../application/backup_runtime.dart';
import '../data/backup_archive_service.dart';
import '../data/backup_file_safety.dart';
import '../domain/backup_record.dart';
import 'backup_destination_panels.dart';
import 'backup_history_panel.dart';
import 'backup_restore_source_dialog.dart';
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
  String? _notice;
  bool _noticeError = false;

  void _showNotice(String? message, {bool error = false}) {
    if (!mounted) return;
    setState(() {
      _notice = message;
      _noticeError = error;
    });
  }

  String _errorMessage(Object error) => error
      .toString()
      .replaceFirst('Bad state: ', '')
      .replaceFirst('FormatException: ', '');

  List<BackupRecord> _recoveryRecords(BackupCoordinator controller) {
    final byId = <String, BackupRecord>{
      for (final record in controller.records) record.id: record,
    };
    for (final cloudRecord in controller.cloudRecords) {
      final saved = byId[cloudRecord.id];
      if (saved == null) {
        byId[cloudRecord.id] = cloudRecord;
      } else if (saved.driveId == null && cloudRecord.driveId != null) {
        byId[cloudRecord.id] = saved.uploaded(cloudRecord.driveId!);
      }
    }
    final records = byId.values.toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return records;
  }

  Future<BackupCoordinator> _load() async =>
      widget.controller ?? await BackupRuntime.instance.coordinator();

  Future<void> _action(Future<void> Function() action,
      {String? success}) async {
    _showNotice(null);
    try {
      await action();
      if (success != null && (await _loading).error == null) {
        _showNotice(success);
      }
    } catch (error) {
      if ((await _loading).error == null) {
        _showNotice(_errorMessage(error), error: true);
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
    _showNotice(null);
    VerifiedBackup? preview;
    File? downloaded;
    try {
      BackupRestoreSource? restoreSource;
      if (file == null) {
        restoreSource = await selectBackupRestoreSource(context, record!,
            googleDriveConnected: controller.drive.auth.connected);
        if (restoreSource == null || !mounted) return;
      }
      final source = file ??
          (restoreSource == BackupRestoreSource.local
              ? File(record!.localPath!)
              : downloaded = await controller.download(record!));
      preview = await controller.inspect(source);
      if (!mounted) return;
      final approved = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => Theme(
              data: BackupWorkspaceTheme.of(dialogContext),
              child: AlertDialog(
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
                              'Source: ${restoreSource == BackupRestoreSource.googleDrive ? 'Google Drive' : 'Local Backup'}'),
                          const SizedBox(height: 8),
                          Text(
                              '${preview.fileCount} files verified · Databases checked'),
                          if ((preview.manifest['missingMedia'] as List? ?? [])
                              .isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                                '${(preview.manifest['missingMedia'] as List).length} linked media files were missing when this backup was created and cannot be restored.',
                                style: const TextStyle(
                                    color: BackupWorkspaceTheme.amber)),
                          ],
                          if ((preview.manifest['missingIssuedDocuments']
                                      as List? ??
                                  [])
                              .isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                                '${(preview.manifest['missingIssuedDocuments'] as List).length} original invoice PDFs were missing or unreadable when this backup was created. They cannot be restored from it.',
                                style: const TextStyle(
                                    color: BackupWorkspaceTheme.amber)),
                            const SizedBox(height: 4),
                            Text(
                                (preview.manifest['missingIssuedDocuments']
                                        as List)
                                    .take(5)
                                    .join('\n'),
                                style: const TextStyle(
                                    color: BackupWorkspaceTheme.amber)),
                            if ((preview.manifest['missingIssuedDocuments']
                                        as List)
                                    .length >
                                5)
                              Text(
                                  '...and ${(preview.manifest['missingIssuedDocuments'] as List).length - 5} more',
                                  style: const TextStyle(
                                      color: BackupWorkspaceTheme.amber)),
                          ],
                          if (!preview.manifest
                              .containsKey('missingIssuedDocuments')) ...[
                            const SizedBox(height: 10),
                            const Text(
                                'This older backup was created before invoice PDF completeness checks. Confirm its original PDFs before restoring.',
                                style: TextStyle(
                                    color: BackupWorkspaceTheme.amber)),
                          ],
                          const SizedBox(height: 16),
                          const Text(
                              'This replaces the current business records, shop settings, photos and documents with this backup.'),
                          const SizedBox(height: 12),
                          const Text(
                              'A verified recovery backup of your current data will be kept locally before anything is replaced.'),
                          const SizedBox(height: 12),
                          const Text(
                              'Lotus ERP will close and reopen automatically to apply the restore. Sign in with the account credentials saved in the restored backup.'),
                        ]))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel')),
                  FilledButton.icon(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      icon: const Icon(Icons.restore_rounded, size: 18),
                      label: const Text('Restore Backup'))
                ],
              )));
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
      if (controller.error == null) {
        _showNotice(_errorMessage(error), error: true);
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
                  // Saving a preference is intentionally non-disruptive: the
                  // destination selection remains visually stable while it is
                  // persisted, instead of dimming the complete workspace.
                  final savingSettings = controller.busy &&
                      controller.phase == 'Saving backup settings';
                  final enabled = !controller.restorePending &&
                      (!controller.busy || savingSettings);
                  return PopScope(
                      canPop: !controller.restorePending,
                      child: Scaffold(
                        appBar: BackupWorkspaceAppBar(
                            onBack: controller.restorePending
                                ? null
                                : widget.onBack,
                            busy: controller.busy && !savingSettings),
                        body: SingleChildScrollView(
                            padding: EdgeInsets.all(
                                MediaQuery.sizeOf(context).width < 600
                                    ? 16
                                    : 24),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  BackupWorkspaceOverview(
                                      controller: controller,
                                      onBackup: () => _action(
                                          controller.backupNow,
                                          success: controller
                                                  .settings!.googleDriveEnabled
                                              ? controller
                                                      .settings!.localEnabled
                                                  ? 'Backup saved locally and uploaded to Google Drive.'
                                                  : 'Google Drive backup created and verified.'
                                              : 'Local backup created and verified.')),
                                  if (controller.busy && !savingSettings) ...[
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
                                  if (controller.error != null ||
                                      _notice != null) ...[
                                    const SizedBox(height: 16),
                                    BackupWorkspaceNotice(
                                        message: controller.error ?? _notice!,
                                        error: controller.error != null ||
                                            _noticeError)
                                  ],
                                  if (controller.records.isNotEmpty &&
                                      controller
                                              .records.first.missingMediaCount >
                                          0) ...[
                                    const SizedBox(height: 16),
                                    BackupWorkspaceNotice(
                                        message:
                                            'The latest backup is saved, but ${controller.records.first.missingMediaCount} original invoice PDFs or linked files were missing and cannot be restored from it.',
                                        error: true),
                                  ],
                                  if (controller.restorePending) ...[
                                    const SizedBox(height: 16),
                                    BackupWorkspaceNotice(
                                        message:
                                            'Restore is prepared. If Lotus ERP did not reopen automatically, retry opening it here.',
                                        error: true,
                                        actionLabel: 'Retry Reopen',
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
                                                  controller.settings!.copyWith(
                                                      localFolder: folder));
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
                                      onLocalEnabled: (value) => _action(() =>
                                          controller.saveSettings(controller.settings!
                                              .copyWith(localEnabled: value))),
                                      onDriveEnabled: (value) => _action(() =>
                                          controller.saveSettings(controller.settings!
                                              .copyWith(googleDriveEnabled: value)))),
                                  const SizedBox(height: 20),
                                  BackupSchedulePanel(
                                      schedule: controller.settings!.schedule,
                                      enabled: enabled,
                                      localEnabled:
                                          controller.settings!.localEnabled,
                                      googleDriveEnabled: controller
                                          .settings!.googleDriveEnabled,
                                      localFolder:
                                          controller.settings!.localFolder,
                                      onSave: (schedule) => _action(
                                          () => controller.saveSettings(
                                              controller.settings!.copyWith(
                                                  schedule: schedule)),
                                          success: 'Backup schedule saved.')),
                                  const SizedBox(height: 20),
                                  BackupHistoryPanel(
                                      records: _recoveryRecords(controller),
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
                                ])),
                      ));
                });
          }));
}
