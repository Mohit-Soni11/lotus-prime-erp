import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_config.dart';
import 'core/logging/app_logger.dart';
import 'core/router/app_router.dart';
import 'database/db/app_database.dart';
import 'features/finance/ledger/data/finance_day_closure_repository.dart';
import 'theme/dashboard/app/uv.dart';
import 'features/settings/backup_restore/application/backup_runtime.dart';
import 'features/settings/backup_restore/application/backup_application_lease.dart';

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    AppLogger.error(
      'Unhandled Flutter framework error.',
      error: details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    AppLogger.error(
      'Unhandled platform error.',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };

  await runZonedGuarded(() async {
    try {
      await _bootstrapApplication(
          waitForPrevious: arguments.contains('--lotus-restore-restart'));
      runApp(
        ProviderScope(
          child: LotusERPApp(routerConfig: createAppRouter()),
        ),
      );
      BackupRuntime.instance.startScheduler();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Application bootstrap failed.',
        error: error,
        stackTrace: stackTrace,
      );
      runApp(
        BootstrapFailureApp(
          errorMessage: _formatStartupError(error),
        ),
      );
    }
  }, (error, stackTrace) {
    AppLogger.error(
      'Uncaught zone error.',
      error: error,
      stackTrace: stackTrace,
    );
  });
}

Future<void> _bootstrapApplication({bool waitForPrevious = false}) async {
  if (kReleaseMode) {
    SharedPreferences.setPrefix('lotus_erp.production.');
  }
  await BackupRuntime.instance.bootstrap(waitForPrevious: waitForPrevious);
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  initAuthRouting();

  await FinanceDayClosureRepository(AppDatabase()).migrateLegacyLocks();
}

String _formatStartupError(Object error) {
  if (error is BackupStartupException) return error.message;
  return 'Startup failed. Please review local configuration and restart the app.';
}

class LotusERPApp extends StatelessWidget {
  final RouterConfig<Object> routerConfig;

  const LotusERPApp({
    super.key,
    required this.routerConfig,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: UV.colors.bgPrimary,
        useMaterial3: true,
        fontFamily: GoogleFonts.inter().fontFamily,
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark(useMaterial3: true).textTheme,
        ).apply(
          bodyColor: const Color(0xFFF9FAFB),
          displayColor: const Color(0xFFF9FAFB),
        ),
      ),
      builder: _readableTextScaleBuilder,
      routerConfig: routerConfig,
    );
  }
}

Widget _readableTextScaleBuilder(BuildContext context, Widget? child) {
  final media = MediaQuery.of(context);
  final currentScale = media.textScaler.scale(1.0);
  final targetScale = currentScale < 1.08 ? 1.08 : currentScale;
  return MediaQuery(
    data: media.copyWith(
      textScaler: TextScaler.linear(targetScale.clamp(1.08, 1.18).toDouble()),
    ),
    child: child ?? const SizedBox.shrink(),
  );
}

class BootstrapFailureApp extends StatelessWidget {
  final String errorMessage;

  const BootstrapFailureApp({
    super.key,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD4A927)),
      ),
      home: BootstrapFailureScreen(errorMessage: errorMessage),
    );
  }
}

class BootstrapFailureScreen extends StatelessWidget {
  final String errorMessage;

  const BootstrapFailureScreen({
    super.key,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F5),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD9DDE3)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12101827),
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConfig.appName,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: const Color(0xFF101827),
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Application startup needs attention.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF101827),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      errorMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF172435),
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      errorMessage.contains('already open')
                          ? 'Switch to the Lotus ERP window that is already running.'
                          : 'Check local database access and application settings before relaunching.',
                      style: const TextStyle(
                        color: Color(0xFF596575),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
