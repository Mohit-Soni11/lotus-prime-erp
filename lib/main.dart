import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'config/app_config.dart';
import 'config/env_config.dart';
import 'core/logging/app_logger.dart';
import 'core/router/app_router.dart';
import 'database/db/app_database.dart';
import 'database/seeds/database_seeder.dart';
import 'firebase_options.dart';
import 'theme/dashboard/app/uv.dart';

Future<void> main() async {
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
      await _bootstrapApplication();
      runApp(LotusERPApp(routerConfig: createAppRouter()));
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

Future<void> _bootstrapApplication() async {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  initAuthRouting();

  final database = AppDatabase();
  if (EnvConfig.enableDemoSeed) {
    await DatabaseSeeder(database).seed();
  } else {
    AppLogger.info('Demo seeding disabled for this environment.');
  }
}

String _formatStartupError(Object error) {
  if (error is FirebaseException) {
    return 'Firebase startup failed. Check project configuration and internet connectivity.';
  }
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
      ),
      routerConfig: routerConfig,
    );
  }
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
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(useMaterial3: true),
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
      backgroundColor: const Color(0xFF0E1116),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF161C24),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2B3442)),
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
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Application startup needs attention.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      errorMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFFCAD2DC),
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Check Firebase setup, local permissions, and environment flags before relaunching.',
                      style: TextStyle(
                        color: Color(0xFF8FA0B3),
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
