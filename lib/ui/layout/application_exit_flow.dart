import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/business_day/application/business_day_exit_service.dart';
import 'package:lotus_erp/features/business_day/data/business_day_repository.dart';
import 'package:lotus_erp/features/notifications/data/business_day_alert_repository.dart';

abstract final class ApplicationExitFlow {
  static Future<void> run(BuildContext context) async {
    final db = AppDatabase();
    try {
      await BusinessDayExitService(BusinessDayRepository(db)).requestExit(
        now: DateTime.now(),
        openClosing: (day) async {
          if (!context.mounted) return;
          await context.push(BusinessDayAlertRepository.dayBookLocation(
            day,
            'close',
            exitAfterClose: true,
          ));
        },
        exitApplication: () async {
          if (!context.mounted) return;
          await db.close();
          if (Platform.isAndroid || Platform.isIOS) {
            await SystemNavigator.pop();
          } else {
            exit(0);
          }
        },
      );
    } catch (error) {
      if (context.mounted) {
        AppFeedback.warning(context,
            message:
                'Day closing could not be completed. ${error.toString().replaceFirst('Bad state: ', '')}');
      }
    }
  }
}
