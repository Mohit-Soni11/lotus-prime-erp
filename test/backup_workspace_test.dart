import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/features/settings/backup_restore/application/backup_coordinator.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_restore_service.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_store.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/google_drive_auth.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/google_drive_backup_service.dart';
import 'package:lotus_erp/features/settings/backup_restore/domain/backup_schedule.dart';
import 'package:lotus_erp/features/settings/backup_restore/domain/backup_record.dart';
import 'package:lotus_erp/features/settings/backup_restore/domain/google_drive_client.dart';
import 'package:lotus_erp/features/settings/backup_restore/presentation/backup_history_panel.dart';
import 'package:lotus_erp/features/settings/backup_restore/presentation/backup_restore_screen.dart';
import 'package:lotus_erp/features/settings/backup_restore/presentation/backup_workspace_app_bar.dart';
import 'package:lotus_erp/features/settings/backup_restore/presentation/backup_workspace_theme.dart';
import 'package:lotus_erp/ui/settings/settings_dashboard/settings_screen.dart';
import 'dart:io';
import 'backup_restore_test_support.dart';
import 'google_drive_backup_test_support.dart';

class _LoopbackHttpOverrides extends HttpOverrides {}

Future<(BackupFixture, BackupCoordinator)> _controller({
  GoogleDriveClient applicationClient = const GoogleDriveClient(clientId: ''),
  Future<bool> Function(Uri)? openBrowser,
  FakeBackupHttp? transport,
}) async {
  final fixture =
      BackupFixture(await Directory.systemTemp.createTemp('lotus-backup-ui-'));
  await fixture.seed();
  final http = transport ??
      FakeBackupHttp((a, b, c, d) async => backupJsonResponse({'files': []}));
  final controller = BackupCoordinator(
      locations: fixture.locations,
      store: BackupStore(fixture.locations),
      preferences: fixture.preferences,
      drive: GoogleDriveBackupService(
          auth: GoogleDriveAuth(
              http: http,
              secrets: MemoryBackupSecrets(),
              applicationClient: applicationClient,
              openBrowser: openBrowser),
          http: http),
      restore: BackupRestoreService(fixture.locations, fixture.preferences,
          clearSession: () async {}),
      requireOwner: () async {});
  await controller.initialize();
  return (fixture, controller);
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

void main() {
  testWidgets('recovery keeps every destination in one labelled list',
      (tester) async {
    final records = [
      BackupRecord(
          id: 'local',
          name: 'local.lotusbackup',
          createdAt: DateTime.utc(2026, 11, 22, 8),
          size: 1024,
          sha256: 'a' * 64,
          localPath: 'C:/Backups/local.lotusbackup'),
      BackupRecord(
          id: 'drive',
          name: 'drive.lotusbackup',
          createdAt: DateTime.utc(2026, 11, 22, 9),
          size: 1024,
          sha256: 'b' * 64,
          driveId: 'drive-backup'),
      BackupRecord(
          id: 'both',
          name: 'both.lotusbackup',
          createdAt: DateTime.utc(2026, 11, 22, 10),
          size: 1024,
          sha256: 'c' * 64,
          localPath: 'C:/Backups/both.lotusbackup',
          driveId: 'both-backup'),
    ];
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: BackupHistoryPanel(
                    records: records,
                    enabled: true,
                    connected: true,
                    onRefreshCloud: () {},
                    onRestore: (_) {},
                    onRetryUpload: (_) {},
                    onPickLocal: () {})))));
    await tester.pump();
    expect(find.text('Local'), findsOneWidget);
    expect(find.text('Google Drive'), findsOneWidget);
    expect(find.text('Local + Google Drive'), findsOneWidget);
    expect(find.byType(SegmentedButton<bool>), findsNothing);
    expect(find.text('Restore Backup File'), findsOneWidget);
  });

  testWidgets('recovery restores only the backup selected by the user',
      (tester) async {
    final local = BackupRecord(
        id: 'local',
        name: 'local.lotusbackup',
        createdAt: DateTime.utc(2026, 11, 22, 8),
        size: 1024,
        sha256: 'a' * 64,
        localPath: 'C:/Backups/local.lotusbackup');
    final drive = BackupRecord(
        id: 'drive',
        name: 'drive.lotusbackup',
        createdAt: DateTime.utc(2026, 11, 22, 9),
        size: 1024,
        sha256: 'b' * 64,
        driveId: 'drive-backup');
    BackupRecord? restored;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: BackupHistoryPanel(
                records: [local, drive],
                enabled: true,
                connected: true,
                onRefreshCloud: () {},
                onRestore: (record) => restored = record,
                onRetryUpload: (_) {},
                onPickLocal: () {}))));

    final restoreSelected =
        find.widgetWithText(FilledButton, 'Restore Selected');
    expect(tester.widget<FilledButton>(restoreSelected).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('backup-row-drive')));
    await tester.pump();
    await tester.tap(restoreSelected);

    expect(restored?.id, 'drive');
  });

  for (final width in [500.0, 1600.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('backup workspace at $width px and $scale text scale',
          (tester) async {
        late (BackupFixture, BackupCoordinator) data;
        await tester.runAsync(() async {
          data = await _controller();
        });
        await tester.binding.setSurfaceSize(Size(width, 1000));
        addTearDown(() async {
          data.$2.dispose();
          await tester
              .runAsync(() => data.$1.directory.delete(recursive: true));
          await tester.binding.setSurfaceSize(null);
        });
        await tester.pumpWidget(MaterialApp(
            home: MediaQuery(
                data: MediaQueryData(
                    size: Size(width, 1000),
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true),
                child:
                    BackupRestoreScreen(controller: data.$2, onBack: () {}))));
        await _pump(tester);
        for (final title in [
          'Local Backup',
          'Google Drive Backup',
          'Backup Schedule',
          'Backups & Recovery'
        ]) {
          await tester.ensureVisible(find.text(title));
          await _pump(tester);
          expect(tester.takeException(), isNull, reason: title);
        }
        expect(find.text('BACKUP & RESTORE'), findsOneWidget);
        expect(find.text('Restore Backup File'), findsOneWidget);
        expect(find.text('Back Up Now'), findsOneWidget);
        expect(find.text('Business Data Backup'), findsOneWidget);
        expect(find.text('Backup Type'), findsOneWidget);
        expect(find.text('Next Backup'), findsNothing);
        final theme = Theme.of(tester.element(find.text('Local Backup')));
        expect(theme.brightness, Brightness.light);
        expect(theme.scaffoldBackgroundColor, BackupWorkspaceTheme.canvas);
      });
    }
  }

  testWidgets(
      'schedule saves and Google connection has no developer setup flow',
      (tester) async {
    late (BackupFixture, BackupCoordinator) data;
    await tester.runAsync(() async {
      data = await _controller();
    });
    await tester.binding.setSurfaceSize(const Size(1280, 1000));
    addTearDown(() async {
      data.$2.dispose();
      await tester.runAsync(() => data.$1.directory.delete(recursive: true));
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(MaterialApp(
        home: BackupRestoreScreen(controller: data.$2, onBack: () {})));
    await _pump(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('backup-frequency')));
    await tester.tap(find.byKey(const ValueKey('backup-frequency')));
    await _pump(tester);
    await tester.tap(find.text('Weekly').last);
    await _pump(tester);
    await tester.ensureVisible(find.text('Save Schedule'));
    await tester.runAsync(() async {
      await tester.tap(find.text('Save Schedule'));
    });
    await _pump(tester);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pump(const Duration(seconds: 3));
    await _pump(tester);
    expect(data.$2.settings!.schedule.frequency, BackupFrequency.weekly);
    expect(find.text('Set Up Google Drive'), findsNothing);
    expect(find.text('Connection Setup'), findsNothing);
    expect(find.text('Import Desktop Client JSON'), findsNothing);
    await tester.ensureVisible(find.text('Connect Google Account'));
    await tester.tap(find.text('Connect Google Account'));
    await _pump(tester);
    expect(data.$2.drive.auth.connected, isFalse);
    expect(data.$2.error, contains('not available in this build'));
    expect(find.byType(AlertDialog), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Connect opens Google directly and shows the connected account',
      (tester) async {
    late (BackupFixture, BackupCoordinator) data;
    var browserOpened = false;
    await tester.runAsync(() async {
      data = await _controller(
          applicationClient: const GoogleDriveClient(
              clientId: 'test.apps.googleusercontent.com'),
          transport: FakeBackupHttp((uri, method, headers, body) async {
            if (uri.path == '/token') {
              return backupJsonResponse({
                'access_token': 'test-access',
                'refresh_token': 'test-refresh',
                'expires_in': 3600,
                'scope': '${GoogleDriveAuth.driveScope} openid email'
              });
            }
            return backupJsonResponse(uri.path == '/v1/userinfo'
                ? {'email': 'owner@example.test', 'sub': 'test-owner'}
                : {'files': []});
          }),
          openBrowser: (uri) async {
            browserOpened = true;
            expect(uri.host, 'accounts.google.com');
            final callback = Uri.parse(uri.queryParameters['redirect_uri']!)
                .replace(queryParameters: {
              'state': uri.queryParameters['state']!,
              'code': 'test-code'
            });
            expect(callback.host, '127.0.0.1');
            final client = _LoopbackHttpOverrides().createHttpClient(null);
            try {
              await (await (await client.getUrl(callback)).close())
                  .drain<void>();
            } finally {
              client.close(force: true);
            }
            return true;
          });
    });
    await tester.binding.setSurfaceSize(const Size(1280, 1000));
    addTearDown(() async {
      data.$2.dispose();
      await tester.runAsync(() => data.$1.directory.delete(recursive: true));
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(MaterialApp(
        home: BackupRestoreScreen(controller: data.$2, onBack: () {})));
    await _pump(tester);
    await tester.ensureVisible(find.text('Connect Google Account'));
    await tester.runAsync(() async {
      await tester.tap(find.text('Connect Google Account'));
      await Future.doWhile(() async {
        if (!data.$2.busy) return false;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return true;
      }).timeout(const Duration(seconds: 5));
    });
    await _pump(tester);
    expect(browserOpened, isTrue);
    expect(data.$2.drive.auth.connected, isTrue, reason: data.$2.error);
    expect(data.$2.settings!.googleDriveEnabled, isFalse);
    expect(find.text('owner@example.test'), findsOneWidget);
    expect(find.text('Change Account'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.byTooltip('Google Drive Backup not selected'));
      await Future.doWhile(() async {
        if (!data.$2.busy) return false;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return true;
      }).timeout(const Duration(seconds: 5));
    });
    await _pump(tester);
    expect(data.$2.settings!.googleDriveEnabled, isTrue);
    await tester.runAsync(() async {
      await tester.tap(find.byTooltip('Local Backup selected'));
      await Future.doWhile(() async {
        if (!data.$2.busy) return false;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return true;
      }).timeout(const Duration(seconds: 5));
    });
    await _pump(tester);
    expect(data.$2.settings!.localEnabled, isFalse);
    expect(data.$2.settings!.googleDriveEnabled, isTrue);
    expect(
        (await tester.runAsync(data.$2.store.settings))!.localEnabled, isFalse);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings backup card opens a root workspace and Back returns',
      (tester) async {
    late (BackupFixture, BackupCoordinator) data;
    await tester.runAsync(() async {
      data = await _controller();
    });
    await tester.binding.setSurfaceSize(const Size(1280, 1000));
    final root = GlobalKey<NavigatorState>();
    final router =
        GoRouter(navigatorKey: root, initialLocation: '/settings', routes: [
      ShellRoute(
          builder: (_, __, child) => Row(children: [
                const SizedBox(width: 180, child: Text('Sidebar navigation')),
                Expanded(child: child)
              ]),
          routes: [
            GoRoute(
                path: '/settings',
                builder: (context, _) => SettingsScreen(
                    onNavigate: (id) => context.push(RouteMapper.toPath(id)))),
          ]),
      GoRoute(
          path: RoutePaths.settingsBackupRestore,
          parentNavigatorKey: root,
          builder: (context, _) => BackupRestoreScreen(
              controller: data.$2, onBack: () => context.pop())),
    ]);
    addTearDown(() async {
      router.dispose();
      data.$2.dispose();
      await tester.runAsync(() => data.$1.directory.delete(recursive: true));
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await _pump(tester);
    await tester.ensureVisible(find.text('Backup & Restore'));
    await tester.tap(find.text('Backup & Restore'));
    await _pump(tester);
    expect(find.byType(BackupWorkspaceAppBar), findsOneWidget);
    expect(find.text('Sidebar navigation').hitTestable(), findsNothing);
    expect(tester.getSize(find.byType(BackupWorkspaceAppBar)).width, 1280);
    await tester.tap(find.byTooltip('Back'));
    await _pump(tester);
    expect(find.text('Backup & Restore'), findsOneWidget);
    expect(find.text('Sidebar navigation'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
