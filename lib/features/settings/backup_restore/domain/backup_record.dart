import 'backup_schedule.dart';

class BackupSettings {
  const BackupSettings(
      {required this.localFolder,
      this.localEnabled = true,
      this.googleDriveEnabled = false,
      this.schedule = const BackupSchedule()});
  final String localFolder;
  final bool localEnabled;
  final bool googleDriveEnabled;
  final BackupSchedule schedule;
  BackupSettings copyWith({
    String? localFolder,
    bool? localEnabled,
    bool? googleDriveEnabled,
    BackupSchedule? schedule,
  }) =>
      BackupSettings(
        localFolder: localFolder ?? this.localFolder,
        localEnabled: localEnabled ?? this.localEnabled,
        googleDriveEnabled: googleDriveEnabled ?? this.googleDriveEnabled,
        schedule: schedule ?? this.schedule,
      );
  Map<String, dynamic> toJson() => {
        'localFolder': localFolder,
        'localEnabled': localEnabled,
        'googleDriveEnabled': googleDriveEnabled,
        'schedule': schedule.toJson()
      };
  factory BackupSettings.fromJson(
          Map<String, dynamic> json, String defaultFolder) =>
      BackupSettings(
        localFolder: json['localFolder'] as String? ?? defaultFolder,
        localEnabled: json['localEnabled'] != false,
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
      this.localRequested = true,
      this.missingMediaCount = 0});
  final String id;
  final String name;
  final DateTime createdAt;
  final int size;
  final String sha256;
  final String? localPath;
  final String? driveId;
  final String? cloudError;
  final bool localRequested;
  final int missingMediaCount;

  BackupRecord withLocalPreference(bool requested) => BackupRecord(
      id: id,
      name: name,
      createdAt: createdAt,
      size: size,
      sha256: sha256,
      localPath: localPath,
      driveId: driveId,
      cloudError: cloudError,
      localRequested: requested,
      missingMediaCount: missingMediaCount);

  BackupRecord uploaded(String fileId) => BackupRecord(
      id: id,
      name: name,
      createdAt: createdAt,
      size: size,
      sha256: sha256,
      localPath: localPath,
      driveId: fileId,
      localRequested: localRequested,
      missingMediaCount: missingMediaCount);
  BackupRecord withoutLocalCopy() => BackupRecord(
      id: id,
      name: name,
      createdAt: createdAt,
      size: size,
      sha256: sha256,
      driveId: driveId,
      localRequested: localRequested,
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
      localRequested: localRequested,
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
        'localRequested': localRequested,
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
      localRequested: json['localRequested'] != false,
      missingMediaCount: (json['missingMediaCount'] as num?)?.toInt() ?? 0);
}
