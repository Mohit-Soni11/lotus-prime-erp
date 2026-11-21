import 'backup_schedule.dart';

class BackupSettings {
  const BackupSettings(
      {required this.localFolder,
      this.googleDriveEnabled = false,
      this.schedule = const BackupSchedule()});
  final String localFolder;
  final bool googleDriveEnabled;
  final BackupSchedule schedule;
  Map<String, dynamic> toJson() => {
        'localFolder': localFolder,
        'googleDriveEnabled': googleDriveEnabled,
        'schedule': schedule.toJson()
      };
  factory BackupSettings.fromJson(
          Map<String, dynamic> json, String defaultFolder) =>
      BackupSettings(
        localFolder: json['localFolder'] as String? ?? defaultFolder,
        googleDriveEnabled: json['googleDriveEnabled'] == true,
        schedule: BackupSchedule.fromJson(
            Map<String, dynamic>.from(json['schedule'] as Map? ?? {})),
      );
}

class BackupRecord {
  const BackupRecord(
      {required this.id,
      required this.name,
      required this.createdAt,
      required this.size,
      required this.sha256,
      this.localPath,
      this.driveId,
      this.cloudError,
      this.missingMediaCount = 0});
  final String id;
  final String name;
  final DateTime createdAt;
  final int size;
  final String sha256;
  final String? localPath;
  final String? driveId;
  final String? cloudError;
  final int missingMediaCount;

  BackupRecord uploaded(String fileId) => BackupRecord(
      id: id,
      name: name,
      createdAt: createdAt,
      size: size,
      sha256: sha256,
      localPath: localPath,
      driveId: fileId,
      missingMediaCount: missingMediaCount);
  BackupRecord uploadFailed(String message) => BackupRecord(
      id: id,
      name: name,
      createdAt: createdAt,
      size: size,
      sha256: sha256,
      localPath: localPath,
      driveId: driveId,
      cloudError: message,
      missingMediaCount: missingMediaCount);
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'size': size,
        'sha256': sha256,
        'localPath': localPath,
        'driveId': driveId,
        'cloudError': cloudError,
        'missingMediaCount': missingMediaCount,
      };
  factory BackupRecord.fromJson(Map<String, dynamic> json) => BackupRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      size: (json['size'] as num).toInt(),
      sha256: json['sha256'] as String,
      localPath: json['localPath'] as String?,
      driveId: json['driveId'] as String?,
      cloudError: json['cloudError'] as String?,
      missingMediaCount: (json['missingMediaCount'] as num?)?.toInt() ?? 0);
}
