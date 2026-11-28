import 'dart:async';
import 'dart:io';
import '../../../../../ui/auth/services/auth_result.dart';
import '../../../../../ui/auth/services/auth_service.dart';
import '../../../../../ui/auth/services/auth_session_controller.dart';
import '../../../../../ui/auth/services/local_session_store.dart';
import '../data/backup_http_transport.dart';
import '../data/backup_locations.dart';
import '../data/backup_restore_service.dart';
import '../data/backup_store.dart';
import '../data/google_drive_auth.dart';
import '../data/google_drive_backup_service.dart';
import 'backup_application_lease.dart';
import 'backup_coordinator.dart';
import 'google_recovery_linker.dart';

class BackupRuntime {
  BackupRuntime._();
  static final instance = BackupRuntime._();
  final _lease = BackupApplicationLease();
  BackupLocations? _locations;
  Future<BackupCoordinator>? _coordinator;
  Timer? _timer;
  bool _ticking = false;

  Future<void> bootstrap({bool waitForPrevious = false}) async {
    _locations = await BackupLocations.discover();
    await _lease.acquire(_locations!, waitForPrevious: waitForPrevious);
    final restore = BackupRestoreService(
        _locations!, SharedBusinessPreferences(),
        clearSession: const SecureLocalSessionStore().clear);
    final recovering = await restore.journal.exists();
    var applied = false;
    try {
      applied = await restore.applyPending();
    } catch (_) {
      throw const BackupStartupException(
          'Restore could not finish. Close Lotus ERP and reopen it to retry recovery. Your recovery files have been kept.');
    }
    if (recovering && !applied) {
      throw const BackupStartupException(
          'An interrupted restore was rolled back and your previous records were recovered. Close and reopen Lotus ERP to continue.');
    }
  }

  Future<BackupCoordinator> coordinator() =>
      _coordinator ??= _createCoordinator();
  Future<BackupCoordinator> _createCoordinator() async {
    final paths = _locations ?? await BackupLocations.discover();
    final preferences = SharedBusinessPreferences();
    final transport = IoBackupHttpTransport();
    final coordinator = BackupCoordinator(
        locations: paths,
        store: BackupStore(paths),
        preferences: preferences,
        drive: GoogleDriveBackupService(
            auth: GoogleDriveAuth(http: transport), http: transport),
        restore: BackupRestoreService(paths, preferences,
            clearSession: const SecureLocalSessionStore().clear),
        requireOwner: () async {
          if ((await AuthService().validateCurrentSession()).status !=
              SessionCheckStatus.authorized) {
            throw StateError(
                'Sign in with the shop owner account to manage backups.');
          }
        },
        recoveryLinker: LocalGoogleRecoveryLinker(AuthService()));
    try {
      await coordinator.initialize();
      return coordinator;
    } catch (_) {
      _coordinator = null;
      coordinator.dispose();
      rethrow;
    }
  }

  void startScheduler() {
    if (_timer != null) return;
    AuthSessionController.instance.addListener(_tick);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
    _tick();
  }

  Future<void> _tick() async {
    if (_ticking ||
        AuthSessionController.instance.status != AuthSessionStatus.authorized) {
      return;
    }
    _ticking = true;
    try {
      await (await coordinator()).scheduledTick(DateTime.now());
    } catch (_) {
      /* Backup failures are reported in the backup workspace. */
    } finally {
      _ticking = false;
    }
  }

  Future<void> restartForRestore() async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      throw StateError('Automatic reopen is supported on the desktop app.');
    }
    final child = await Process.start(
        Platform.resolvedExecutable, ['--lotus-restore-restart'],
        workingDirectory: File(Platform.resolvedExecutable).parent.path,
        mode: ProcessStartMode.detached);
    if (child.pid <= 0) {
      throw StateError(
          'Restart could not be started. Close and reopen Lotus ERP.');
    }
    exit(0);
  }
}
