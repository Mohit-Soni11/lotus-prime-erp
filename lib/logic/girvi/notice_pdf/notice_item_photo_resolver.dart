import 'dart:io';

import '../../../database/db/app_database.dart';
import '../../../repositories/girvi/girvi_details_repository.dart';
import '../../../repositories/setting/billing_setup/girvi_billing_repo.dart';

/// Uses the same per-metal photo visibility setting as the Girvi invoice.
class NoticeItemPhotoResolver {
  NoticeItemPhotoResolver(AppDatabase database)
      : _details = GirviDetailsRepository(database),
        _billing = GirviBillingRepo(db: database);

  final GirviDetailsRepository _details;
  final GirviBillingRepo _billing;

  Future<String?> resolve(int loanId) async {
    try {
      final settings = await _billing.fetch();
      final details = await _details.getLoanDetails(
        loanId,
      );
      if (details == null) return null;
      for (final item in details.items) {
        if (!settings.settingsForMetal(item.item.metalType).showItemPhotos) {
          continue;
        }
        for (final photo in item.photos) {
          final source = photo.filePath.trim();
          if (source.isEmpty) continue;
          final uri = Uri.tryParse(source);
          final path = uri?.scheme == 'file'
              ? uri!.toFilePath(windows: Platform.isWindows)
              : source;
          if (await File(path).exists()) return path;
        }
      }
    } catch (_) {
      // A missing image must never prevent notice generation.
    }
    return null;
  }
}
