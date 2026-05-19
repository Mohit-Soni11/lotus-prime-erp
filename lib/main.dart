import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'config/app_config.dart';
import 'config/env_config.dart';
import 'core/logging/app_logger.dart';
import 'database/db/app_database.dart';
import 'database/seeds/database_seeder.dart';
import 'firebase_options.dart';
import 'theme/dashboard/app/uv.dart';
import 'ui/auth/login_screen.dart';
import 'ui/layout/main_layout_wrapper.dart';

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
      runApp(const LotusERPApp());
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
  const LotusERPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: UV.colors.bgPrimary,
        useMaterial3: true,
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (snapshot.hasError) {
          return const BootstrapFailureScreen(
            errorMessage: 'Authentication service is temporarily unavailable.',
          );
        }

        if (snapshot.hasData) {
          return const MainLayoutWrapper();
        }

        return const LoginScreen();
      },
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
