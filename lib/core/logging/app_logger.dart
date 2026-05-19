import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../config/env_config.dart';

class AppLogger {
  AppLogger._();

  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    if (!EnvConfig.enableVerboseLogs) {
      return;
    }
    _log('DEBUG', message, error: error, stackTrace: stackTrace);
  }

  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    _log('INFO', message, error: error, stackTrace: stackTrace);
  }

  static void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log('WARN', message, error: error, stackTrace: stackTrace);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log('ERROR', message, error: error, stackTrace: stackTrace);
  }

  static void _log(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      '[$level] $message',
      name: 'LotusERP',
      error: error,
      stackTrace: stackTrace,
    );

    if (kDebugMode && error != null && stackTrace == null) {
      developer.log(
        '[$level] $error',
        name: 'LotusERP',
      );
    }
  }
}
