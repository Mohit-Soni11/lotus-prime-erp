import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../../core/storage/app_storage_paths.dart';
import '../../../../../config/db_config.dart';
import '../../../../../database/local_database/shop_database_schema.dart';

class BackupResource {
  const BackupResource(this.id, this.path, {this.schemaVersion});
  final String id;
  final String path;
  final int? schemaVersion;
  bool get isDatabase => schemaVersion != null;
}

class BackupLocations {
  const BackupLocations({required this.resources, required this.root});
  final List<BackupResource> resources;
  final Directory root;
  Directory get local => Directory(p.join(root.path, 'Local'));
  Directory get work => Directory(p.join(root.path, 'Work'));
  Directory get recovery => Directory(p.join(root.path, 'Recovery'));

  static Future<BackupLocations> discover() async {
    final documents = await AppStoragePaths.documentsDirectory();
    final support = await AppStoragePaths.supportDirectory();
    final shop = await AppStoragePaths.shopDatabaseDirectory();
    final localAppData =
        Platform.isWindows ? Platform.environment['LOCALAPPDATA'] : null;
    final base = localAppData ?? (await getApplicationSupportDirectory()).path;
    return BackupLocations(
      root: Directory(p.join(base, AppStoragePaths.productionFolder,
          kReleaseMode ? 'Backups' : 'DevelopmentBackups')),
      resources: [
        BackupResource('business', p.join(documents.path, DbConfig.dbName),
            schemaVersion: DbConfig.schemaVersion),
        BackupResource('shop', p.join(shop.path, 'erp_master_db.db'),
            schemaVersion: ShopDatabaseSchema.currentVersion),
        BackupResource(
            'captured_media', p.join(documents.path, 'Lotus ERP', 'media')),
        BackupResource('supplier_bills',
            p.join(documents.path, 'lotus_erp', 'supplier_bills')),
        BackupResource('girvi_item_photos',
            p.join(documents.path, 'lotus_erp', 'girvi_item_photos')),
        BackupResource('girvi_kyc_photos',
            p.join(documents.path, 'lotus_erp', 'girvi_kyc_photos')),
        BackupResource('issued_invoices',
            p.join(support.path, 'lotus_erp', 'issued_invoices')),
        BackupResource('girvi_documents',
            p.join(support.path, 'lotus_erp', 'girvi_documents')),
        BackupResource(
            'customer_media', p.join(support.path, 'customer_media')),
        BackupResource('profile', p.join(support.path, 'profile')),
        BackupResource(
            'external_media', p.join(support.path, 'recovered_media')),
        BackupResource('shop_identity', p.join(support.path, 'shop_identity')),
        BackupResource(
            'shop_documents', p.join(support.path, 'shop_documents')),
      ],
    );
  }

  void validateDestination(String folder) {
    if (!p.isAbsolute(folder)) {
      throw StateError('Choose an absolute backup folder.');
    }
    final target = p.normalize(p.absolute(folder));
    for (final resource
        in resources.where((resource) => !resource.isDatabase)) {
      if (p.equals(resource.path, target) ||
          p.isWithin(resource.path, target)) {
        throw StateError('Choose a backup folder outside your business files.');
      }
    }
  }
}
